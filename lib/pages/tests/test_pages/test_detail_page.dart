import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../test_model.dart';
import 'test_instruction_page.dart';
import '/services/stats_service.dart';
import '../../../widgets/smooth_page_route.dart';

// ─── Per-test config (same as home_tests_page) ───────────────────────────────
const _kCfg = {
  'attention': _Cfg(Color(0xFF3B82F6), Color(0xFF1D4ED8), Icons.center_focus_strong_rounded, '5-8 min', 'Media'),
  'memory':    _Cfg(Color(0xFF10B981), Color(0xFF047857), Icons.grid_view_rounded,            '4-6 min', 'Media'),
  'emotion':   _Cfg(Color(0xFF8B5CF6), Color(0xFF6D28D9), Icons.favorite_rounded,             '3-5 min', 'Fácil'),
};

class _Cfg {
  final Color color;
  final Color dark;
  final IconData icon;
  final String duration;
  final String difficulty;
  const _Cfg(this.color, this.dark, this.icon, this.duration, this.difficulty);
}

_Cfg _getCfg(String id) => _kCfg[id] ?? const _Cfg(Color(0xFF64748B), Color(0xFF475569), Icons.quiz_rounded, '5 min', 'Media');

// ─── Instructions & tips per test ─────────────────────────────────────────────
const _kInstructions = {
  'attention': [
    'Observa cada estímulo que aparezca en pantalla con atención.',
    'Responde solo cuando identifiques el estímulo específico pedido.',
    'Mantén el enfoque durante toda la duración del test.',
    'Evita distracciones externas para obtener resultados precisos.',
  ],
  'memory': [
    'Memoriza la secuencia que se te presentará.',
    'Presta atención al orden y los detalles visuales.',
    'Reproduce la secuencia en el mismo orden.',
    'Confía en tu memoria visual y espacial.',
  ],
  'emotion': [
    'Reflexiona brevemente sobre cada situación presentada.',
    'Selecciona la respuesta que mejor describa tu reacción.',
    'No hay respuestas correctas o incorrectas.',
    'Sé honesto contigo mismo en cada elección.',
  ],
};

const _kTips = [
  _Tip(Icons.volume_off_rounded,   'Busca un ambiente tranquilo sin distracciones.'),
  _Tip(Icons.wifi_rounded,         'Asegúrate de tener buena conexión a internet.'),
  _Tip(Icons.verified_user_rounded,'Responde con sinceridad para resultados precisos.'),
  _Tip(Icons.timer_rounded,        'Tómate tu tiempo, no hay prisa.'),
];

class _Tip {
  final IconData icon;
  final String text;
  const _Tip(this.icon, this.text);
}

// ═════════════════════════════════════════════════════════════════════════════
class TestDetailPage extends StatelessWidget {
  final MentalTest test;
  const TestDetailPage({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c      = _getCfg(test.id);
    final instr  = _kInstructions[test.id] ?? _kInstructions['attention']!;

    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // ── Gradient header ────────────────────────────────────────────────
        _gradientHeader(context, c, isDark),

        // ── Scrollable content ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // About card
              _sectionCard(
                isDark, cardBg, cardBdr,
                icon: c.icon, iconColor: c.color,
                title: 'Sobre este test',
                child: Text(test.description,
                    style: TextStyle(fontSize: 14, height: 1.6, color: textSub)),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
              const SizedBox(height: 16),

              // Instructions card
              _sectionCard(
                isDark, cardBg, cardBdr,
                icon: Icons.list_alt_rounded, iconColor: c.color,
                title: 'Cómo realizarlo',
                child: Column(children: instr.asMap().entries.map((e) =>
                  _instrRow(e.key + 1, e.value, c.color, textSub, isDark),
                ).toList()),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
              const SizedBox(height: 16),

              // Tips card
              _sectionCard(
                isDark, cardBg, cardBdr,
                icon: Icons.lightbulb_outline_rounded, iconColor: const Color(0xFFF59E0B),
                title: 'Consejos',
                child: Column(children: _kTips.map((t) =>
                  _tipRow(t, textSub, isDark),
                ).toList()),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),
              const SizedBox(height: 28),

              // CTA button
              _ctaButton(context, c, isDark),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Gradient header ────────────────────────────────────────────────────────
  Widget _gradientHeader(BuildContext ctx, _Cfg c, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.color, c.dark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Back + duration pill
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_rounded, color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                  Text(c.duration, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            // Test icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(c.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            Text(test.title,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text(test.subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.4)),
          ]),
        ),
      ),
    );
  }

  // ── Section card ────────────────────────────────────────────────────────────
  Widget _sectionCard(bool isDark, Color bg, Color border, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  // ── Instruction row ──────────────────────────────────────────────────────────
  Widget _instrRow(int num, String text, Color accent, Color textSub, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$num', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.5, color: textSub))),
      ]),
    );
  }

  // ── Tip row ──────────────────────────────────────────────────────────────────
  Widget _tipRow(_Tip tip, Color textSub, bool isDark) {
    const accent = Color(0xFFF59E0B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(tip.icon, color: accent, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(tip.text, style: TextStyle(fontSize: 13, height: 1.4, color: textSub))),
      ]),
    );
  }

  // ── CTA button ───────────────────────────────────────────────────────────────
  Widget _ctaButton(BuildContext ctx, _Cfg c, bool isDark) {
    return GestureDetector(
      onTap: () {
        StatsService.recordTestCompleted();
        Navigator.push(ctx, SmoothPageRoute(page: TestInstructionPage(test: test)));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.color, c.dark]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(
            test.buttonText.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.6),
          ),
        ]),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
    );
  }
}