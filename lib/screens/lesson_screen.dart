// 课程页（设计稿屏 2 听 + 屏 3 比）：对话 → 词汇 → 句型 → 跟读对比 → 测验。
// 全部内容由数据包驱动；跟读步的"音高对比"是本地计算的核心功能。
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/content_loader.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../services/pitch_detector.dart';
import '../theme.dart';
import '../widgets/pitch_chart.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _audio = AudioService();
  int _step = 0;

  // 跟读步状态：句子 id → 录音分析结果
  final Map<String, _ShadowResult> _shadow = {};

  int get _total => widget.lesson.steps.length;

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final ui = state.ui;
    final step = widget.lesson.steps[_step];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lesson.title.get(state.lang),
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            Text(ui.get('step_of', args: {'n': '${_step + 1}', 'total': '$_total'}),
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 步骤进度点
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_total, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? AppColors.cinnabar : AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(step, state),
            ),
          ),
          _BottomBar(
            ui: ui,
            isLast: _step == _total - 1,
            onNext: _next,
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_step < _total - 1) {
      setState(() => _step++);
    } else {
      final state = AppStateScope.of(context);
      // 完成课程：本课词汇记为已学
      for (final step in widget.lesson.steps) {
        if (step is VocabStep) {
          for (final id in step.wordIds) {
            state.learnedWords.add(id);
          }
        }
      }
      state.completeLesson(widget.lesson.id);
      Navigator.pop(context);
    }
  }

  Widget _buildStep(LessonStep step, AppState state) {
    final ui = state.ui;
    switch (step.type) {
      case 'dialogue':
        return _DialogueView(
            turns: (step as DialogueStep).turns, ui: ui, lang: state.lang);
      case 'vocabulary':
        return _VocabView(
            wordIds: (step as VocabStep).wordIds,
            ui: ui,
            lang: state.lang,
            pack: state.pack!);
      case 'patterns':
        return _PatternView(items: (step as PatternStep).items, lang: state.lang);
      case 'shadow':
        return _ShadowView(
          sentences: (step as ShadowStep).sentences,
          ui: ui,
          results: _shadow,
          audio: _audio,
          onResult: (id, r) => setState(() => _shadow[id] = r),
          threshold: state.pack!.review.matchThreshold,
        );
      case 'quiz':
        return _QuizView(
            items: (step as QuizStep).items,
            ui: ui,
            pack: state.pack!,
            lang: state.lang);
    }
    return const SizedBox.shrink();
  }
}

class _ShadowResult {
  final List<double> userF0;
  _ShadowResult(this.userF0);
}

