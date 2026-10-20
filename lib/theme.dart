// 设计令牌：与设计稿一致（暖米白底 + 朱砂红主色 + 金色用户曲线）。
import 'package:flutter/material.dart';

class AppColors {
  static const cream = Color(0xFFF6F2EB); // 页面底色
  static const card = Color(0xFFFFFFFF);
  static const cinnabar = Color(0xFFC03A2A); // 主色 / 标准音曲线
  static const cinnabarSoft = Color(0xFFF5E3E0);
  static const gold = Color(0xFFD9A441); // 用户录音曲线
  static const ink = Color(0xFF2B2620); // 主文字
  static const muted = Color(0xFF8A8175); // 次级文字
  static const line = Color(0xFFE7E0D5); // 分隔线
  static const green = Color(0xFF3E7C4F); // 正确
  static const amber = Color(0xFFC77F1F); // 偏差提示
}

class AppText {
  static const ar = 'Noto Naskh Arabic';
  static const zh = 'Noto Sans SC';
  static const latin = 'Inter';

  /// 按当前界面语言选择字体栈（中文固定用中文字体）。
  static List<String> stackFor(String lang) =>
      lang == 'ar' ? const [ar, latin] : const [latin, zh];
}
