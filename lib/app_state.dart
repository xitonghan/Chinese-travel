// 全局状态：界面语言（ar/en）+ 已加载内容包 + 学习进度（内存版，测试版本暂不持久化）。
import 'package:flutter/material.dart';

import 'data/content_loader.dart';
import 'data/models.dart';

class AppStateScope extends InheritedWidget {
  final AppState state;
  const AppStateScope({super.key, required this.state, required super.child});
  static AppState of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppStateScope>()!
      .state;
}

class AppState extends ChangeNotifier {
  String lang = 'ar'; // 默认阿拉伯语（目标市场）；可切英语
  ContentPack? pack;
  bool loading = true;
  String? loadError;

  // 进度（测试版本：内存态，重启清零）
  final Set<String> completedLessons = {};
  final Set<String> learnedWords = {}; // 跟读达到阈值的词
  int streak = 12; // 设计稿演示值

  Future<void> init() async {
    try {
      pack = await ContentLoader.load();
      loadError = null;
    } catch (e) {
      loadError = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  void setLang(String l) {
    if (l == lang) return;
    lang = l;
    notifyListeners();
  }

  void toggleLang() => setLang(lang == 'ar' ? 'en' : 'ar');

  UiStrings get ui => pack!.ui(lang);

  void completeLesson(String id) {
    completedLessons.add(id);
    notifyListeners();
  }

  bool lessonDone(String id) => completedLessons.contains(id);

  Lesson? currentLesson() {
    if (pack == null) return null;
    final free = pack!.paths.firstWhere((p) => p.free, orElse: () => pack!.paths.first);
    final ls = pack!.lessonsOfPath(free.id);
    return ls.isEmpty ? null : ls.first;
  }
}
