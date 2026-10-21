// 运行时 F0 提取：与 tools/extract_f0.py（数据侧）同算法的 Dart 实现。
// 时域直接计算（无 FFT 依赖），帧 2048 / hop 512，够实时。
import 'dart:math';
import 'dart:typed_data';

class PitchDetector {
  static const frame = 2048;
  static const hop = 512;
  static const fMin = 60.0;
  static const fMax = 500.0;
  static const thresh = 0.25;

  /// 对 16kHz 单声道 PCM16 提取 F0 序列（与参考数据同 hop 对齐思路）。
  static List<double> extract(Int16List pcm, int sampleRate) {
    final tauMin = max(2, (sampleRate / fMax).floor());
    final tauMax = min((sampleRate / fMin).floor(), frame ~/ 2);
    final n = 1 + max(0, (pcm.length - frame) ~/ hop);
    final out = <double>[];
    for (var i = 0; i < n; i++) {
      out.add(_frameF0(pcm, i * hop, sampleRate, tauMin, tauMax));
    }
    return _postprocess(out);
  }

  static double _frameF0(Int16List pcm, int start, int sr, int tauMin, int tauMax) {
    // 能量门限（int16 满量程 32768 的 1%）
    var energy = 0.0;
    for (var j = 0; j < frame; j++) {
      final v = pcm[start + j] / 32768.0;
      energy += v * v;
    }
    if (sqrt(energy / frame) < 0.01) return 0.0;

    // 差分函数 + CMND（时域直接算）
    final d = List<double>.filled(tauMax - tauMin + 1, 0.0);
    for (var t = 0; t < d.length; t++) {
      final tau = tauMin + t;
      var sum = 0.0;
      for (var j = 0; j + tau < frame; j++) {
        final diff = pcm[start + j] / 32768.0 - pcm[start + j + tau] / 32768.0;
        sum += diff * diff;
      }
      d[t] = sum;
    }
    final cmnd = List<double>.filled(d.length, 1.0);
    var running = 0.0;
    for (var i = 0; i < d.length; i++) {
      running += d[i];
      final tau = tauMin + i;
      cmnd[i] = running > 1e-10 ? d[i] * tau / running : 1.0;
    }

    // 第一个低于阈值的局部最小；否则全局最小兜底（滑音帧）
    var best = -1;
    for (var i = 1; i < cmnd.length - 1; i++) {
      if (cmnd[i] < thresh && cmnd[i] <= cmnd[i - 1] && cmnd[i] <= cmnd[i + 1]) {
        best = i;
        break;
      }
    }
    if (best < 0) {
      var minV = double.infinity;
      for (var i = 1; i < cmnd.length; i++) {
        if (cmnd[i] < minV) {
          minV = cmnd[i];
          best = i;
        }
      }
      if (minV > 0.6) return 0.0;
    }

    // 抛物线插值（tau 保持 double，shift 是小数）
    var tau = (tauMin + best).toDouble();
    if (best > 0 && best < cmnd.length - 1) {
      final y0 = cmnd[best - 1], y1 = cmnd[best], y2 = cmnd[best + 1];
      final denom = 2 * (2 * y1 - y0 - y2);
      if (denom.abs() > 1e-10) {
        final shift = (y2 - y0) / denom * 0.5;
        if (shift.abs() <= 1) tau += shift;
      }
    }
    return sr / tau;
  }

  /// 后处理：八度校正 + 中值滤波 + 短洞插值（与 Python 侧一致）。
  static List<double> _postprocess(List<double> f0) {
    final n = f0.length;
    var prev = 0.0;
    for (var i = 0; i < n; i++) {
      final v = f0[i];
      if (v <= 0) continue;
      if (prev > 0) {
        final ratio = v / prev;
        if (ratio > 1.9 && (v / 2 - prev).abs() / prev < 0.25) {
          f0[i] = v / 2;
        } else if (ratio < 0.53 && (v * 2 - prev).abs() / prev < 0.25) {
          f0[i] = v * 2;
        }
      }
      prev = f0[i] > 0 ? f0[i] : prev;
    }
    const half = 2;
    for (var i = 0; i < n; i++) {
      if (f0[i] <= 0) continue;
      final lo = max(0, i - half), hi = min(n, i + half + 1);
      final win = f0.sublist(lo, hi).where((v) => v > 0).toList()..sort();
      if (win.length >= 3) {
        final med = win[win.length ~/ 2];
        if ((f0[i] - med).abs() / med > 0.2) f0[i] = med;
      }
    }
    var i = 0;
    while (i < n) {
      if (f0[i] == 0) {
        var j = i;
        while (j < n && f0[j] == 0) {
          j++;
        }
        if (i > 0 && j < n && (j - i) <= 10) {
          final a = f0[i - 1], b = f0[j];
          for (var k = i; k < j; k++) {
            f0[k] = a + (b - a) * (k - i + 1) / (j - i + 1);
          }
        }
        i = j;
      } else {
        i++;
      }
    }
    return f0;
  }
}
