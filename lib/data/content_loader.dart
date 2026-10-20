// 内容加载器：内置数据包 + 外部数据覆盖（数据可独立发布/热替换）。
//
// 数据发布方式：
//   1) 仓库内 assets/content/pack_v1.json（随 App 打包）
//   2) 设备目录 <appDocuments>/content/pack_override.json（优先级更高，可独立投放）
//   3) 音频同理：内置 assets/audio/... 或 <appDocuments>/content/audio/...
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'models.dart';

class ContentLoader {
  /// App 版本号（与 pubspec.yaml 的 version 保持一致）。
  static const appVersion = '0.1.0';
  static ContentPack? _pack;
  static Directory? _externalDir;

  static Future<ContentPack> load() async {
    if (_pack != null) return _pack!;
    // 外部覆盖数据（数据与 App 分离的关键机制）
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/content');
      if (await dir.exists()) {
        final f = File('${dir.path}/pack_override.json');
        if (await f.exists()) {
          final pack = ContentPack.fromJson(jsonDecode(await f.readAsString()));
          if (_compatible(pack.meta.minAppVersion)) {
            _externalDir = dir;
            _pack = pack;
            return _pack!;
          }
          // 数据包要求的 App 版本更高 → 整份忽略（含其音频），回退内置包
        } else {
          _externalDir = dir; // 无覆盖包时，仍允许外部音频目录
        }
      }
    } catch (_) {
      // 外部数据异常时静默回退到内置包
    }
    final raw = await rootBundle.loadString('assets/content/pack_v1.json');
    _pack = ContentPack.fromJson(jsonDecode(raw));
    return _pack!;
  }

  /// 数据包声明的 min_app_version 是否不高于当前 App 版本。
  static bool _compatible(String minApp) {
    final a = _v(appVersion), b = _v(minApp);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x >= y;
    }
    return true;
  }

  static List<int> _v(String s) =>
      s.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();

  /// 音频资源路径：外部目录优先，否则走内置 assets。
  static String audioPath(String fileName) {
    if (_externalDir != null) {
      final f = File('${_externalDir!.path}/audio/$fileName');
      if (f.existsSync()) return f.path;
    }
    return 'assets/audio/$fileName';
  }

  static String? sentenceAudio(String fileName) {
    if (_externalDir != null) {
      final f = File('${_externalDir!.path}/audio/sentences/$fileName');
      if (f.existsSync()) return f.path;
    }
    return 'assets/audio/sentences/$fileName';
  }

  static String? wordAudio(String fileName) {
    if (_externalDir != null) {
      final f = File('${_externalDir!.path}/audio/words/$fileName');
      if (f.existsSync()) return f.path;
    }
    return 'assets/audio/words/$fileName';
  }
}
