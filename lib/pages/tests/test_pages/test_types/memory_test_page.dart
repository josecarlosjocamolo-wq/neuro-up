import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../test_model.dart';
import '../../results_repository.dart';
import '../../../../services/achievement_service.dart';
import '../../../../widgets/smooth_page_route.dart';
import '../../../../pages/home/home_page.dart';

class MemoryTestPage extends StatefulWidget {
  final MentalTest test;
  const MemoryTestPage({super.key, required this.test});
  @override
  State<MemoryTestPage> createState() => _MemoryTestPageState();
}

class _MemoryTestPageState extends State<MemoryTestPage> {
  bool _modeSelected = false;
  int _selectedMode = 0;

  final List<Map<String, dynamic>> _modes = [
    {
      'title': 'Símbolos de Colores',
      'desc': 'Secuencias de emojis de colores',
      'icon': Icons.color_lens_rounded,
      'symbols': ['🔴', '🔵', '🟢', '🟡', '🟣'],
    },
    {
      'title': 'Secuencias Numéricas',
      'desc': 'Memoriza secuencias de números',
      'icon': Icons.numbers_rounded,
      'symbols': ['1', '2', '3', '4', '5'],
    },
    {
      'title': 'Secuencias de Letras',
      'desc': 'Memoriza letras tranquilamente',
      'icon': Icons.abc_rounded,
      'symbols': ['A', 'B', 'C', 'D', 'E'],
    },
    {
      'title': 'Patrones Geométricos',
      'desc': 'Secuencias de figuras geométricas',
      'icon': Icons.architecture_rounded,
      'symbols': ['▲', '●', '■', '★', '◆'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_modeSelected) {
      return _MemoryGamePage(
        test: widget.test,
        mode: _modes[_selectedMode],
        onBack: () => setState(() => _modeSelected = false),
      );
    }

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
                Text('Memoria', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textMain, letterSpacing: -0.5)),
                Text('Elige tu modo de juego', style: TextStyle(fontSize: 13, color: textSub)),
              ])),
            ]),
          ),

          // Tip banner
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
                  Text('No hay límite de tiempo. Tómate el tiempo necesario para memorizar.',
                      style: TextStyle(fontSize: 12, color: isDark ? textSub : accent.withValues(alpha: 0.8), height: 1.3)),
                ])),
              ]),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          ),
          const SizedBox(height: 20),

          // List of modes
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _modes.length,
              itemBuilder: (_, i) {
                final mode = _modes[i];
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
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                          child: Icon(mode['icon'], color: accent, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(mode['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textMain)),
                          const SizedBox(height: 4),
                          Text(mode['desc'], style: TextStyle(fontSize: 13, color: textSub, height: 1.3)),
                        ])),
                        Icon(Icons.chevron_right_rounded, color: cardBdr, size: 24),
                      ]),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 + i * 50)).slideX(begin: 0.05),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Game Engine ──────────────────────────────────────────────────────────────
class _MemoryGamePage extends StatefulWidget {
  final MentalTest test;
  final Map<String, dynamic> mode;
  final VoidCallback onBack;
  const _MemoryGamePage({required this.test, required this.mode, required this.onBack});
  @override
  State<_MemoryGamePage> createState() => __MemoryGamePageState();
}

class __MemoryGamePageState extends State<_MemoryGamePage> {
  final int _maxLvl = 6;
  int _currentLvl = 0;
  int _score = 0;
  
  List<int> _seq = [];
  List<int> _userSeq = [];
  
