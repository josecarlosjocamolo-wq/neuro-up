import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../test_model.dart';
import 'test_types/attention_test_page.dart';
import 'test_types/memory_test_page.dart';
import 'test_types/emotion_test_page.dart';
import '../../../widgets/smooth_page_route.dart';

// ─── Per-test color helper ────────────────────────────────────────────────────
Color _darker(Color c) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * 0.72).clamp(0.0, 1.0)).toColor();
}

// ═════════════════════════════════════════════════════════════════════════════
class TestInstructionPage extends StatelessWidget {
  final MentalTest test;
  const TestInstructionPage({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final accent   = test.colorValue;
    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────────────
        _header(context, accent, isDark),

        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            child: Column(children: [

              // Upi + label
              _upiBlock(accent, isDark).animate().scale(
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 24),

              // Main message card
              _messageCard(cardBg, cardBdr, textMain, textSub, isDark, accent)
                  .animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
              const SizedBox(height: 16),

              // Disclaimer card
              _disclaimerCard(isDark, cardBg, cardBdr)
                  .animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),
              const SizedBox(height: 28),

              // CTA
              _ctaButton(context, accent),
              const SizedBox(height: 12),

              // Back link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Volver atrás',
                    style: TextStyle(color: textSub, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _header(BuildContext ctx, Color accent, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, _darker(accent)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
            const Expanded(
              child: Text('Instrucciones de Upi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 40), // balance
          ]),
        ),
      ),
    );
  }

  // ── Upi block ────────────────────────────────────────────────────────────────
  Widget _upiBlock(Color accent, bool isDark) {
    return Column(children: [
      Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: ClipOval(
          child: Image.asset('assets/gifs/upica.gif', fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.psychology_rounded, size: 52, color: accent)),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('¡Hola! Soy Upi, tu compañero',
            style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  // ── Message card ─────────────────────────────────────────────────────────────
  Widget _messageCard(Color bg, Color border, Color textMain, Color textSub, bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.info_outline_rounded, color: accent, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Mensaje de Upi para ti',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textMain)),
        ]),
        const SizedBox(height: 14),
        Text(
          'Este test está diseñado como herramienta de autoconocimiento y evaluación cognitiva. '
          'Los resultados son indicativos y no constituyen un diagnóstico médico.',
          style: TextStyle(fontSize: 13, height: 1.6, color: textSub),
        ),
        const SizedBox(height: 14),
        Text(
          'Al continuar, aceptas que comprendes que este es un ejercicio de autoevaluación.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSub),
        ),
      ]),
    );
  }

  // ── Disclaimer card ───────────────────────────────────────────────────────────
  Widget _disclaimerCard(bool isDark, Color bg, Color border) {
    const amber = Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1700) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: amber.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.medical_information_rounded, color: amber, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Aviso importante',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: amber)),
            const SizedBox(height: 6),
            Text(
              'Si experimentas problemas de salud mental persistentes, te recomendamos consultar con un profesional. '
              'Esta aplicación no sustituye el diagnóstico médico profesional.',
              style: TextStyle(fontSize: 12, height: 1.5,
                  color: isDark ? const Color(0xFFD97706) : const Color(0xFF92400E)),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── CTA button ────────────────────────────────────────────────────────────────
  Widget _ctaButton(BuildContext ctx, Color accent) {
    return GestureDetector(
      onTap: () => _navigate(ctx),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, _darker(accent)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 7))],
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text('ENTENDIDO, CONTINUAR',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
        ]),
      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────────
  void _navigate(BuildContext ctx) {
    try {
      switch (test.id) {
        case 'attention':
          Navigator.push(ctx, SmoothPageRoute(page: AttentionTestPage(test: test)));
        case 'memory':
          Navigator.push(ctx, SmoothPageRoute(page: MemoryTestPage(test: test)));
        case 'emotion':
          Navigator.push(ctx, SmoothPageRoute(page: EmotionTestPage(test: test)));
        default:
          _showComingSoon(ctx);
      }
    } catch (e) {
      debugPrint('Error navigating to test: $e');
      _showError(ctx);
    }
  }

  void _showComingSoon(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.construction_rounded, color: Color(0xFFF59E0B)),
        SizedBox(width: 10),
        Text('Próximamente'),
      ]),
      content: Text('El test ${test.title} estará disponible en la próxima actualización.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
    ),
  );

  void _showError(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.error_outline_rounded, color: Colors.red),
        SizedBox(width: 10),
        Text('Error'),
      ]),
      content: const Text('Ocurrió un error al cargar el test. Intenta nuevamente.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ),
  );
}