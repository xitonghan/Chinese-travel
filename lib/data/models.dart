// 内容数据包模型 —— 与 assets/content/pack_v1.json 严格对应。
// 数据与 App 分离：本文件只定义结构，不含任何内容。

class ContentPack {
  final PackMeta meta;
  final Map<String, UiStrings> uiStrings; // "ar" / "en"
  final List<LearningPath> paths;
  final List<Lesson> lessons;
  final List<WordEntry> words;
  final ReviewRules review;

  ContentPack({
    required this.meta,
    required this.uiStrings,
    required this.paths,
    required this.lessons,
    required this.words,
    required this.review,
  });

  factory ContentPack.fromJson(Map<String, dynamic> j) => ContentPack(
        meta: PackMeta.fromJson(j["pack"]),
        uiStrings: (j["ui_strings"] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, UiStrings.fromJson(v)),
        ),
        paths: (j["paths"] as List).map((e) => LearningPath.fromJson(e)).toList(),
        lessons: (j["lessons"] as List).map((e) => Lesson.fromJson(e)).toList(),
        words: (j["words"] as List).map((e) => WordEntry.fromJson(e)).toList(),
        review: ReviewRules.fromJson(j["review"]),
      );

  UiStrings ui(String lang) => uiStrings[lang] ?? uiStrings["en"]!;
  /// 按 id 取词；数据缺失时返回占位词（测试版不崩溃，调用方无需判空）。
  WordEntry word(String id) {
    for (final w in words) {
      if (w.id == id) return w;
    }
    return WordEntry(id: id, hanzi: id, pinyin: '', audio: '', ar: '', en: '');
  }
  List<Lesson> lessonsOfPath(String pathId) =>
      lessons.where((l) => l.path == pathId).toList();
}

class PackMeta {
  final String id, version, minAppVersion, updated;
  final List<String> contentLangs;
  PackMeta({
    required this.id,
    required this.version,
    required this.minAppVersion,
    required this.updated,
    required this.contentLangs,
  });
  factory PackMeta.fromJson(Map<String, dynamic> j) => PackMeta(
        id: j["id"],
        version: j["version"],
        minAppVersion: j["min_app_version"],
        updated: j["updated"],
        contentLangs: List<String>.from(j["content_langs"]),
      );
}

/// 本地化短文本：数据包里每个可见文本都是 {ar, en}。
class L10n {
  final String ar, en;
  L10n(this.ar, this.en);
  factory L10n.fromJson(Map<String, dynamic> j) =>
      L10n(j["ar"] ?? "", j["en"] ?? "");
  String get(String lang) => lang == "ar" ? ar : en;
}

class UiStrings {
  final Map<String, String> _m;
  UiStrings(this._m);
  factory UiStrings.fromJson(Map<String, dynamic> j) =>
      UiStrings(j.map((k, v) => MapEntry(k, v.toString())));
  String get(String key, {Map<String, String> args = const {}}) {
    var s = _m[key] ?? key;
    args.forEach((k, v) => s = s.replaceAll("{$k}", v));
    return s;
  }
}

class LearningPath {
  final String id, icon;
  final bool free;
  final List<String> lessonIds;
  final L10n title, sub, meta;
  LearningPath({
    required this.id,
    required this.icon,
    required this.free,
    required this.lessonIds,
    required this.title,
    required this.sub,
    required this.meta,
  });
  factory LearningPath.fromJson(Map<String, dynamic> j) => LearningPath(
        id: j["id"],
        icon: j["icon"],
        free: j["free"] ?? false,
        lessonIds: List<String>.from(j["lessons"]),
        title: L10n.fromJson(j["title"]),
        sub: L10n.fromJson(j["sub"]),
        meta: L10n.fromJson(j["meta"]),
      );
}

class Lesson {
  final String id, path;
  final L10n title;
  final List<LessonStep> steps;
  Lesson({required this.id, required this.path, required this.title, required this.steps});
  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j["id"],
        path: j["path"],
        title: L10n.fromJson(j["title"]),
        steps: (j["steps"] as List).map((e) => LessonStep.fromJson(e)).toList(),
      );
}

abstract class LessonStep {
  final String type;
  LessonStep(this.type);
  factory LessonStep.fromJson(Map<String, dynamic> j) {
    switch (j["type"]) {
      case "dialogue":
        return DialogueStep.fromJson(j);
      case "vocabulary":
        return VocabStep.fromJson(j);
      case "patterns":
        return PatternStep.fromJson(j);
      case "shadow":
        return ShadowStep.fromJson(j);
      case "quiz":
        return QuizStep.fromJson(j);
      default:
        throw ArgumentError("unknown step type: ${j["type"]}");
    }
  }
}

class DialogueStep extends LessonStep {
  final List<DialogueTurn> turns;
  DialogueStep(this.turns) : super("dialogue");
  factory DialogueStep.fromJson(Map<String, dynamic> j) => DialogueStep(
        (j["turns"] as List).map((e) => DialogueTurn.fromJson(e)).toList(),
      );
}

