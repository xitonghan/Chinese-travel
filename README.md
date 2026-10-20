# 中文商旅 · Chinese Travel · الصينية للسفر

> 给阿拉伯语使用者的中文商旅学习 App（Flutter）。
> **数据与 App 分离**：App 是框架，课程/词汇/文案/音频全部在数据包里，可独立修改与发布。
> **核心功能**：跟读录音后，本地计算音高曲线（F0），与标准音叠加对比——不依赖任何云服务、无需账号。

---

## 中文

### 这是什么

第一个可测试版本（v0.1）：包含 1 节完整课程「在机场」（对话 → 词汇 → 句型 → 跟读对比 → 测验），
界面默认阿拉伯语（RTL），可一键切换英语。所有中文内容配有拼音和阿拉伯语/英语释义。

### 功能亮点

- **音高对比**：录音后提取你的音高曲线，与标准音曲线叠加显示（红实线=标准，金虚线=你），逐音节打分。
  全部在手机本地计算（YIN 算法），不联网、不上传、免费。
- **阿拉伯语 RTL 界面**：布局、导航、进度条全部从右向左。
- **数据与 App 分离**：界面文案、课程、词汇、音频都是数据包 `assets/content/pack_v1.json`。
  App 不认识任何具体内容；改数据不用改 App 代码。

### 目录结构

```
chinese_travel/
├── lib/                        # App 代码（框架，不含内容）
│   ├── data/                   # 数据模型 + 加载器（含外部数据覆盖机制）
│   ├── services/               # 录音播放 + 本地音高提取（YIN）
│   ├── screens/                # 学习 / 课程 / 复习页
│   ├── widgets/pitch_chart.dart  # 音高对比图（核心组件）
│   └── main.dart
├── assets/
│   ├── content/pack_v1.json    # 数据包（可独立发布）
│   └── audio/                  # 标准音（句子 + 词汇）
├── tools/                      # 数据管线（改内容只动这里）
│   ├── build_pack.py           #   生成数据包
│   ├── extract_f0.py           #   提取标准音 F0 参考曲线
│   └── prep_audio.py           #   准备音频（edge-tts 生成）
├── android/app/src/main/AndroidManifest.xml  # 含录音权限
└── .github/workflows/build-apk.yml           # 推送即自动构建 APK
```

### 构建测试版 APK

**方式一：GitHub 自动构建（推荐，本机不用装 Flutter）**

1. 把本项目推到 GitHub（见下方《发布到 GitHub》）。
2. 打开仓库页面 → 上方 **Actions** → 点最新的 `build-apk` 运行。
3. 等 3–5 分钟变绿，页面底部 **Artifacts** 里下载 `chinese-travel-debug-apk`。
4. 解压得到 `app-debug.apk`，发给测试者安装（需在手机上允许"安装未知来源应用"）。

**方式二：本机构建**

```bash
flutter pub get
flutter create . --platforms=android   # 首次：生成安卓平台代码
flutter build apk --debug              # 产物在 build/app/outputs/flutter-apk/
```

### 修改与发布数据（数据与 App 分离）

1. 编辑 `tools/build_pack.py`（课程、词汇、三语文案都在里面）。
2. 运行 `python tools/build_pack.py` → 自动生成 `assets/content/pack_v1.json`。
3. 提交推送 → Actions 自动出新 APK。**App 代码零改动。**

新增音频：把 mp3 放进 `assets/audio/` 对应目录，运行
`python tools/extract_f0.py` 重新生成 F0 参考曲线，再跑 `build_pack.py`。
（依赖：`pip install miniaudio numpy`；生成语音用 `pip install edge-tts`）

另有一套**外部数据覆盖**机制已内置：把 `pack_override.json` 放到手机
`应用数据目录/content/` 下即可整体替换内容包，为将来的"只发数据、不发 App"热更新做准备。

### 发布到 GitHub（傻瓜步骤）

1. 装 **GitHub Desktop**（github.com/desktop 下载安装）。
2. File → Add local repository → 选择本 `chinese_travel` 文件夹。
3. 上方 Publish repository → 名字填 `chinese-travel` → **取消勾选 Keep this code private** → Publish。
4. 以后改完数据，在 GitHub Desktop 里写 Summary → Commit to main → Push origin，自动触发构建。

---

## English

### What is this

First testable build (v0.1) of a Chinese-learning app for Arabic speakers: one complete
lesson ("At the Airport": dialogue → vocabulary → patterns → shadowing with pitch
comparison → quiz). The UI is Arabic (RTL) by default, switchable to English. Every
Chinese item has pinyin plus Arabic/English translations.

### Highlights

