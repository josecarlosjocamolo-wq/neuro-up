import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../test_model.dart';
import '../../results_repository.dart';
import '../../question_service.dart';
import '../../../../services/achievement_service.dart';
import '../../../../widgets/smooth_page_route.dart';
import '../../../../pages/home/home_page.dart';

class AttentionTestPage extends StatefulWidget {
  final MentalTest test;
  const AttentionTestPage({super.key, required this.test});
  @override
  State<AttentionTestPage> createState() => _AttentionTestPageState();
}

class _AttentionTestPageState extends State<AttentionTestPage> {
  bool _modeSelected = false;
  int _selectedMode = 0;
  bool _showTutorial = false;

  final List<Map<String, dynamic>> _modes = [
    {
      'title': 'Matemáticas',
      'desc': 'Cálculos y operaciones',
      'icon': Icons.calculate_rounded,
      'color': const Color(0xFF3B82F6),
      'hasMath': true,
    },
    {
      'title': 'Atención Visual',
      'desc': 'Enfoque y observación',
      'icon': Icons.center_focus_strong_rounded,
      'color': const Color(0xFF10B981),
      'q': QuestionService.getAttentionVisualQuestions(10),
    },
    {
      'title': 'Modo Mixto',
      'desc': 'Combina mate y atención',
      'icon': Icons.shuffle_rounded,
      'color': const Color(0xFF8B5CF6),
      'q': [
        ...QuestionService.getAttentionVisualQuestions(5),
        {'question': '7 + 5 = ?', 'options': ['11', '12', '13', '14'], 'correct': 1},
        {'question': '15 - 8 = ?', 'options': ['6', '7', '8', '9'], 'correct': 1},
        {'question': '3 × 4 = ?', 'options': ['7', '12', '15', '16'], 'correct': 1},
      ]..shuffle(),
    },
  ];

  final List<Map<String, dynamic>> _mathSubs = [
    {'title': 'Sumas', 'desc': 'Adición básica', 'icon': Icons.add_rounded, 'color': const Color(0xFF2563EB), 'op': '+'},
    {'title': 'Restas', 'desc': 'Sustracción', 'icon': Icons.remove_rounded, 'color': const Color(0xFFDC2626), 'op': '-'},
    {'title': 'Multiplicaciones', 'desc': 'Producto', 'icon': Icons.close_rounded, 'color': const Color(0xFF059669), 'op': '×'},
    {'title': 'Divisiones', 'desc': 'División simple', 'icon': Icons.percent_rounded, 'color': const Color(0xFFD97706), 'op': '÷'},
    {'title': 'Mixtas', 'desc': 'Varias operaciones', 'icon': Icons.shuffle_rounded, 'color': const Color(0xFF7C3AED), 'op': 'mix'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_showTutorial) {
      return _MathTutorial(onBack: () => setState(() => _showTutorial = false), test: widget.test);
    }
    if (!_modeSelected) return _buildModeSelection(context);

    if (_modes[_selectedMode]['hasMath'] == true) {
      return _MathSubmodeSelection(
        test: widget.test,
        modes: _modes,
        selectedMode: _selectedMode,
        subs: _mathSubs,
        onBack: () => setState(() => _modeSelected = false),
        onTut: () => setState(() => _showTutorial = true),
      );
    }

    return _AttentionGamePage(
      test: widget.test,
      mode: _modes[_selectedMode],
      onBack: () => setState(() => _modeSelected = false),
    );
  }