// ── 底部按钮条 ────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final UiStrings ui;
  final bool isLast;
  final VoidCallback onNext;
  const _BottomBar(
      {required this.ui, required this.isLast, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onNext,
                child: Text(ui.get('skip'),
                    style: const TextStyle(color: AppColors.muted)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cinnabar,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onNext,
                child: Text(isLast ? ui.get('got_it') : ui.get('continue'),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 步骤 1：对话 ──────────────────────────────────────────────
class _DialogueView extends StatelessWidget {
  final List<DialogueTurn> turns;
  final UiStrings ui;
  final String lang;
  const _DialogueView(
      {required this.turns, required this.ui, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: turns.map((t) {
        final mine = t.speaker == 'you';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mine ? AppColors.cinnabarSoft : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(ui.get(mine ? 'speaker_you' : 'speaker_staff'),
                      style: const TextStyle(
                          color: AppColors.cinnabar,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => AudioService()
                        .playIfExists(ContentLoader.sentenceAudio(t.audio)),
                    child: const Icon(Icons.play_circle_outline,
                        color: AppColors.cinnabar, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 中文保持 LTR 渲染
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(t.zh,
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(t.pinyin,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ),
              const SizedBox(height: 4),
              Text(t.ar.get(lang),
                  style: const TextStyle(color: AppColors.ink, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── 步骤 2：词汇 ──────────────────────────────────────────────
class _VocabView extends StatelessWidget {
  final List<String> wordIds;
  final UiStrings ui;
  final String lang;
  final ContentPack pack;
  const _VocabView(
      {required this.wordIds,
      required this.ui,
      required this.lang,
      required this.pack});

  @override
  Widget build(BuildContext context) {
    final words = wordIds.map((id) => pack.word(id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cinnabarSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.cinnabar, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(ui.get('tip_tap_word'),
                    style: const TextStyle(
                        color: AppColors.ink, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...words.map((w) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(w.hanzi,
                              style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(w.pinyin,
                              style: const TextStyle(
                                  color: AppColors.cinnabar, fontSize: 12)),
                        ),
                        const SizedBox(height: 2),
                        Text(lang == 'ar' ? w.ar : w.en,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => AudioService()
                        .playIfExists(ContentLoader.wordAudio(w.audio)),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.cinnabarSoft,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: const Icon(Icons.volume_up_outlined,
                          color: AppColors.cinnabar, size: 18),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ── 步骤 3：句型 ──────────────────────────────────────────────
class _PatternView extends StatelessWidget {
  final List<PatternItem> items;
  final String lang;
  const _PatternView({required this.items, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
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
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(p.zh,
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(p.pinyin,
                          style: const TextStyle(
                              color: AppColors.cinnabar, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(p.note.get(lang),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(p.exampleZh.get(lang),
                            style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text(p.exampleAr.get(lang),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
    );
  }
}

// ── 步骤 4：跟读 + 音高对比（核心功能） ───────────────────────
class _ShadowView extends StatefulWidget {
  final List<ShadowSentence> sentences;
  final UiStrings ui;
  final Map<String, _ShadowResult> results;
  final AudioService audio;
  final void Function(String, _ShadowResult) onResult;
  final int threshold;
  const _ShadowView({
    required this.sentences,
    required this.ui,
    required this.results,
    required this.audio,
    required this.onResult,
    required this.threshold,
  });

  @override
  State<_ShadowView> createState() => _ShadowViewState();
}

class _ShadowViewState extends State<_ShadowView> {
  final Set<String> _recording = {}; // 正在录音的句子 id
  final Set<String> _analyzing = {};

  Future<void> _toggleRecord(ShadowSentence s) async {
    if (_recording.contains(s.id)) {
      setState(() {
        _recording.remove(s.id);
        _analyzing.add(s.id);
      });
      final pcm = await widget.audio.stopRecording();
      if (pcm == null || pcm.isEmpty) {
        setState(() => _analyzing.remove(s.id));
        return;
      }
      // 本地 YIN 提取（毫秒级）
      final f0 = PitchDetector.extract(pcm, 16000);
      widget.onResult(s.id, _ShadowResult(f0));
      setState(() => _analyzing.remove(s.id));
    } else {
      final ok = await widget.audio.hasMicPermission();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.ui.get('tap_and_speak'))),
          );
        }
        return;
      }
      await widget.audio.startRecording();
      setState(() => _recording.add(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.sentences.map((s) {
        final r = widget.results[s.id];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 句子 + 播放
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(s.zh,
                              style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(s.pinyin,
                              style: const TextStyle(
                                  color: AppColors.cinnabar, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: widget.ui.get('say_this'),
                    onPressed: () => widget.audio
                        .playIfExists(ContentLoader.sentenceAudio(s.audioNormal)),
                    icon: const Icon(Icons.play_circle_fill,
                        color: AppColors.cinnabar, size: 34),
                  ),
                  IconButton(
                    onPressed: () => widget.audio
                        .playIfExists(ContentLoader.sentenceAudio(s.audioSlow)),
                    icon: const Icon(Icons.slow_motion_video,
                        color: AppColors.muted, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 录音按钮
              Center(
                child: GestureDetector(
                  onTap: () => _toggleRecord(s),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _recording.contains(s.id)
                          ? AppColors.cinnabar
                          : AppColors.cinnabarSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _recording.contains(s.id)
                          ? Icons.stop
                          : Icons.mic_none_outlined,
                      color: _recording.contains(s.id)
                          ? Colors.white
                          : AppColors.cinnabar,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _analyzing.contains(s.id)
                      ? '…'
                      : _recording.contains(s.id)
                          ? '● ● ●'
                          : widget.ui.get('tap_and_speak'),
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12),
                ),
              ),

              // 对比结果
              if (r case final rr?)
                if (s.f0 case final ff?) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.ui.get('compare_title'),
                            style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        PitchChart(
                          standard: ff,
                          userF0: rr.userF0,
                          userSr: 16000,
                          zh: s.zh,
                          ui: widget.ui,
                        ),
                        // 判定条：达到阈值 → 通过；否则提示复习规则
                        Builder(builder: (context) {
                          final al = PitchChart.align(
                              ff, rr.userF0, 16000, s.zh);
                          final avg = al.scores.isEmpty
                              ? 0.0
                              : al.scores.reduce((a, b) => a + b) /
                                  al.scores.length;
                          final pass = avg >= widget.threshold;
                          return Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: pass
                                  ? AppColors.green.withValues(alpha: 0.10)
                                  : AppColors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                    pass
                                        ? Icons.check_circle
                                        : Icons.lightbulb_outline,
                                    color: pass
                                        ? AppColors.green
                                        : AppColors.amber,
                                    size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                      pass
                                          ? widget.ui.get('got_it')
                                          : widget.ui.get('below_threshold'),
                                      style: TextStyle(
                                          color: pass
                                              ? AppColors.green
                                              : AppColors.amber,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── 步骤 5：测验 ──────────────────────────────────────────────
class _QuizView extends StatefulWidget {
  final List<QuizItem> items;
  final UiStrings ui;
  final ContentPack pack;
  final String lang;
  const _QuizView(
      {required this.items,
      required this.ui,
      required this.pack,
      required this.lang});

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  int _idx = 0;
  int? _picked; // 选中的选项下标
  int _right = 0;
  bool _finished = false;

  void _pick(int i, List<dynamic> options) {
    if (_picked != null) return;
    final correct = options[i]['correct'] == true;
    setState(() {
      _picked = i;
      if (correct) _right++;
      if (_idx == widget.items.length - 1) _finished = true;
    });
    if (_finished) return;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _idx++;
        _picked = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_idx];
    final j = item.raw;
    final options = (j['options'] as List);
    final prompt = (j['prompt'] as Map);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 进度 / 结算
        Row(
          children: [
            Text(_finished
                ? '$_right/${widget.items.length}'
                : '${_idx + 1}/${widget.items.length}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const Spacer(),
            if (_finished)
              Text(widget.ui.get('got_it'),
                  style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            if (!_finished)
              Text('$_right ✓',
                  style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),

        // 题干
        if (item.qtype == 'listen_choose') ...[
          Row(
            children: [
              Expanded(
                child: Text((prompt[widget.lang] ?? prompt['en'] ?? '').toString(),
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              IconButton(
                onPressed: () => AudioService().playIfExists(
                    ContentLoader.sentenceAudio(j['audio'] as String)),
                icon: const Icon(Icons.volume_up,
                    color: AppColors.cinnabar),
              ),
            ],
          ),
        ] else ...[
          Text((prompt[widget.lang] ?? prompt['en'] ?? '').toString(),
              style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (j['word'] != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cinnabarSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(widget.pack.word(j['word']).hanzi,
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),

        // 选项
        ...List.generate(options.length, (i) {
          final o = options[i] as Map;
          final picked = _picked == i;
          final isRight = o['correct'] == true;
          Color border = AppColors.line;
          Color bg = AppColors.card;
          if (_picked != null) {
            if (isRight) {
              border = AppColors.green;
              bg = AppColors.green.withValues(alpha: 0.08);
            } else if (picked) {
              border = AppColors.cinnabar;
              bg = AppColors.cinnabar.withValues(alpha: 0.06);
            }
          }
          return GestureDetector(
            onTap: () => _pick(i, options),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: _picked != null ? 2 : 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (o['zh'] != null)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(o['zh'],
                                style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                        Text((o[widget.lang] ?? o['en'] ?? '').toString(),
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (_picked != null && isRight)
                    const Icon(Icons.check_circle,
                        color: AppColors.green, size: 20),
                  if (_picked != null && picked && !isRight)
                    const Icon(Icons.cancel,
                        color: AppColors.cinnabar, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
