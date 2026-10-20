# -*- coding: utf-8 -*-
"""内容管线：维护课程/词汇/界面文案 → 注入 F0 参考数据 → 产出数据包 pack_v1.json。

以后新增场景/词汇只改本文件，运行后数据包自动更新，App 代码零改动。
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACK_PATH = os.path.join(ROOT, "assets", "content", "pack_v1.json")
F0_PATH = os.path.join(ROOT, "tools", "f0_data.json")

with open(F0_PATH, encoding="utf-8") as f:
    F0 = json.load(f)


def f0_of(stem):
    """注入某条音频的 F0 参考曲线；没有则 None。"""
    d = F0.get(stem)
    return {"sr": d["sr"], "hop": d["hop"], "f0": d["f0"]} if d else None


# ─────────────────────────── 界面文案（中英阿） ───────────────────────────
UI = {
    "ar": {
        "tab_learn": "تعلّم", "tab_review": "مراجعة", "tab_talk": "تحدّث", "tab_me": "حسابي",
        "continue": "تابع", "back": "رجوع", "skip": "تخطَّ الآن", "retry": "حاول مرة أخرى",
        "greeting": "صباح الخير يا جيمس", "greeting_sub": "هل أنت مستعد لعشر دقائق اليوم؟",
        "streak": "12 يوماً متتالياً",
        "continue_chip": "تابع · الدرس الأول",
        "progress_meta": "60% · الخطوة 3 من 5",
        "choose_path": "اختر مسارك", "see_all": "عرض الكل",
        "path_survival_title": "صينية البقاء", "path_survival_sub": "تحدث من اليوم الأول",
        "path_survival_meta": "6 مواقف · 80 كلمة · مجاني",
        "path_basics_title": "أساسيات العمل", "path_basics_sub": "أسبوعك الأول في الصين",
        "path_basics_meta": "6 مواقف · 220 كلمة",
        "path_pro_title": "العمل الاحترافي", "path_pro_sub": "تفاوض وأتمم الصفقات",
        "path_pro_meta": "5 مواقف · احترافي",
        "lesson_title": "الدرس 1 · في المطار", "step_of": "الخطوة {n} من {total}",
        "speaker_staff": "موظف تسجيل الوصول", "speaker_you": "أنت",
        "tip_tap_word": "تلميح: اضغط على أي كلمة لترى معناها",
        "got_it": "فهمت — تابع",
        "say_this": "قُل هذا", "tap_and_speak": "اضغط وتحدث",
        "compare_title": "نطقك مقابل النطق القياسي",
        "legend_standard": "المعيار", "legend_yours": "نطقك",
        "pitch_high": "عالٍ", "pitch_low": "منخفض", "time_axis": "الزمن",
        "review_title": "المراجعة اليومية", "review_sub": "الثلاثاء · 24 كلمة مستحقة",
        "done_today": "أُنجزت اليوم", "start_review": "ابدأ المراجعة",
        "stat_streak": "يوماً متتالياً", "stat_accuracy": "الدقة", "stat_words": "كلمات متعلمة",
        "due_now": "مستحقة الآن",
        "below_threshold": "الكلمات الأقل من 85% تعود في مراجعة الغد",
    },
    "en": {
        "tab_learn": "Learn", "tab_review": "Review", "tab_talk": "Talk", "tab_me": "Me",
        "continue": "Continue", "back": "Back", "skip": "Skip for now", "retry": "Try again",
        "greeting": "Good morning, James", "greeting_sub": "Ready for today's 10 minutes?",
        "streak": "12 day streak",
        "continue_chip": "CONTINUE · LESSON 1",
        "progress_meta": "60% · Step 3 of 5",
        "choose_path": "Choose your path", "see_all": "See all",
        "path_survival_title": "Survival Chinese", "path_survival_sub": "Speak from day one",
        "path_survival_meta": "6 scenarios · 80 words · Free",
        "path_basics_title": "Business Basics", "path_basics_sub": "Your first week in China",
        "path_basics_meta": "6 scenarios · 220 words",
        "path_pro_title": "Business Pro", "path_pro_sub": "Negotiate & close deals",
        "path_pro_meta": "5 scenarios · PRO",
        "lesson_title": "Lesson 1 · At the Airport", "step_of": "Step {n} of {total}",
        "speaker_staff": "Check-in staff", "speaker_you": "You",
        "tip_tap_word": "Tip: tap any word to see its meaning",
        "got_it": "Got it — continue",
        "say_this": "SAY THIS", "tap_and_speak": "Tap and speak",
        "compare_title": "Your pronunciation vs standard",
        "legend_standard": "Standard", "legend_yours": "Yours",
        "pitch_high": "High", "pitch_low": "Low", "time_axis": "Time",
        "review_title": "Daily review", "review_sub": "Tuesday · 24 words due",
        "done_today": "Done today", "start_review": "Start review",
        "stat_streak": "Day streak", "stat_accuracy": "Accuracy", "stat_words": "Words learned",
        "due_now": "Due now",
        "below_threshold": "Words below 85% come back in tomorrow's review",
    },
}

# ─────────────────────────── 学习路径 ───────────────────────────
PATHS = [
    {"id": "survival", "icon": "plane", "free": True, "lessons": ["lesson_01"],
     "title": {"ar": UI["ar"]["path_survival_title"], "en": UI["en"]["path_survival_title"]},
     "sub": {"ar": UI["ar"]["path_survival_sub"], "en": UI["en"]["path_survival_sub"]},
     "meta": {"ar": UI["ar"]["path_survival_meta"], "en": UI["en"]["path_survival_meta"]}},
    {"id": "basics", "icon": "briefcase", "free": False, "lessons": [],
     "title": {"ar": UI["ar"]["path_basics_title"], "en": UI["en"]["path_basics_title"]},
     "sub": {"ar": UI["ar"]["path_basics_sub"], "en": UI["en"]["path_basics_sub"]},
     "meta": {"ar": UI["ar"]["path_basics_meta"], "en": UI["en"]["path_basics_meta"]}},
    {"id": "pro", "icon": "chart", "free": False, "lessons": [],
     "title": {"ar": UI["ar"]["path_pro_title"], "en": UI["en"]["path_pro_title"]},
     "sub": {"ar": UI["ar"]["path_pro_sub"], "en": UI["en"]["path_pro_sub"]},
     "meta": {"ar": UI["ar"]["path_pro_meta"], "en": UI["en"]["path_pro_meta"]}},
]

# ─────────────────────────── 词汇（场景1） ───────────────────────────
WORDS = [
    {"id": "w_nihao", "hanzi": "你好", "pinyin": "nǐhǎo", "audio": "w_nihao.mp3",
     "ar": "مرحباً", "en": "hello"},
    {"id": "w_huanying", "hanzi": "欢迎", "pinyin": "huānyíng", "audio": "w_huanying.mp3",
     "ar": "أهلاً وسهلاً", "en": "welcome"},
    {"id": "w_zhongguo", "hanzi": "中国", "pinyin": "Zhōngguó", "audio": "w_zhongguo.mp3",
     "ar": "الصين", "en": "China"},
    {"id": "w_chuchai", "hanzi": "出差", "pinyin": "chūchāi", "audio": "w_chuchai.mp3",
     "ar": "رحلة عمل", "en": "business trip"},
    {"id": "w_huzhao", "hanzi": "护照", "pinyin": "hùzhào", "audio": "w_huzhao.mp3",
     "ar": "جواز السفر", "en": "passport"},
    {"id": "w_chushi", "hanzi": "出示", "pinyin": "chūshì", "audio": "w_chushi.mp3",
     "ar": "إبراز", "en": "to show (a document)"},
    {"id": "w_qingwen", "hanzi": "请问", "pinyin": "qǐngwèn", "audio": "w_qingwen.mp3",
     "ar": "عفواً / لو سمحت", "en": "excuse me (polite opener)"},
    {"id": "w_dengjikou", "hanzi": "登机口", "pinyin": "dēngjīkǒu", "audio": "w_dengjikou.mp3",
     "ar": "بوابة الصعود", "en": "boarding gate"},
    {"id": "w_ruzhu", "hanzi": "入住", "pinyin": "rùzhù", "audio": "w_ruzhu.mp3",
     "ar": "تسجيل الوصول (فندق)", "en": "hotel check-in"},
    {"id": "w_canguan", "hanzi": "参观", "pinyin": "cānguān", "audio": "w_canguan.mp3",
     "ar": "زيارة", "en": "to visit (a place)"},
    {"id": "w_gongchang", "hanzi": "工厂", "pinyin": "gōngchǎng", "audio": "w_gongchang.mp3",
     "ar": "مصنع", "en": "factory"},
    {"id": "w_xishoujian", "hanzi": "洗手间", "pinyin": "xǐshǒujiān", "audio": "w_xishoujian.mp3",
     "ar": "دورة المياه", "en": "restroom"},
    {"id": "w_shaodeng", "hanzi": "稍等", "pinyin": "shāoděng", "audio": "w_shaodeng.mp3",
     "ar": "لحظة", "en": "wait a moment"},
    {"id": "w_duoshaoqian", "hanzi": "多少钱", "pinyin": "duōshao qián", "audio": "w_duoshaoqian.mp3",
     "ar": "كم الثمن؟", "en": "how much?"},
]

# ─────────────────────────── 场景1 课程（五步流） ───────────────────────────
LESSON_01 = {
    "id": "lesson_01",
    "path": "survival",
    "title": {"ar": "في المطار", "en": "At the Airport"},
    "steps": [
        # 第1步：听对话
        {"type": "dialogue", "turns": [
            {"speaker": "staff", "zh": "你好！欢迎来到中国。", "pinyin": "Nǐ hǎo! Huānyíng lái dào Zhōngguó.",
             "ar": "مرحباً! أهلاً بك في الصين.", "en": "Hello! Welcome to China.",
             "audio": "l01_s01_normal.mp3"},
            {"speaker": "you", "zh": "你好，我是来出差的。", "pinyin": "Nǐ hǎo, wǒ shì lái chūchāi de.",
             "ar": "مرحباً، أنا هنا في رحلة عمل.", "en": "Hello, I'm here on a business trip.",
             "audio": "l01_s02_normal.mp3"},
            {"speaker": "staff", "zh": "请出示您的护照。", "pinyin": "Qǐng chūshì nín de hùzhào.",
             "ar": "يُرجى إبراز جواز السفر.", "en": "Please show your passport.",
             "audio": "l01_s03_normal.mp3"},
            {"speaker": "you", "zh": "谢谢。请问登机口在哪里？", "pinyin": "Xièxie. Qǐngwèn dēngjīkǒu zài nǎlǐ?",
             "ar": "شكراً. أين بوابة الصعود؟", "en": "Thanks. Where is the boarding gate?",
             "audio": "l01_s04_normal.mp3"},
            {"speaker": "staff", "zh": "请稍等。", "pinyin": "Qǐng shāo děng.",
             "ar": "لحظة، من فضلك.", "en": "One moment, please.",
             "audio": "l01_s08_normal.mp3"},
            {"speaker": "you", "zh": "太好了，谢谢您！", "pinyin": "Tài hǎo le, xièxie nín!",
             "ar": "هذا رائع، شكراً!", "en": "Wonderful, thank you!",
             "audio": "l01_s10_normal.mp3"},
        ]},
        # 第2步：学词汇
        {"type": "vocabulary",
         "word_ids": ["w_nihao", "w_huanying", "w_zhongguo", "w_chuchai", "w_huzhao",
                      "w_chushi", "w_qingwen", "w_dengjikou", "w_ruzhu", "w_canguan",
                      "w_gongchang", "w_xishoujian", "w_shaodeng", "w_duoshaoqian"]},
        # 第3步：句型
        {"type": "patterns", "items": [
            {"zh": "我是来___的。", "pinyin": "Wǒ shì lái ___ de.", "note": {"ar": "للتعريف عن سبب الزيارة", "en": "state your purpose"},
             "example": {"zh": "我是来出差的。", "pinyin": "Wǒ shì lái chūchāi de.",
                         "ar": "أنا هنا في رحلة عمل.", "en": "I'm here on a business trip."}},
            {"zh": "请问___在哪里？", "pinyin": "Qǐngwèn ___ zài nǎlǐ?", "note": {"ar": "السؤال عن المكان بأدب", "en": "ask for a location politely"},
             "example": {"zh": "请问登机口在哪里？", "pinyin": "Qǐngwèn dēngjīkǒu zài nǎlǐ?",
                         "ar": "أين بوابة الصعود؟", "en": "Where is the boarding gate?"}},
            {"zh": "我想___。", "pinyin": "Wǒ xiǎng ___.", "note": {"ar": "التعبير عن الرغبة", "en": "express a wish"},
             "example": {"zh": "我想参观工厂。", "pinyin": "Wǒ xiǎng cānguān gōngchǎng.",
                         "ar": "أرغب في زيارة المصنع.", "en": "I'd like to visit the factory."}},
            {"zh": "请出示您的___。", "pinyin": "Qǐng chūshì nín de ___.", "note": {"ar": "طلب إبراز وثيقة", "en": "ask to see a document"},
             "example": {"zh": "请出示您的护照。", "pinyin": "Qǐng chūshì nín de hùzhào.",
                         "ar": "يُرجى إبراز جواز السفر.", "en": "Please show your passport."}},
            {"zh": "这个多少钱？", "pinyin": "Zhège duōshao qián?", "note": {"ar": "السؤال عن السعر", "en": "ask the price"},
             "example": {"zh": "这个多少钱？", "pinyin": "Zhège duōshao qián?",
                         "ar": "كم ثمن هذا؟", "en": "How much is this?"}},
        ]},
        # 第4步：跟读对比（F0 参考曲线已注入）
        {"type": "shadow", "sentences": [
            {"id": "sh_01", "zh": "你好，我是来出差的。", "pinyin": "Nǐ hǎo, wǒ shì lái chūchāi de.",
             "ar": "مرحباً، أنا هنا في رحلة عمل.", "en": "Hello, I'm here on a business trip.",
             "audio_normal": "l01_s02_normal.mp3", "audio_slow": "l01_s02_slow.mp3",
             "f0": f0_of("l01_s02_normal")},
            {"id": "sh_02", "zh": "我想参观工厂。", "pinyin": "Wǒ xiǎng cānguān gōngchǎng.",
             "ar": "أرغب في زيارة المصنع.", "en": "I'd like to visit the factory.",
             "audio_normal": "l01_s06_normal.mp3", "audio_slow": "l01_s06_slow.mp3",
             "f0": f0_of("l01_s06_normal")},
            {"id": "sh_03", "zh": "请问登机口在哪里？", "pinyin": "Qǐngwèn dēngjīkǒu zài nǎlǐ?",
             "ar": "أين بوابة الصعود؟", "en": "Where is the boarding gate?",
             "audio_normal": "l01_s04_normal.mp3", "audio_slow": "l01_s04_slow.mp3",
             "f0": f0_of("l01_s04_normal")},
        ]},
        # 第5步：练习
        {"type": "quiz", "items": [
            {"qtype": "listen_choose", "audio": "l01_s06_normal.mp3",
             "prompt": {"ar": "ماذا قال المتحدث؟", "en": "What did the speaker say?"},
             "options": [{"zh": "我想参观工厂。", "ar": "أرغب في زيارة المصنع.", "en": "I'd like to visit the factory.", "correct": True},
                         {"zh": "我要办入住。", "ar": "أرغب في تسجيل الوصول.", "en": "I'd like to check in.", "correct": False},
                         {"zh": "这个多少钱？", "ar": "كم ثمن هذا؟", "en": "How much is this?", "correct": False}]},
            {"qtype": "word_match", "prompt": {"ar": "اختر المعنى الصحيح", "en": "Pick the right meaning"},
             "word": "w_chuchai",
             "options": [{"ar": "رحلة عمل", "en": "business trip", "correct": True},
                         {"ar": "جواز السفر", "en": "passport", "correct": False},
                         {"ar": "مصنع", "en": "factory", "correct": False}]},
            {"qtype": "order_words", "prompt": {"ar": "رتّب الكلمات جملة", "en": "Put the words in order"},
             "tokens": ["我", "想", "参观", "工厂"], "answer": "我想参观工厂。"},
            {"qtype": "tone_pick", "prompt": {"ar": "أي نبرة لكلمة 想 (xiǎng)؟", "en": "Which tone is 想 (xiǎng)?"},
             "options": [{"ar": "النبرة الثالثة (降然后升)", "en": "3rd tone (fall then rise)", "correct": True},
                         {"ar": "النبرة الأولى (مسطحة)", "en": "1st tone (flat)", "correct": False},
                         {"ar": "النبرة الرابعة (هبوط)", "en": "4th tone (falling)", "correct": False}]},
            {"qtype": "shadow_score", "sentence_id": "sh_02",
             "prompt": {"ar": "اقرأ الجملة وقارن نبرتك", "en": "Read the sentence and compare your tones"}},
        ]},
    ],
}

# ─────────────────────────── 复习规则 ───────────────────────────
REVIEW = {
    "match_threshold": 85,      # 逐字贴合度 >=85% 视为掌握
    "new_tomorrow": 70,         # <70% 次日必须复习
    "streak_goal_min": 10,      # 每日目标分钟
}


def main():
    pack = {
        "pack": {
            "id": "chinese_travel_content",
            "version": "1.0.0",
            "min_app_version": "0.1.0",
            "updated": "2026-10-20",
            "content_langs": ["ar", "en"],
        },
        "ui_strings": UI,
        "paths": PATHS,
        "lessons": [LESSON_01],
        "words": WORDS,
        "review": REVIEW,
    }
    os.makedirs(os.path.dirname(PACK_PATH), exist_ok=True)
    with open(PACK_PATH, "w", encoding="utf-8") as f:
        json.dump(pack, f, ensure_ascii=False, indent=2)
    n_shadow = sum(len(s["sentences"]) for l in pack["lessons"] for s in l["steps"] if s["type"] == "shadow")
    n_f0 = sum(1 for l in pack["lessons"] for s in l["steps"] if s["type"] == "shadow"
               for x in s["sentences"] if x.get("f0"))
    print(f"数据包已生成: {PACK_PATH}")
    print(f"  路径 {len(PATHS)} | 课程 {len(pack['lessons'])} | 词汇 {len(WORDS)} | 跟读句 {n_shadow}（含 F0 {n_f0}）")
    print(f"  大小: {os.path.getsize(PACK_PATH)//1024} KB")


if __name__ == "__main__":
    main()
