// 屏 4：复习页（设计稿 Review Tab）。
// 测试版本：展示本课词表 + 跟读得分，达到阈值算掌握，低于阈值进"明天复习"。
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import 'lesson_screen.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final ui = state.ui;
    final pack = state.pack;
    if (pack == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(ui.get('review_title'),
            style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(ui.get('review_sub'),
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 16),

        // 统计行
        Row(
          children: [
            _Stat(
                value: '${pack.words.length}',
                label: ui.get('due_now'),
                color: AppColors.cinnabar),
            const SizedBox(width: 10),
            _Stat(
                value: '${state.learnedWords.length}',
                label: ui.get('done_today'),
                color: AppColors.green),
            const SizedBox(width: 10),
            _Stat(
                value: '${state.streak}',
                label: ui.get('stat_streak'),
                color: AppColors.amber),
          ],
        ),
        const SizedBox(height: 16),

        // 规则说明
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cinnabarSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.cinnabar, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(ui.get('below_threshold'),
                    style: const TextStyle(
                        color: AppColors.ink, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 待复习词表
        ...pack.words.map((w) => _WordRow(word: w, lang: state.lang, ui: ui)),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cinnabar,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            // 测试版本：直接进入唯一课程（复习流程后续版本做）
            onPressed: () {
              final lesson = state.currentLesson();
              if (lesson case final l?) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LessonScreen(lesson: l)));
              }
            },
            child: Text(ui.get('start_review'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final WordEntry word;
  final String lang;
  final UiStrings ui;
  const _WordRow({required this.word, required this.lang, required this.ui});

  @override
  Widget build(BuildContext context) {
    final learned = AppStateScope.of(context).learnedWords.contains(word.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(
            learned ? Icons.check_circle : Icons.radio_button_unchecked,
            color: learned ? AppColors.green : AppColors.muted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(word.hanzi,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(word.pinyin,
                style: const TextStyle(color: AppColors.cinnabar, fontSize: 11)),
          ),
          const Spacer(),
          Text(lang == 'ar' ? word.ar : word.en,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
