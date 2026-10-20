import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/pomodoro_service.dart';

// ─── Constantes de diseño ────────────────────────────────────────────────────
const _kIndigo  = Color(0xFF4F46E5);
const _kViolet  = Color(0xFF7C3AED);
const _kGreen   = Color(0xFF10B981);
const _kEmerald = Color(0xFF059669);

const _kMotivational = [
  '¡Silencia el ruido. Este momento es tuyo!',
  '25 minutos. Tú puedes. Sin distracciones.',
  'Cada bloque completado es un logro real.',
  'El enfoque es un músculo. Estás entrenándolo.',
  'Una tarea a la vez. Eso es todo lo que se necesita.',
  '¡Vas increíble! Sigue así.',
];

// ═════════════════════════════════════════════════════════════════════════════
//  WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class EnfoquePage extends StatefulWidget {
  const EnfoquePage({super.key});
  @override
  State<EnfoquePage> createState() => _EnfoquePageState();
}

class _EnfoquePageState extends State<EnfoquePage>
    with SingleTickerProviderStateMixin {
  final PomodoroService _svc = PomodoroService.instance;
  late AnimationController _pulse;
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _svc.loadSettings();
    _svc.addListener(_onUpdate);
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _quoteIndex = math.Random().nextInt(_kMotivational.length);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    _pulse.dispose();
    super.dispose();
  }

  // ── Settings dialog ───────────────────────────────────────────────────────
  void _openSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int study = _svc.studyTime;
    int brk   = _svc.breakTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Configuración', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              )),
              const SizedBox(height: 28),
              _settingSlider(ctx, setSt, '⏱ Tiempo de enfoque', study, 5, 60, isDark,
                  (v) => setSt(() => study = v.round())),
              const SizedBox(height: 20),
              _settingSlider(ctx, setSt, '☕ Tiempo de descanso', brk, 1, 30, isDark,
                  (v) => setSt(() => brk = v.round())),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _svc.updateSettings(study, brk);
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _settingSlider(BuildContext ctx, StateSetter setSt, String label, int value,
      int min, int max, bool isDark, ValueChanged<double> onChanged) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: _kIndigo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text('$value min', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kIndigo)),
        ),
      ]),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderTheme.of(ctx).copyWith(
          activeTrackColor: _kIndigo,
          inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          thumbColor: _kIndigo,
          overlayColor: _kIndigo.withValues(alpha: 0.1),
          trackHeight: 4,
        ),
        child: Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: onChanged,
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$min min', style: TextStyle(fontSize: 11, color: subColor)),
        Text('$max min', style: TextStyle(fontSize: 11, color: subColor)),
      ]),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStudy = _svc.isStudyTime;
    final accentA = isStudy ? _kIndigo   : _kGreen;
    final accentB = isStudy ? _kViolet   : _kEmerald;
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Modo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSub)),
                  Text('Enfoque', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                      color: textMain, height: 1.1, letterSpacing: -0.5)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Mode toggle ─────────────────────────────────────────────────
          _modeToggle(isDark, textSub),

          const Spacer(),

          // ── Timer ring ──────────────────────────────────────────────────
          _timerRing(isDark, isStudy, accentA, accentB, textMain, cardBg),

          const SizedBox(height: 20),

          // ── Controls: [ −1 ] [ ▶/⏸ ] [ +1 ] ────────────────────────────
          _controls(isDark, accentA, accentB, textSub, textMain, cardBg, cardBorder),

          const SizedBox(height: 20),

          // ── Upi motivation card ─────────────────────────────────────────
          _upiCard(isDark, cardBg, textMain, textSub),

          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  // ── Header icon button ────────────────────────────────────────────────────
  Widget _headerIconBtn(IconData icon, Color fg, Color bg, Color border, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: bg, shape: BoxShape.circle,
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: fg),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
      ),
    );
  }

  // ── Mode toggle pill ──────────────────────────────────────────────────────
  Widget _modeToggle(bool isDark, Color textSub) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          _toggleTab('Enfoque', _svc.isStudyTime,
              const LinearGradient(colors: [_kIndigo, _kViolet]), textSub, () {
            if (!_svc.isStudyTime) { _svc.resetTimer(); setState(() {}); }
          }),
          _toggleTab('Descanso', !_svc.isStudyTime,
              const LinearGradient(colors: [_kGreen, _kEmerald]), textSub, () {
            if (_svc.isStudyTime) { _svc.resetTimer(); setState(() {}); }
          }),
        ]),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15),
    );
  }

  Widget _toggleTab(String label, bool active, Gradient grad, Color textSub, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: active ? grad : null,
            borderRadius: BorderRadius.circular(24),
            boxShadow: active ? [BoxShadow(color: (active && label == 'Enfoque' ? _kIndigo : _kGreen).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Text(
            label, textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? Colors.white : textSub,
            ),
          ),
        ),
      ),
    );
  }

  // ── Timer ring ────────────────────────────────────────────────────────────
  Widget _timerRing(bool isDark, bool isStudy, Color accentA, Color accentB, Color textMain, Color cardBg) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Glow underneath
          if (_svc.isRunning)
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: accentA.withValues(alpha: 0.15 + _pulse.value * 0.1),
                  blurRadius: 60 + _pulse.value * 20,
                  spreadRadius: 10 + _pulse.value * 10,
                )],
              ),
            ),
          // Ring
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: _RingPainter(
                progress: _svc.progress,
                isDark: isDark,
                colorA: accentA,
                colorB: accentB,
                pulse: _svc.isRunning ? _pulse.value : 0,
              ),
            ),
          ),
          // Center content
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              _svc.formattedTime,
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: textMain,
                letterSpacing: -3,
                height: 1,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentA, accentB]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isStudy ? '✦  Modo Enfoque' : '☕  Descanso',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOut);
  }

  // ── Session pills ─────────────────────────────────────────────────────────
  Widget _sessionPills(bool isDark, bool isStudy, Color cardBg, Color cardBorder, Color textMain, Color textSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(children: [
        _pill(Icons.timer_outlined, '${_svc.studyTime} min', 'Enfoque', _kIndigo, cardBg, cardBorder, textMain, textSub),
        const SizedBox(width: 12),
        _pill(Icons.coffee_outlined, '${_svc.breakTime} min', 'Descanso', _kGreen, cardBg, cardBorder, textMain, textSub),
        const SizedBox(width: 12),
        _pill(Icons.repeat_rounded, isStudy ? 'En curso' : 'Completado', 'Estado',
            isStudy ? _kIndigo : _kGreen, cardBg, cardBorder, textMain, textSub),
      ]).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _pill(IconData icon, String value, String label, Color accent,
      Color cardBg, Color cardBorder, Color textMain, Color textSub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Column(children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textMain)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: textSub, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Adjust study time by delta minutes (clamped 1–90) ────────────────────
  void _adjustTime(int delta) {
    if (_svc.isRunning) return; // no cambiar mientras corre
    final next = (_svc.studyTime + delta).clamp(1, 90);
    setState(() {
      _svc.studyTime = next;
      _svc.remainingTime = next * 60;
    });
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  Widget _controls(bool isDark, Color accentA, Color accentB, Color textSub,
      Color textMain, Color cardBg, Color cardBorder) {
    final iconColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final resetColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Column(children: [
      // ── Row: [ −1 min ] [ ▶/⏸ ] [ +1 min ] ────────────────────────────
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // −1 min button
        _timeAdjBtn('−1', iconColor, cardBg, cardBorder, () => _adjustTime(-1)),
        const SizedBox(width: 20),
        // Play / Pause
        GestureDetector(
          onTap: _svc.toggleTimer,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accentA, accentB]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: accentA.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Transform.scale(
                scale: _svc.isRunning ? 1.0 + _pulse.value * 0.04 : 1.0,
                child: Icon(
                  _svc.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // +1 min button
        _timeAdjBtn('+1', iconColor, cardBg, cardBorder, () => _adjustTime(1)),
      ]).animate().slideY(begin: 0.2, duration: 450.ms, curve: Curves.easeOut),

      const SizedBox(height: 16),

      // ── Reset button ────────────────────────────────────────────────────
      GestureDetector(
        onTap: _svc.resetTimer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.refresh_rounded, size: 16, color: resetColor),
            const SizedBox(width: 6),
            Text('Reiniciar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: resetColor)),
          ]),
        ),
      ).animate().fadeIn(delay: 200.ms),
    ]);
  }

  // Botón cuadrado de ajuste de tiempo ──────────────────────────────────────
  Widget _timeAdjBtn(String label, Color fg, Color bg, Color border, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg),
        ),
      ),
    );
  }

  // ── Upi card ──────────────────────────────────────────────────────────────
  Widget _upiCard(bool isDark, Color cardBg, Color textMain, Color textSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // Upi bounce
        SizedBox(
          width: 64,
          height: 64,
          child: Image.asset('assets/gifs/upiaudi.gif', fit: BoxFit.contain),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -6, end: 6, duration: const Duration(milliseconds: 1800), curve: Curves.easeInOut),

        const SizedBox(width: 12),

        // Speech bubble
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(20),
                topRight:    Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft:  Radius.circular(6),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Text(
              _kMotivational[_quoteIndex],
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMain, height: 1.45),
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, curve: Curves.easeOut),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTER — Timer ring
// ═════════════════════════════════════════════════════════════════════════════
class _RingPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color colorA;
  final Color colorB;
  final double pulse;

  const _RingPainter({
    required this.progress,
    required this.isDark,
    required this.colorA,
    required this.colorB,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const stroke = 12.0;
    const start  = -math.pi / 2;

    // ── Background track ──
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final rect  = Rect.fromCircle(center: center, radius: radius);

    final shader = SweepGradient(
      startAngle: start,
      endAngle: start + 2 * math.pi,
      colors: [colorA, colorB, colorA],
      stops: const [0.0, 0.55, 1.0],
      transform: GradientRotation(start),
    ).createShader(rect);

    // ── Glow layer ──
    if (pulse > 0) {
      canvas.drawArc(
        rect, start, sweep, false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke + pulse * 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // ── Main arc ──
    canvas.drawArc(
      rect, start, sweep, false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );

    // ── Dot at end of arc ──
    final endAngle = start + sweep;
    final dotOffset = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    canvas.drawCircle(dotOffset, stroke / 2 + 2,
        Paint()..color = colorB..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.isDark != isDark ||
      old.colorA != colorA || old.colorB != colorB || old.pulse != pulse;
}