  bool _showing = true;
  int _seqIdx = 0;
  DateTime? _start;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _generate();
  }

  void _generate() {
    setState(() {
      _seq = [];
      _userSeq = [];
      _seqIdx = 0;
      _showing = true;
      for (int i = 0; i <= _currentLvl; i++) {
        _seq.add(_rnd.nextInt(widget.mode['symbols'].length));
      }
    });
    _playSeq();
  }

  void _playSeq() {
    if (_seqIdx < _seq.length) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() => _seqIdx++);
        _playSeq();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _showing = false);
      });
    }
  }

  void _tapSymbol(int idx) {
    if (_showing) return;
    setState(() => _userSeq.add(idx));

    // Check input so far
    for (int i = 0; i < _userSeq.length; i++) {
      if (_userSeq[i] != _seq[i]) {
        _endGame(false);
        return;
      }
    }

    // Level completed?
    if (_userSeq.length == _seq.length) {
      _score += (_currentLvl + 1) * 10;
      if (_currentLvl < _maxLvl - 1) {
        setState(() => _currentLvl++);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _generate();
        });
      } else {
        _endGame(true);
      }
    }
  }

  void _endGame(bool completed) {
    final t = DateTime.now().difference(_start!).inSeconds;
    final r = TestResultData(
      testId: widget.test.id,
      score: _score,
      date: DateTime.now(),
      timeSpent: t,
      details: {
        'levelReached': _currentLvl + 1,
        'maxLevel': _maxLvl,
        'completed': completed,
        'memoryMode': widget.mode['title'],
        'testType': 'memory',
      },
    );
    ResultsRepository.addResult(r);
    AchievementService.checkAfterTest(context, r);
    _showDialog(completed, r);
  }

  void _showDialog(bool completed, TestResultData r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        test: widget.test,
        score: _score,
        completed: completed,
        lvl: _currentLvl + 1,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent   = widget.test.colorValue;

    final progress = (_currentLvl + 1) / _maxLvl;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              Column(children: [
                Text(widget.mode['title'], style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w800)),
                Text('Nivel ${_currentLvl + 1}/$_maxLvl', style: TextStyle(color: textSub, fontSize: 12)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.stars_rounded, color: accent, size: 14),
                  const SizedBox(width: 4),
                  Text('$_score', style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
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
                widthFactor: progress,
                child: Container(decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Board
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Info Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _showing ? 'Observa la secuencia...' : 'Tu turno',
                    key: ValueKey(_showing),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textMain),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _showing ? 'Elemento ${_seqIdx}/${_seq.length}' : 'Reproduce el orden exacto',
                    key: ValueKey(_showing ? _seqIdx : -1),
                    style: TextStyle(fontSize: 14, color: _showing ? textSub : accent, fontWeight: FontWeight.w600),
                  ),
                ),
                
                const Spacer(),

                // Central Symbol (When showing)
                if (_showing)
                  SizedBox(
                    height: 140,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _seqIdx < _seq.length ? 1.0 : 0.0,
                        child: Text(
                          _seqIdx < _seq.length ? widget.mode['symbols'][_seq[_seqIdx]] : '',
                          style: const TextStyle(fontSize: 80),
                        ).animate(key: ValueKey(_seqIdx)).scale(begin: const Offset(0.5, 0.5), duration: 200.ms, curve: Curves.easeOutBack),
                      ),
                    ),
                  )
                else
                  // Grid (When playing)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: widget.mode['symbols'].length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _tapSymbol(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBdr, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: Text(widget.mode['symbols'][i], style: const TextStyle(fontSize: 36)),
                      ),
                    ).animate().scale(delay: Duration(milliseconds: i * 50), curve: Curves.easeOutBack),
                  ),

                const Spacer(),
              ]),
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
  final bool completed;
  final int lvl;

  const _ResultDialog({required this.test, required this.score, required this.completed, required this.lvl});

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
            Icon(completed ? Icons.emoji_events_rounded : Icons.self_improvement_rounded, color: accent, size: 64),
            const SizedBox(height: 16),
            Text(completed ? '¡Excelente memoria!' : 'Buen intento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textMain)),
            const SizedBox(height: 8),
            Text('Completaste el nivel $lvl.', style: TextStyle(fontSize: 14, color: textSub, fontWeight: FontWeight.w600)),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.stars_rounded, color: accent, size: 28),
                const SizedBox(width: 8),
                Text('$score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: accent)),
                const SizedBox(width: 8),
                Text('pts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent)),
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