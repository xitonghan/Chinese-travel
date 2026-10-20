# -*- coding: utf-8 -*-
"""准备场景1音频：拷贝句子（规范命名）+ edge-tts 生成词汇点读音。"""
import asyncio
import os
import shutil

import edge_tts

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # 项目根
SRC = os.path.join(os.path.expanduser("~"), "Desktop", "标准音试听")
SENT_DIR = os.path.join(ROOT, "assets", "audio", "sentences")
WORD_DIR = os.path.join(ROOT, "assets", "audio", "words")

# 源文件名(桌面) -> 目标名(资产)
SENTENCES = {
    "01_你好！欢迎来到中国。": "l01_s01",
    "02_你好，我是来出差的。": "l01_s02",
    "03_请出示您的护照。": "l01_s03",
    "04_谢谢。请问登机口在哪里？": "l01_s04",
    "05_我要办入住。": "l01_s05",
    "06_我想参观工厂。": "l01_s06",
    "07_请问洗手间在哪里？": "l01_s07",
    "08_请稍等。": "l01_s08",
    "09_这个多少钱？": "l01_s09",
    "10_太好了，谢谢您！": "l01_s10",
}

WORDS = [
    ("你好", "nǐhǎo", "w_nihao"),
    ("欢迎", "huānyíng", "w_huanying"),
    ("中国", "Zhōngguó", "w_zhongguo"),
    ("出差", "chūchāi", "w_chuchai"),
    ("护照", "hùzhào", "w_huzhao"),
    ("出示", "chūshì", "w_chushi"),
    ("请问", "qǐngwèn", "w_qingwen"),
    ("登机口", "dēngjīkǒu", "w_dengjikou"),
    ("入住", "rùzhù", "w_ruzhu"),
    ("参观", "cānguān", "w_canguan"),
    ("工厂", "gōngchǎng", "w_gongchang"),
    ("洗手间", "xǐshǒujiān", "w_xishoujian"),
    ("稍等", "shāoděng", "w_shaodeng"),
    ("多少钱", "duōshao qián", "w_duoshaoqian"),
]

VOICE = "zh-CN-YunyangNeural"


async def gen(text: str, path: str) -> bool:
    c = edge_tts.Communicate(text, VOICE)
    try:
        await c.save(path)
        return os.path.getsize(path) > 3000
    except Exception as e:
        print(f"    [失败] {e}")
        return False


async def main():
    os.makedirs(SENT_DIR, exist_ok=True)
    os.makedirs(WORD_DIR, exist_ok=True)

    print("== 拷贝句子音频 ==")
    n = 0
    for src_name, dst_stem in SENTENCES.items():
        for ver, suffix in (("常速", "normal"), ("慢速", "slow")):
            src = os.path.join(SRC, f"{src_name}_{ver}.mp3")
            dst = os.path.join(SENT_DIR, f"{dst_stem}_{suffix}.mp3")
            if os.path.exists(src):
                shutil.copyfile(src, dst)
                n += 1
            else:
                print(f"  [缺] {src}")
    print(f"  {n}/20 个句子音频就位")

    print("\n== 生成词汇点读音 ==")
    ok = 0
    for zh, py, stem in WORDS:
        path = os.path.join(WORD_DIR, f"{stem}.mp3")
        good = await gen(zh, path)
        print(f"  {stem} {zh} {'OK' if good else 'FAIL'}")
        ok += good
    print(f"\n句子 {n}/20 + 词汇 {ok}/{len(WORDS)}")


if __name__ == "__main__":
    asyncio.run(main())