  Widget _buildModeSelection(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent   = widget.test.colorValue;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle, border: Border.all(color: cardBdr)),
                  child: Icon(Icons.arrow_back_rounded, size: 20, color: textMain),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Atención', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textMain, letterSpacing: -0.5)),
                Text('Elige tu modo de juego', style: TextStyle(fontSize: 13, color: textSub)),
              ])),
            ]),
          ),

          // Tip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(Icons.self_improvement_rounded, color: accent, size: 24),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ve a tu ritmo', style: TextStyle(fontWeight: FontWeight.w800, color: textMain, fontSize: 14)),
                  Text('Sin límite de tiempo. Concéntrate.',
                      style: TextStyle(fontSize: 12, color: isDark ? textSub : accent.withValues(alpha: 0.8), height: 1.3)),
                ])),
              ]),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          ),
          const SizedBox(height: 20),

          // List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _modes.length,
              itemBuilder: (_, i) {
                final m = _modes[i];
                final mc = m['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedMode = i;
                      _modeSelected = true;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBdr),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: mc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                          child: Icon(m['icon'], color: mc, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textMain)),
                          const SizedBox(height: 4),
                          Text(m['desc'], style: TextStyle(fontSize: 13, color: textSub, height: 1.3)),
                        ])),
                        Icon(Icons.chevron_right_rounded, color: cardBdr, size: 24),
                      ]),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 + i * 50)).slideX(begin: 0.05),
                );
              },
            ),
          ),

          // Tutorial Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GestureDetector(
              onTap: () => setState(() => _showTutorial = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.school_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 8),
                  Text('TUTORIAL DE OPERACIONES', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Tutorial ───────────────────────────────────────────────────────────────
class _MathTutorial extends StatefulWidget {
  final VoidCallback onBack;
  final MentalTest test;
  const _MathTutorial({required this.onBack, required this.test});
  @override
  State<_MathTutorial> createState() => __MathTutorialState();
}

class __MathTutorialState extends State<_MathTutorial> {
  int _step = 0;
  final _steps = [
    {'title': '¡Bienvenido!', 'content': 'Aprenderemos a resolver operaciones paso a paso.', 'ex': '', 'icon': Icons.school_rounded, 'color': const Color(0xFF3B82F6)},
    {'title': 'Orden (PEMDAS)', 'content': '• Paréntesis\n• Exponentes\n• Multiplicación/División (izq a der)\n• Suma/Resta (izq a der)', 'ex': '8 × 1 + 2\n1. 8 × 1 = 8\n2. 8 + 2 = 10', 'icon': Icons.list_alt_rounded, 'color': const Color(0xFF10B981)},
    {'title': 'Multiplicación', 'content': 'Se hace antes que la suma o resta.', 'ex': '7 + 3 × 2\n1. 3 × 2 = 6\n2. 7 + 6 = 13', 'icon': Icons.close_rounded, 'color': const Color(0xFFEF4444)},
    {'title': 'División', 'content': 'También va antes que la suma o resta.', 'ex': '9 + 6 ÷ 2\n1. 6 ÷ 2 = 3\n2. 9 + 3 = 12', 'icon': Icons.percent_rounded, 'color': const Color(0xFFF59E0B)},
    {'title': 'Mixtos', 'content': 'Sigue el orden PEMDAS estrictamente.', 'ex': '20 - 12 ÷ 3\n1. 12 ÷ 3 = 4\n2. 20 - 4 = 16', 'icon': Icons.shuffle_rounded, 'color': const Color(0xFF8B5CF6)},
    {'title': '¡Listo!', 'content': 'Recuerda: ve sin prisa y verifica.', 'ex': '', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFF10B981)},
  ];

  @override
  Widget build(BuildContext context) {
    final s = _steps[_step];
    final c = s['color'] as Color;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle, border: Border.all(color: cardBdr)),
                  child: Icon(Icons.arrow_back_rounded, size: 20, color: textMain),
                ),
              ),
              const Spacer(),
              Text('Paso ${_step + 1}/${_steps.length}', style: TextStyle(color: textSub, fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              const SizedBox(width: 40),
            ]),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: cardBdr),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(s['icon'] as IconData, color: c, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(s['title'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: c)),
                  const SizedBox(height: 16),
                  Text(s['content'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textSub, height: 1.5)),
                  
                  if ((s['ex'] as String).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: 0.2))),
                      child: Text(s['ex'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textMain)),
                    ),
                  ]
                ]),
              ),
            ),
          ),
          
          // Controls
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              if (_step > 0)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _step--),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: cardBg, border: Border.all(color: cardBdr), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: Text('ATRÁS', style: TextStyle(color: textSub, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    if (_step < _steps.length - 1) setState(() => _step++);
                    else widget.onBack();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                    alignment: Alignment.center,
                    child: Text(_step < _steps.length - 1 ? 'SIGUIENTE' : 'EMPEZAR', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Submode Selection ──────────────────────────────────────────────────────
class _MathSubmodeSelection extends StatelessWidget {
  final MentalTest test;
  final List<Map<String, dynamic>> modes;
  final int selectedMode;
  final List<Map<String, dynamic>> subs;
  final VoidCallback onBack;
  final VoidCallback onTut;

  const _MathSubmodeSelection({required this.test, required this.modes, required this.selectedMode, required this.subs, required this.onBack, required this.onTut});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle, border: Border.all(color: cardBdr)),
                  child: Icon(Icons.arrow_back_rounded, size: 20, color: textMain),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Operaciones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textMain, letterSpacing: -0.5)),
                Text('Elige la dificultad', style: TextStyle(fontSize: 13, color: textSub)),
              ])),
              GestureDetector(
                onTap: onTut,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.school_rounded, size: 20, color: Color(0xFFF59E0B)),
                ),
              ),
            ]),
          ),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: subs.length,
              itemBuilder: (_, i) {
                final s = subs[i];
                final sc = s['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      final q = QuestionService.getMathQuestions(s['op'], 10);
                      Navigator.push(context, SmoothPageRoute(page: _AttentionGamePage(
                        test: test,
                        mode: {
                          'title': '${modes[selectedMode]['title']} - ${s['title']}',
                          'desc': s['desc'],
                          'icon': s['icon'],
                          'color': s['color'],
                          'q': q,
                          'subop': s['op']
                        },
                        onBack: onBack,
                      )));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBdr),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                          child: Icon(s['icon'], color: sc, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textMain)),
                          const SizedBox(height: 4),
                          Text(s['desc'], style: TextStyle(fontSize: 13, color: textSub)),
                        ])),
                        Icon(Icons.chevron_right_rounded, color: cardBdr, size: 24),
                      ]),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideX(begin: 0.05),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Game Engine ────────────────────────────────────────────────────────────