- **Pitch comparison**: after you record, your voice's pitch curve (F0) is extracted
  **on-device** (YIN algorithm) and overlaid on the standard curve (red = standard,
  gold dashed = you), with per-syllable scores. No cloud, no account, no cost.
- **Full Arabic RTL UI**: layout, navigation and progress bars mirror right-to-left.
- **Data/App separation**: all copy, lessons, words and audio live in the data pack
  `assets/content/pack_v1.json`. The app is a framework that knows no content —
  change data without touching app code.

### Build the test APK

**Option A — GitHub Actions (no local Flutter needed)**

1. Push this project to GitHub (see below).
2. Repo page → **Actions** tab → latest `build-apk` run.
3. When green, download the `chinese-travel-debug-apk` artifact from the bottom.
4. Unzip → `app-debug.apk` → send to testers (enable "install unknown apps").

**Option B — local build**

```bash
flutter pub get
flutter create . --platforms=android   # first time only
flutter build apk --debug
```

### Modify & publish data

1. Edit `tools/build_pack.py` (lessons, words, trilingual copy).
2. `python tools/build_pack.py` → regenerates `assets/content/pack_v1.json`.
3. Commit & push → Actions builds a new APK. **Zero app-code changes.**

New audio: drop mp3s into `assets/audio/`, run `python tools/extract_f0.py`,
then `build_pack.py`. (`pip install miniaudio numpy`; voice generation needs
`pip install edge-tts`.)

An **external override** mechanism is built in: dropping `pack_override.json` into
the app's data directory replaces the whole pack — groundwork for data-only
hot updates without shipping a new app.

### Publish to GitHub

1. Install **GitHub Desktop**.
2. File → Add local repository → select this `chinese_travel` folder.
3. Publish repository → name it `chinese-travel` → uncheck "Keep this code private" → Publish.
4. Later: commit with a summary → Push origin; the build triggers automatically.

---

## العربية

### ما هذا

أول نسخة قابلة للتجربة (0.1) من تطبيق تعلّم الصينية للناطقين بالعربية: درس واحد كامل
«في المطار» (حوار ← كلمات ← أنماط ← ترديد مع مقارنة النبرة ← اختبار).
الواجهة افتراضياً بالعربية (من اليمين لليسار)، ويمكن التبديل للإنجليزية.
كل عبارة صينية مع كتابة بنيين وترجمة عربية/إنجليزية.

### أبرز الميزات

- **مقارنة النبرة**: بعد التسجيل، يستخرج التطبيق منحنى نبرة صوتك **على الهاتف نفسه**
  (خوارزمية YIN) ويعرضه فوق المنحنى القياسي (الأحمر = القياسي، الذهبي المتقطع = صوتك)،
  مع تقييم كل مقطع. بدون إنترنت، بدون حساب، وبدون تكلفة.
- **واجهة عربية كاملة**: التخطيط والتنقل وأشرطة التقدم من اليمين لليسار.
- **فصل البيانات عن التطبيق**: كل النصوص والدروس والكلمات والصوتيات في حزمة بيانات
  واحدة `pack_v1.json`. التطبيق إطار فقط — تُعدّل البيانات دون المساس بالكود.

### بناء النسخة التجريبية (APK)

**الطريقة أ — عبر GitHub Actions (بدون تثبيت Flutter)**

1. ارفع المشروع إلى GitHub.
2. صفحة المستودع → تبويب **Actions** → آخر تشغيل لـ `build-apk`.
3. بعد نجاحه (اللون الأخضر)، نزّل الملف `chinese-travel-debug-apk` من الأسفل.
4. فك الضغط → `app-debug.apk` → أرسله للمُجرّب (يحتاج تفعيل «تثبيت تطبيقات غير معروفة»).

**الطريقة ب — بناء محلي**

```bash
flutter pub get
flutter create . --platforms=android   # أول مرة فقط
flutter build apk --debug
```

### تعديل البيانات ونشرها

1. عدّل `tools/build_pack.py` (الدروس والكلمات والنصوص بثلاث لغات).
2. شغّل `python tools/build_pack.py` → يُنتج `pack_v1.json` جديداً.
3. ارفع التغيير → يُبنى APK جديد تلقائياً. **بدون أي تعديل على كود التطبيق.**

لإضافة صوتيات: ضع ملفات mp3 في `assets/audio/`، ثم شغّل
`python tools/extract_f0.py` وأخيراً `build_pack.py`.

---

## 给阿拉伯语审核者的说明 / Note for Arabic reviewers

界面文案、课程译文都在 `tools/build_pack.py` 里，欢迎直接标注修改意见
（阿语用词是否自然、称谓是否正式/友好）。对照审核表见随附文档。

---

*License: MIT. Standard audio generated with Microsoft Edge TTS (zh-CN-YunyangNeural).*