class DialogueTurn {
  final String speaker; // "staff" / "you"
  final String zh, pinyin, audio;
  final L10n ar, en;
  DialogueTurn({
    required this.speaker,
    required this.zh,
    required this.pinyin,
    required this.audio,
    required this.ar,
    required this.en,
  });
  factory DialogueTurn.fromJson(Map<String, dynamic> j) => DialogueTurn(
        speaker: j["speaker"],
        zh: j["zh"],
        pinyin: j["pinyin"],
        audio: j["audio"],
        ar: L10n.fromJson(j["ar"]),
        en: L10n.fromJson(j["en"]),
      );
  L10n get meaning => ar;
}

class VocabStep extends LessonStep {
  final List<String> wordIds;
  VocabStep(this.wordIds) : super("vocabulary");
  factory VocabStep.fromJson(Map<String, dynamic> j) =>
      VocabStep(List<String>.from(j["word_ids"]));
}

class PatternStep extends LessonStep {
  final List<PatternItem> items;
  PatternStep(this.items) : super("patterns");
  factory PatternStep.fromJson(Map<String, dynamic> j) => PatternStep(
        (j["items"] as List).map((e) => PatternItem.fromJson(e)).toList(),
      );
}

class PatternItem {
  final String zh, pinyin;
  final L10n note, exampleZh, examplePinyin, exampleAr, exampleEn;
  PatternItem({
    required this.zh,
    required this.pinyin,
    required this.note,
    required this.exampleZh,
    required this.examplePinyin,
    required this.exampleAr,
    required this.exampleEn,
  });
  factory PatternItem.fromJson(Map<String, dynamic> j) {
    final ex = j["example"] as Map<String, dynamic>;
    return PatternItem(
      zh: j["zh"],
      pinyin: j["pinyin"],
      note: L10n.fromJson(j["note"]),
      exampleZh: L10n(ex["zh"], ex["zh"]),
      examplePinyin: L10n(ex["pinyin"], ex["pinyin"]),
      exampleAr: L10n.fromJson(ex["ar"]),
      exampleEn: L10n.fromJson(ex["en"]),
    );
  }
}

class ShadowStep extends LessonStep {
  final List<ShadowSentence> sentences;
  ShadowStep(this.sentences) : super("shadow");
  factory ShadowStep.fromJson(Map<String, dynamic> j) => ShadowStep(
        (j["sentences"] as List).map((e) => ShadowSentence.fromJson(e)).toList(),
      );
}

class ShadowSentence {
  final String id, zh, pinyin, audioNormal, audioSlow;
  final L10n ar, en;
  final F0Curve? f0; // 标准音参考音高曲线
  ShadowSentence({
    required this.id,
    required this.zh,
    required this.pinyin,
    required this.audioNormal,
    required this.audioSlow,
    required this.ar,
    required this.en,
    this.f0,
  });
  factory ShadowSentence.fromJson(Map<String, dynamic> j) => ShadowSentence(
        id: j["id"],
        zh: j["zh"],
        pinyin: j["pinyin"],
        audioNormal: j["audio_normal"],
        audioSlow: j["audio_slow"],
        ar: L10n.fromJson(j["ar"]),
        en: L10n.fromJson(j["en"]),
        f0: j["f0"] == null ? null : F0Curve.fromJson(j["f0"]),
      );
}

class F0Curve {
  final int sr, hop;
  final List<double> f0; // Hz，0 = 静音
  F0Curve({required this.sr, required this.hop, required this.f0});
  factory F0Curve.fromJson(Map<String, dynamic> j) => F0Curve(
        sr: j["sr"],
        hop: j["hop"],
        f0: (j["f0"] as List).map((e) => (e as num).toDouble()).toList(),
      );
}

class QuizStep extends LessonStep {
  final List<QuizItem> items;
  QuizStep(this.items) : super("quiz");
  factory QuizStep.fromJson(Map<String, dynamic> j) => QuizStep(
        (j["items"] as List).map((e) => QuizItem.fromJson(e)).toList(),
      );
}

class QuizItem {
  final String qtype;
  final Map<String, dynamic> raw;
  QuizItem(this.qtype, this.raw);
  factory QuizItem.fromJson(Map<String, dynamic> j) => QuizItem(j["qtype"], j);
}

class WordEntry {
  final String id, hanzi, pinyin, audio;
  final String ar, en;
  WordEntry({
    required this.id,
    required this.hanzi,
    required this.pinyin,
    required this.audio,
    required this.ar,
    required this.en,
  });
  factory WordEntry.fromJson(Map<String, dynamic> j) => WordEntry(
        id: j["id"],
        hanzi: j["hanzi"],
        pinyin: j["pinyin"],
        audio: j["audio"],
        ar: j["ar"],
        en: j["en"],
      );
}

class ReviewRules {
  final int matchThreshold, newTomorrow, streakGoalMin;
  ReviewRules({
    required this.matchThreshold,
    required this.newTomorrow,
    required this.streakGoalMin,
  });
  factory ReviewRules.fromJson(Map<String, dynamic> j) => ReviewRules(
        matchThreshold: j["match_threshold"] ?? 85,
        newTomorrow: j["new_tomorrow"] ?? 70,
        streakGoalMin: j["streak_goal_min"] ?? 10,
      );
}
