import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../test_model.dart';
import '../../results_repository.dart';
import '../../question_service.dart';
import '../../../../services/achievement_service.dart';
import '../../../../widgets/smooth_page_route.dart';
import '../../../../pages/home/home_page.dart';

class EmotionTestPage extends StatefulWidget {
  final MentalTest test;
  const EmotionTestPage({super.key, required this.test});
  @override
  State<EmotionTestPage> createState() => _EmotionTestPageState();
}

class _EmotionTestPageState extends State<EmotionTestPage> {
  int _current = 0;
  final List<int> _answers = [];
  DateTime? _startTime;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _questions = QuestionService.getEmotionQuestions(5);
  }

  void _answer(int selectedIndex) {
    setState(() {
      _answers.add(selectedIndex);
      if (_current < _questions.length - 1) {
        _current++;
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    final timeSpent = DateTime.now().difference(_startTime!).inSeconds;

    Map<int, int> scoreCount = {};
    for (int ans in _answers) {
      scoreCount[ans] = (scoreCount[ans] ?? 0) + 1;
    }
    int dominant = scoreCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final types = [
      'Emocional Reflexivo',
      'Emocional Expresivo',
      'Emocional Controlado',
      'Emocional Reactivo'
    ];

    int score = 800 + (dominant * 100) + (_answers.length * 50);

    final result = TestResultData(
      testId: widget.test.id,
      score: score,
      date: DateTime.now(),
      timeSpent: timeSpent,
      details: {
        'emotionalType': types[dominant],
        'answers': _answers,
        'dominantEmotionIndex': dominant,
        'testType': 'emotion',
      },
    );

    ResultsRepository.addResult(result);
    AchievementService.checkAfterTest(context, result);

    final descriptions = [
      'Eres una persona que reflexiona profundamente sobre sus emociones. Tiendes a analizar tus sentimientos y necesitas tiempo para procesar las situaciones emocionales.',
      'Expresas tus emociones abiertamente y con intensidad. Eres espontáneo y genuino en tus reacciones emocionales, lo que te hace muy auténtico.',
      'Mantienes un buen control sobre tus emociones. Eres equilibrado y racional, lo que te ayuda a tomar decisiones conscientes incluso en situaciones difíciles.',
      'Tus emociones son intensas y reactivas. Respondes rápidamente a los estímulos emocionales, lo que puede darte energía pero también requiere manejo.'
    ];

    final strengths = [
      'Empatía profunda, autoconocimiento, capacidad de reflexión',
      'Autenticidad, espontaneidad, capacidad de disfrute',
      'Estabilidad emocional, racionalidad, capacidad de liderazgo',
      'Pasión, intensidad, capacidad de motivación'
    ];

    final recommendations = [
      'Practica la expresión emocional y busca equilibrio entre reflexión y acción.',
      'Desarrolla estrategias para manejar emociones intensas y mantén tu autenticidad.',
      'Permítete experimentar emociones más intensas ocasionalmente para mayor conexión.',
      'Practica técnicas de pausa y reflexión antes de reaccionar emocionalmente.'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        test: widget.test,
        score: score,
        timeSpent: timeSpent,
        type: types[dominant],
        desc: descriptions[dominant],
        strengths: strengths[dominant],
        recs: recommendations[dominant],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const SizedBox();

    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent   = widget.test.colorValue;

    final currentQ = _questions[_current];
    final progress = (_current + 1) / _questions.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle, border: Border.all(color: cardBdr)),
                  child: Icon(Icons.close_rounded, size: 20, color: textMain),
                ),
              ),
              const Spacer(),
              Text('Pregunta ${_current + 1} de ${_questions.length}',
                  style: TextStyle(color: textSub, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              const SizedBox(width: 38),
            ]),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 6,
              decoration: BoxDecoration(color: cardBdr, borderRadius: BorderRadius.circular(3)),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                widthFactor: progress,
                child: Container(decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Question Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBdr),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.psychology_rounded, color: accent, size: 32),
                ),
                const SizedBox(height: 20),
                Text(currentQ['question'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain, height: 1.4)),
              ]),
            ).animate(key: ValueKey(_current)).fadeIn(duration: 300.ms).slideY(begin: 0.05),
          ),
          const SizedBox(height: 30),

          // Options
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: currentQ['options'].length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _answer(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBdr),
                    ),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: cardBdr.withValues(alpha: 0.5), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textSub)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(currentQ['options'][i],
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textMain)),
                      ),
                    ]),
                  ),
                ).animate(key: ValueKey('${_current}_$i'))
                 .fadeIn(delay: Duration(milliseconds: 100 + i * 50))
                 .slideX(begin: 0.05),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Result Dialog ───────────────────────────────────────────────────────────
class _ResultDialog extends StatelessWidget {
  final MentalTest test;
  final int score;
  final int timeSpent;
  final String type;
  final String desc;
  final String strengths;
  final String recs;

  const _ResultDialog({
    required this.test, required this.score, required this.timeSpent,
    required this.type, required this.desc, required this.strengths, required this.recs,
  });

  Color _darker(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent   = test.colorValue;

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.psychology_rounded, color: accent, size: 52),
            const SizedBox(height: 14),
            Text('Resultado', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain)),
            
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text('Perfil detectado', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(type, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
              ]),
            ),
            
            const SizedBox(height: 20),
            Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: textSub, height: 1.5)),
            
            const SizedBox(height: 20),
            _section('💪 Fortalezas', strengths, textMain, textSub),
            const SizedBox(height: 12),
            _section('📈 Recomendaciones', recs, textMain, textSub),
            
            const SizedBox(height: 20),
            Divider(color: cardBdr),
            const SizedBox(height: 12),
            
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat(Icons.stars_rounded, 'Puntuación', '$score', accent, textMain),
              _stat(Icons.timer_rounded, 'Tiempo', '${timeSpent}s', textSub, textMain),
            ]),
            
            const SizedBox(height: 24),
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

  Widget _section(String title, String content, Color textMain, Color textSub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textMain)),
      const SizedBox(height: 4),
      Text(content, style: TextStyle(fontSize: 13, color: textSub, height: 1.4)),
    ]);
  }

  Widget _stat(IconData icon, String label, String value, Color color, Color textMain) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textMain)),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
    ]);
  }
}