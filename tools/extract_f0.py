# -*- coding: utf-8 -*-
"""YIN 基频(F0)提取：为每个标准音生成参考音高曲线，供 App 内对比显示。

算法：FFT 加速的自相关差分函数 + 累积均值归一化(CMND) + 局部最小 + 抛物线插值。
输出 tools/f0_data.json: {stem: {"sr":.., "hop":.., "f0":[Hz,...]}}，静音帧为 0。
"""
import json
import os

import miniaudio
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO_DIRS = [
    os.path.join(ROOT, "assets", "audio", "sentences"),
    os.path.join(ROOT, "assets", "audio", "words"),
]
OUT = os.path.join(ROOT, "tools", "f0_data.json")

FMIN, FMAX = 60.0, 500.0
FRAME = 2048
HOP = 512
THRESH = 0.25
FFT_N = 4096


def load_mono(path):
    info = miniaudio.decode_file(path)
    x = np.frombuffer(info.samples, dtype=np.int16).astype(np.float64) / 32768.0
    if info.nchannels > 1:
        x = x.reshape(-1, info.nchannels).mean(axis=1)
    return x, info.sample_rate


def yin_frame_f0(seg, sr, tau_min, tau_max):
    """单帧 YIN，返回 F0 (Hz) 或 0。滑音帧用全局最小兜底（中文三声场景必需）。"""
    rms = np.sqrt(np.mean(seg ** 2))
    if rms < 0.01:  # 静音门限
        return 0.0
    # FFT 自相关
    f = np.fft.rfft(seg, n=FFT_N)
    r = np.fft.irfft(f * np.conj(f), n=FFT_N)[: tau_max + 1]
    r0 = r[0]
    if r0 < 1e-8:
        return 0.0
    # 差分函数 d(tau) = 2*(r0 - r(tau))，取 tau >= tau_min
    d = 2.0 * (r0 - r[tau_min : tau_max + 1])
    # CMND 累积均值归一化（用 tau 而非索引，与标准 YIN 一致）
    cmnd = np.zeros_like(d)
    running = 0.0
    for i in range(len(d)):
        running += d[i]
        tau = tau_min + i
        cmnd[i] = d[i] * tau / running if running > 1e-10 else 1.0
    # 1) 第一个低于阈值的局部最小
    best_i = None
    for i in range(1, len(cmnd) - 1):
        if cmnd[i] < THRESH and cmnd[i] <= cmnd[i - 1] and cmnd[i] <= cmnd[i + 1]:
            best_i = i
            break
    # 2) 兜底：全局最小（滑音帧/微扰帧靠这个保住连续性）
    if best_i is None:
        best_i = int(np.argmin(cmnd[1:])) + 1
        if cmnd[best_i] > 0.6:  # 全局最小都不过 0.6，视为无周期
            return 0.0
    tau = tau_min + best_i
    # 抛物线插值
    if 0 < best_i < len(cmnd) - 1:
        y0, y1, y2 = cmnd[best_i - 1], cmnd[best_i], cmnd[best_i + 1]
        denom = 2 * (2 * y1 - y0 - y2)
        if abs(denom) > 1e-10:
            shift = (y2 - y0) / denom * 0.5
            if abs(shift) <= 1.0:
                tau = tau_min + best_i + shift
    return sr / tau


def postprocess(f0):
    """F0 后处理：八度校正 + 中值滤波 + 短洞插值。"""
    n = len(f0)
    # 1) 八度校正：有声帧与前一有声帧比较，倍频关系时取低
    prev = 0.0
    for i in range(n):
        v = f0[i]
        if v <= 0:
            continue
        if prev > 0:
            ratio = v / prev
            if ratio > 1.9 and abs(v / 2 - prev) / prev < 0.25:
                f0[i] = v / 2
            elif ratio < 0.53 and abs(v * 2 - prev) / prev < 0.25:
                f0[i] = v * 2
        prev = f0[i] if f0[i] > 0 else prev
    # 2) 中值滤波（窗 5）去野值
    half = 2
    for i in range(n):
        if f0[i] <= 0:
            continue
        lo, hi = max(0, i - half), min(n, i + half + 1)
        win = [v for v in f0[lo:hi] if v > 0]
        if len(win) >= 3:
            med = sorted(win)[len(win) // 2]
            if abs(f0[i] - med) / med > 0.2:  # 偏离中值 20% 以上视为野值
                f0[i] = med
    # 3) 短洞（<=10 帧≈116ms）线性插值，保持曲线连续
    i = 0
    while i < n:
        if f0[i] == 0:
            j = i
            while j < n and f0[j] == 0:
                j += 1
            if 0 < i and j < n and (j - i) <= 10:
                a, b = f0[i - 1], f0[j]
                for k in range(i, j):
                    t = (k - i + 1) / (j - i + 1)
                    f0[k] = round(a + (b - a) * t, 1)
            i = j
        else:
            i += 1
    return f0


def extract(path):
    x, sr = load_mono(path)
    tau_min = max(2, int(sr / FMAX))
    tau_max = min(int(sr / FMIN), FRAME // 2)
    n = 1 + max(0, (len(x) - FRAME) // HOP)
    f0 = []
    for i in range(n):
        f0.append(round(yin_frame_f0(x[i * HOP : i * HOP + FRAME], sr, tau_min, tau_max), 1))
    f0 = postprocess(f0)
    return {"sr": sr, "hop": HOP, "f0": f0}


def main():
    data = {}
    for d in AUDIO_DIRS:
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if not f.endswith(".mp3"):
                continue
            stem = f[:-4]
            res = extract(os.path.join(d, f))
            voiced = [v for v in res["f0"] if v > 0]
            data[stem] = res
            span = f"{min(voiced):.0f}-{max(voiced):.0f}Hz" if voiced else "silent"
            print(f"  {stem:18s} {len(res['f0']):4d} frames  范围 {span}")
    with open(OUT, "w", encoding="utf-8") as fp:
        json.dump(data, fp, ensure_ascii=False)
    print(f"\n已写出 {OUT}（{len(data)} 条）")


if __name__ == "__main__":
    main()
