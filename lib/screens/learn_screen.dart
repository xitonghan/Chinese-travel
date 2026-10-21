// 屏 1：学习主页（设计稿 Learn Tab）。
// 问候 + 进度 + 继续课程 + 路径选择，全部文案来自内容包。
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import 'lesson_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final pack = state.pack;
    if (pack == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ui = state.ui;
    final lesson = state.currentLesson();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // 顶部：问候 + 语言切换
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ui.get('greeting'),
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(ui.get('greeting_sub'),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'AR / EN',
              onPressed: state.toggleLang,
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(state.lang == 'ar' ? 'EN' : 'ع',
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 进度卡
        _ProgressCard(ui: ui, lesson: lesson, state: state),
        const SizedBox(height: 16),

        // 继续课程按钮
        if (lesson case final l?)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cinnabar,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LessonScreen(lesson: l))),
              child: Text(ui.get('continue_chip'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        const SizedBox(height: 24),

        // 路径选择
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(ui.get('choose_path'),
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            Text(ui.get('see_all'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        ...pack.paths.map((p) => _PathCard(path: p, ui: ui, lang: state.lang)),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final UiStrings ui;
  final Lesson? lesson;
  final AppState state;
  const _ProgressCard(
      {required this.ui, required this.lesson, required this.state});

  @override
  Widget build(BuildContext context) {
    // 进度 = 已完成步骤 / 总步骤（测试版本按课程完成度粗算）
    final total = lesson?.steps.length ?? 1;
    final done = state.lessonDone(lesson?.id ?? '') ? total : 2;
    final pct = (done / total).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_outlined,
                  color: AppColors.cinnabar, size: 18),
              const SizedBox(width: 4),
              Text(ui.get('streak'),
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(ui.get('progress_meta'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          // RTL 下进度条从右向左填充
          Directionality(
            textDirection: TextDirection.rtl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: AppColors.cinnabarSoft,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.cinnabar),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final LearningPath path;
  final UiStrings ui;
  final String lang;
  const _PathCard({required this.path, required this.ui, required this.lang});

  IconData get _icon => switch (path.icon) {
        'plane' => Icons.flight_outlined,
        'briefcase' => Icons.business_center_outlined,
        'chart' => Icons.trending_up_outlined,
        _ => Icons.school_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: path.free ? AppColors.cinnabarSoft : AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon,
                color: path.free ? AppColors.cinnabar : AppColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(path.title.get(lang),
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(path.sub.get(lang),
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(path.meta.get(lang),
                    style: const TextStyle(
                        color: AppColors.cinnabar,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: AppColors.muted),
        ],
      ),
    );
  }
}
