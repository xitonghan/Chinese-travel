// 音高对比图：标准音曲线（朱砂实线） vs 用户录音曲线（金色虚线）。
// 这是本 App 的核心差异点——完全本地计算，不依赖任何云服务。
//
// 对齐策略：标准音与用户录音的语速不同，因此各自裁剪静音头尾后
// 按"有声段"归一化到同一时间轴 [0,1] 上比较（影子跟读的标准做法）。
//
// 评分策略（测试版启发式）：每个音节比较
//   1) 中位音高偏差  2) 走向（升/降/平）是否一致
// 后续版本可替换为 DTW 相关度等更精细的打分。
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';

class PitchChart extends StatelessWidget {
  final F0Curve standard;
  final List<double> userF0;
  final int userSr; // 用户录音采样率（16000）
  final String zh; // 用于音节切分的中文句
  final UiStrings ui;

  const PitchChart({
    super.key,
    required this.standard,
    required this.userF0,
    required this.userSr,
    required this.zh,
    required this.ui,
  });

  /// 归一化 + 逐音节评分的结果。
  static _AlignResult align(F0Curve std, List<double> user, int userSr, String zh) {
    // 1) 各自裁剪首尾静音，取有声段
    List<double> trim(List<double> v) {
      var a = 0, b = v.length - 1;
      while (a <= b && v[a] <= 0) a++;
      while (b >= a && v[b] <= 0) b--;
      return a > b ? <double>[] : v.sublist(a, b + 1);
    }

    final s = trim(std.f0);
    final u = trim(user);

    // 2) 重采样到 120 点（线性插值，无声段线性过渡）
    const n = 120;
    List<double> resample(List<double> v) {
      if (v.isEmpty) return List.filled(n, 0.0);
      return List.generate(n, (i) {
        final x = i * (v.length - 1) / (n - 1);
        final i0 = x.floor().clamp(0, v.length - 2).toInt();
        final t = x - i0;
        return v[i0] * (1 - t) + v[i0 + 1] * t;
      });
    }

    final sr = resample(s);
    final ur = resample(u);

    // 3) 音节切分（去掉标点）
    final chars = zh.replaceAll(RegExp(r'[，。！？、,.!?\s]'), '').split('');
    final k = max(1, chars.length);
    final scores = <double>[];
    for (var i = 0; i < k; i++) {
      final lo = i * n ~/ k;
      final hi = ((i + 1) * n ~/ k).clamp(lo + 1, n).toInt();
      final sv = sr.sublist(lo, hi).where((v) => v > 0).toList()..sort();
      final uv = ur.sublist(lo, hi).where((v) => v > 0).toList()..sort();
      if (sv.isEmpty || uv.isEmpty) {
        scores.add(0);
        continue;
      }
      final sm = sv[sv.length ~/ 2], um = uv[uv.length ~/ 2];
      // 中位偏差分：偏差 25% → 50 分（clamp 返回 num，显式转 double）
      final medScore =
          (100 - (um - sm).abs() / sm * 200).clamp(0.0, 100.0).toDouble();
      // 走向分：首尾三分之一中位数比较升降
      double slope(List<double> v) {
        final third = max(1, v.length ~/ 3);
        final a = v.sublist(0, third).reduce(max);
        final b = v.sublist(v.length - third).reduce(max);
        return (b - a) / max(a, 1.0);
      }

      double sgn(double x) => x > 0.06 ? 1 : (x < -0.06 ? -1 : 0);
      final contourScore = sgn(slope(sv)) == sgn(slope(uv)) ? 100.0 : 40.0;
      scores.add(medScore * 0.5 + contourScore * 0.5);
    }
    return _AlignResult(sr, ur, chars, scores);
  }

  @override
  Widget build(BuildContext context) {
    final r = align(standard, userF0, userSr, zh);
    final avg = r.scores.isEmpty
        ? 0.0
        : r.scores.reduce((a, b) => a + b) / r.scores.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 图例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.cinnabar, dashed: false),
            Text(' ${ui.get('legend_standard')}   ',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            _LegendDot(color: AppColors.gold, dashed: true),
            Text(' ${ui.get('legend_yours')}',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const Spacer(),
            Text('${avg.round()}%',
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          // 图表本身保持 LTR：时间轴从左到右是科学惯例，阿拉伯界面亦然
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CustomPaint(
              painter: _F0Painter(std: r.std, user: r.user),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // 轴标签
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(ui.get('pitch_high'),
                style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            Text(ui.get('time_axis'),
                style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            Text(ui.get('pitch_low'),
                style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 10),
        // 音节得分行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(r.chars.length, (i) {
            final v = i < r.scores.length ? r.scores[i] : 0.0;
            final color = v >= 85
                ? AppColors.green
                : v >= 60
                    ? AppColors.amber
                    : AppColors.cinnabar;
            return Column(
              children: [
                Text(r.chars[i],
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${v.round()}%',
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _AlignResult {
  final List<double> std, user;
  final List<String> chars;
  final List<double> scores;
  _AlignResult(this.std, this.user, this.chars, this.scores);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final bool dashed;
  const _LegendDot({required this.color, required this.dashed});

  @override
  Widget build(BuildContext context) {
    if (dashed) {
      // 虚线用小段 Container 拼
      return Row(
        children: List.generate(
            3,
            (_) => Container(
                  width: 5,
                  height: 2.5,
                  margin: const EdgeInsets.only(right: 2),
                  color: color,
                )),
      );
    }
    return Container(width: 12, height: 2.5, color: color);
  }
}

class _F0Painter extends CustomPainter {
  final List<double> std, user;
  _F0Painter({required this.std, required this.user});

  @override
  void paint(Canvas canvas, Size size) {
    const fMin = 60.0, fMax = 400.0;
    double y(double hz) {
      if (hz <= 0) return size.height; // 无声画在底部
      final t = ((hz - fMin) / (fMax - fMin)).clamp(0.0, 1.0).toDouble();
      return size.height - t * (size.height - 8) - 4;
    }

    double x(int i) => i / (std.length - 1) * size.width;

    // 网格
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (final hz in [100.0, 200.0, 300.0, 400.0]) {
      canvas.drawLine(Offset(0, y(hz)), Offset(size.width, y(hz)), grid);
    }

    // 曲线绘制：跳过无声点（断线）
    void drawCurve(List<double> v, Paint p, {bool dashed = false}) {
      var pen = 0.0;
      for (var i = 1; i < v.length; i++) {
        if (v[i] <= 0 || v[i - 1] <= 0) continue;
        final a = Offset(x(i - 1), y(v[i - 1]));
        final b = Offset(x(i), y(v[i]));
        if (dashed) {
          final len = (b - a).distance;
          pen += len;
          final on = (pen % 12) < 7;
          if (on) canvas.drawLine(a, b, p);
        } else {
          canvas.drawLine(a, b, p);
        }
      }
    }

    drawCurve(std, Paint()
      ..color = AppColors.cinnabar
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round);
    drawCurve(user, Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round, dashed: true);
  }

  @override
  bool shouldRepaint(_F0Painter old) =>
      !_sameList(std, old.std) || !_sameList(user, old.user);
}

/// 逐元素比较（不依赖 foundation 的 listEquals，跨 Flutter 版本稳定）。
bool _sameList(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
