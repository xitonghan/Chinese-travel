// 底部导航外壳：学习 / 复习 / 对话 / 我的（设计稿 4 Tab）。
// 测试版本中"对话"和"我的"为占位页，正式功能后续版本补齐。
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import 'learn_screen.dart';
import 'review_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _tabs = ['tab_learn', 'tab_review', 'tab_talk', 'tab_me'];
  static const _icons = [
    Icons.school_outlined,
    Icons.replay_outlined,
    Icons.forum_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    // 数据未就绪（加载中 / 加载失败）时显示占位，避免空指针
    if (state.pack == null) {
      return Scaffold(
        body: Center(
          child: state.loading
              ? const CircularProgressIndicator()
              : Text(state.loadError ?? 'Content load failed',
                  textAlign: TextAlign.center),
        ),
      );
    }
    final ui = state.ui;
    final pages = [
      const LearnScreen(),
      const ReviewScreen(),
      _Placeholder(text: ui.get('tab_talk')),
      _Placeholder(text: ui.get('tab_me')),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.cinnabarSoft,
        destinations: List.generate(4, (i) {
          final label = ui.get(_tabs[i]);
          return NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_icons[i], color: AppColors.cinnabar),
            label: label.length > 10 ? label.substring(0, 10) : label,
          );
        }),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String text;
  const _Placeholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_outlined,
              size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(text,
              style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
