import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';
import '../../../theme/calm_mode_notifier.dart';
class AnimatedWaveBackground extends StatefulWidget {
  final Widget child;
  const AnimatedWaveBackground({super.key, required this.child});

  @override
  State<AnimatedWaveBackground> createState() => _AnimatedWaveBackgroundState();
}

class _AnimatedWaveBackgroundState extends State<AnimatedWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: calmModeNotifier,
      builder: (context, isCalmMode, childWidget) {
        if (isCalmMode) {
          // Detenemos animación para ahorrar CPU en modo calma
          if (_controller.isAnimating) _controller.stop();
          return RepaintBoundary(
            child: CustomPaint(
              painter: WavePainter(0.0, isCalmMode: true),
              child: widget.child,
            ),
          );
        } else {
          if (!_controller.isAnimating) _controller.repeat();
          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(_controller.value, isCalmMode: false),
                  child: widget.child,
                );
              },
            ),
          );
        }
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final bool isCalmMode;
  WavePainter(this.animationValue, {this.isCalmMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // GUARDIA CRÍTICA: Evita NaN, division by zero y bucles infinitos
    // que ocurren cuando Flutter pasa dimensiones inválidas durante el resize
    if (w <= 0 || h <= 0 || !w.isFinite || !h.isFinite) return;

    // Fondo base con gradiente
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    if (isCalmMode) return;

    // 3 capas de olas (bajo costo de CPU)
    _drawWave(canvas, w, h, animationValue * 2 * math.pi,
        Colors.white.withOpacity(0.08), 0.65, 1.5, 15);
    _drawWave(canvas, w, h, (animationValue + 0.3) * 2 * math.pi,
        AppColors.secondary.withOpacity(0.20), 0.72, 1.1, 18);
    _drawWave(canvas, w, h, (animationValue + 0.6) * 2 * math.pi,
        Colors.white.withOpacity(0.10), 0.80, 0.8, 12);

    // Estrellas/partículas - SIN drawShadow (causa freeze en web)
    _drawStar(canvas, w, h, 0.15, 0.25, 4.0, 1.5);
    _drawStar(canvas, w, h, 0.85, 0.20, 5.0, 0.8);
    _drawStar(canvas, w, h, 0.50, 0.12, 3.0, 2.0);
    _drawStar(canvas, w, h, 0.90, 0.70, 4.0, 1.2);
    _drawStar(canvas, w, h, 0.10, 0.75, 3.5, 2.5);
  }

  void _drawStar(Canvas canvas, double w, double h,
      double px, double py, double size, double speed) {
    final double ox = math.sin((animationValue * 2 * math.pi * speed) + px * 10) * 12;
    final double oy = math.cos((animationValue * 2 * math.pi * speed) + py * 10) * 12;
    final double alpha = ((math.sin(animationValue * 2 * math.pi * speed * 2) + 1) / 2) * 0.5 + 0.5;

    final center = Offset(w * px + ox, h * py + oy);

    // Círculo central (mucho más eficiente que Path en canvas web)
    canvas.drawCircle(center, size * 0.5,
        Paint()..color = Colors.white.withOpacity(alpha));

    // Cruz de luz con dos líneas simples (sin shadow — era la causa del freeze)
    final lp = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, center.dy - size),
        Offset(center.dx, center.dy + size), lp);
    canvas.drawLine(Offset(center.dx - size, center.dy),
        Offset(center.dx + size, center.dy), lp);
  }

  void _drawWave(Canvas canvas, double w, double h, double offset,
      Color color, double heightFactor, double speed, double waveHeight) {
    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, h * heightFactor);

    // Paso de 14px: buena suavidad visual, bajo costo de CPU
    for (double i = 0; i <= w; i += 14) {
      final y = h * heightFactor +
          math.sin((i / w * 2 * math.pi * speed) + offset) * waveHeight;
      path.lineTo(i, y);
    }

    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant WavePainter old) =>
      old.animationValue != animationValue;
}
