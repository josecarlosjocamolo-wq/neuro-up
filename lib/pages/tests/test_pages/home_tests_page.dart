import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../test_model.dart';
import '../test_data.dart';
import 'test_detail_page.dart';
import 'results_page.dart';
import '../../../widgets/smooth_page_route.dart';

// ─── Per-test visual config ──────────────────────────────────────────────────
const _kTestCfg = {
  'attention': _TstCfg(Color(0xFF3B82F6), Color(0xFF1D4ED8), Icons.center_focus_strong_rounded, '5-8 min', 'Media'),
  'memory':    _TstCfg(Color(0xFF10B981), Color(0xFF047857), Icons.grid_view_rounded,            '4-6 min', 'Media'),
  'emotion':   _TstCfg(Color(0xFF8B5CF6), Color(0xFF6D28D9), Icons.favorite_rounded,             '3-5 min', 'Fácil'),
};

class _TstCfg {
  final Color color;
  final Color dark;
  final IconData icon;
  final String duration;
  final String difficulty;
  const _TstCfg(this.color, this.dark, this.icon, this.duration, this.difficulty);
}

_TstCfg _cfg(String id) => _kTestCfg[id] ?? const _TstCfg(Color(0xFF64748B), Color(0xFF475569), Icons.quiz_rounded, '5 min', 'Media');

// ═════════════════════════════════════════════════════════════════════════════
class HomeTestsPage extends StatelessWidget {
  const HomeTestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tests  = TestData.getTests().where((t) => t.id != 'speed').toList();

    final bg    = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      color: bg,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ────────────────────────────────────────────────────
            _header(isDark, textMain, textSub),
            const SizedBox(height: 24),

            // ── Banner cognitivo ──────────────────────────────────────────
            _banner(isDark, tests.length, textMain, textSub),
            const SizedBox(height: 28),

            // ── Sección: Tests disponibles ────────────────────────────────
            Text('Tests disponibles',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: textMain, letterSpacing: -0.3))
                .animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 4),
            Text('Cada uno mide una habilidad diferente de tu mente.',
                style: TextStyle(fontSize: 13, color: textSub))
                .animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),

            // ── Test cards ────────────────────────────────────────────────
            ...tests.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _testCard(context, e.value, isDark, e.key,
                  textMain, textSub, cardBg, cardBorder),
            )),

            const SizedBox(height: 8),

            // ── Results card ──────────────────────────────────────────────
            _resultsCard(context, isDark, cardBg, cardBorder, textMain, textSub),
          ]),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _header(bool isDark, Color textMain, Color textSub) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Modo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSub)),
            Text('Tests', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                color: textMain, height: 1.1, letterSpacing: -0.5)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.psychology_rounded, color: Color(0xFF8B5CF6), size: 16),
            const SizedBox(width: 6),
            const Text('Cognitivos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6))),
          ]),
        ),
      ]).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
    );
  }

  // ── Banner ───────────────────────────────────────────────────────────────────
  Widget _banner(bool isDark, int count, Color textMain, Color textSub) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tu perfil cognitivo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textMain)),
            const SizedBox(height: 6),
            Text('Completa los $count tests para conocer tus fortalezas y áreas de mejora.',
                style: TextStyle(fontSize: 13, height: 1.5, color: textSub)),
            const SizedBox(height: 14),
            // Progress bar segments
            Row(children: [
              _segment(const Color(0xFF3B82F6)),
              const SizedBox(width: 5),
              _segment(const Color(0xFF10B981)),
              const SizedBox(width: 5),
              _segment(const Color(0xFF8B5CF6)),
            ]),
          ]),
        ),
        const SizedBox(width: 16),
        // Count badge
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            const Text('tests', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70)),
          ]),
        ),
      ]),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08);
  }

  Widget _segment(Color color) => Expanded(
    child: Container(
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );

  // ── Test card ────────────────────────────────────────────────────────────────
  Widget _testCard(BuildContext ctx, MentalTest test, bool isDark, int idx,
      Color textMain, Color textSub, Color cardBg, Color cardBorder) {
    final c = _cfg(test.id);

    return GestureDetector(
      onTap: () => Navigator.push(ctx, SmoothPageRoute(page: TestDetailPage(test: test))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.color.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(c.icon, color: c.color, size: 26),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(test.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textMain)),
              const SizedBox(height: 3),
              Text(test.subtitle, style: TextStyle(fontSize: 12, color: textSub, height: 1.4),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                _miniChip(Icons.timer_outlined, c.duration, textSub, cardBorder, isDark),
                const SizedBox(width: 8),
                _miniChip(Icons.bar_chart_rounded, c.difficulty, textSub, cardBorder, isDark),
              ]),
            ]),
          ),
          const SizedBox(width: 10),
          // Arrow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.color.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_forward_rounded, color: c.color, size: 18),
          ),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: 300 + idx * 80)).slideX(begin: 0.06, curve: Curves.easeOut),
    );
  }

  Widget _miniChip(IconData icon, String label, Color textSub, Color border, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: textSub),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSub)),
      ]),
    );
  }

  // ── Results card ─────────────────────────────────────────────────────────────
  Widget _resultsCard(BuildContext ctx, bool isDark, Color cardBg, Color cardBorder,
      Color textMain, Color textSub) {
    const accent = Color(0xFF4F46E5);

    return GestureDetector(
      onTap: () => Navigator.push(ctx, SmoothPageRoute(page: ResultsPage())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_graph_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ver Resultados', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textMain)),
              const SizedBox(height: 3),
              Text('Consulta tu evolución y progreso cognitivo', style: TextStyle(fontSize: 12, color: textSub)),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 14),
        ]),
      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.08),
    );
  }
}