class _AttentionGamePage extends StatefulWidget {
  final MentalTest test;
  final Map<String, dynamic> mode;
  final VoidCallback onBack;
  const _AttentionGamePage({required this.test, required this.mode, required this.onBack});
  @override
  State<_AttentionGamePage> createState() => __AttentionGamePageState();
}

class __AttentionGamePageState extends State<_AttentionGamePage> {
  int _idx = 0;
  int _score = 0;
  bool _feedback = false;
  bool _isCorrect = false;
  bool _done = false;
  DateTime? _start;
  late List<dynamic> _q;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _q = widget.mode['q'];
  }

  void _answer(int optIdx) {
    if (_done || _feedback) return;
    
    final correct = optIdx == _q[_idx]['correct'];
    setState(() {
      _isCorrect = correct;
      _feedback = true;
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _feedback = false;
        if (_idx < _q.length - 1) {
          _idx++;
        } else {
          _done = true;
          _showRes();
        }
      });
    });
  }

  void _showRes() {
    final t = DateTime.now().difference(_start!).inSeconds;
    final perc = (_score / _q.length) * 100;
    final r = TestResultData(
      testId: widget.test.id,
      score: _score * 100,
      date: DateTime.now(),
      timeSpent: t,
      details: {
        'correctAnswers': _score,
        'totalQuestions': _q.length,
        'percentage': perc.toStringAsFixed(1),
        'attentionMode': widget.mode['title'],
        'mathSubmode': widget.mode['subop'],
        'testType': 'attention',
      },
    );
    ResultsRepository.addResult(r);
    AchievementService.checkAfterTest(context, r);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResDialog(test: widget.test, mode: widget.mode, score: _score, total: _q.length, perc: perc),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_q.isEmpty) return const SizedBox();
    
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final mc       = widget.mode['color'] as Color;

    final curr = _q[_idx];
    final prog = (_idx + 1) / _q.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  else widget.onBack();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle, border: Border.all(color: cardBdr)),
                  child: Icon(Icons.close_rounded, size: 20, color: textMain),
                ),
              ),
              const Spacer(),
              Column(children: [
                Text(widget.mode['title'], style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w800)),
                Text('Aciertos: $_score', style: TextStyle(color: textSub, fontSize: 12)),
              ]),
              const Spacer(),
              const SizedBox(width: 42),
            ]),
          ),

          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 6,
              decoration: BoxDecoration(color: cardBdr, borderRadius: BorderRadius.circular(3)),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                widthFactor: prog,
                child: Container(decoration: BoxDecoration(color: mc, borderRadius: BorderRadius.circular(3))),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Question Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBdr),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: mc.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(widget.mode['icon'], color: mc, size: 36),
                ),
                const SizedBox(height: 24),
                Text(curr['question'], textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textMain, height: 1.3)),
              ]),
            ).animate(key: ValueKey(_idx)).fadeIn(duration: 300.ms).slideY(begin: 0.05),
          ),
          const SizedBox(height: 30),

          // Options
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: curr['options'].length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _answer(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBdr, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(curr['options'][i].toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textMain)),
                  ),
                ).animate(key: ValueKey('${_idx}_$i')).fadeIn(delay: Duration(milliseconds: 50 + i * 50)).slideX(begin: 0.05),
              ),
            ),
          ),

          // Feedback toast
          if (_feedback)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  border: Border.all(color: _isCorrect ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: _isCorrect ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(_isCorrect ? '¡Correcto!' : 'Incorrecto', style: TextStyle(color: _isCorrect ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            ),
        ]),
      ),
    );
  }
}

// ─── Result Dialog ──────────────────────────────────────────────────────────
class _ResDialog extends StatelessWidget {
  final MentalTest test;
  final Map<String, dynamic> mode;
  final int score;
  final int total;
  final double perc;

  const _ResDialog({required this.test, required this.mode, required this.score, required this.total, required this.perc});

  Color _darker(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent   = test.colorValue;

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(perc >= 80 ? Icons.emoji_events_rounded : Icons.self_improvement_rounded, color: accent, size: 64),
            const SizedBox(height: 16),
            Text('¡Test Completado!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain)),
            Text(mode['title'], style: TextStyle(fontSize: 14, color: textSub, fontWeight: FontWeight.w600)),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_rounded, color: accent, size: 24),
                  const SizedBox(width: 8),
                  Text('$score/$total', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: accent)),
                ]),
                const SizedBox(height: 4),
                Text('${perc.toStringAsFixed(1)}% de precisión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
              ]),
            ),
            
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(context, SmoothReplaceRoute(page: const HomePage()), (r) => false);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, _darker(accent)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: const Text('VOLVER AL INICIO', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}