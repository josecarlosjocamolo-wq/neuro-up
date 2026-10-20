import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/pomodoro_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/calm_mode_notifier.dart';

class PomodoroTimerWidget extends StatefulWidget {
  final bool compact;
  const PomodoroTimerWidget({super.key, this.compact = false});

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget>
    with SingleTickerProviderStateMixin {
  final PomodoroService _svc = PomodoroService.instance;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _svc.loadSettings();
    _svc.addListener(_onServiceUpdate);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _svc.removeListener(_onServiceUpdate);
    _glowCtrl.dispose();
    super.dispose();
  }

  // ─── Settings dialog ─────────────────────────────────────────────────────
  void _showSettings() {
    int tempStudy = _svc.studyTime;
    int tempBreak = _svc.breakTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: isDark ? Border.all(color: const Color(0xFF334155), width: 1) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ajustes', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                _buildSliderCard(
                  ctx: ctx,
                  setDlg: setDlg,
                  label: 'Tiempo de Estudio',
                  value: tempStudy,
                  icon: Icons.auto_stories_rounded,
                  colors: [AppColors.primary, AppColors.secondary],
                  onChanged: (v) => tempStudy = v.round(),
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildSliderCard(
                  ctx: ctx,
                  setDlg: setDlg,
                  label: 'Tiempo de Descanso',
                  value: tempBreak,
                  icon: Icons.self_improvement_rounded,
                  colors: [AppColors.success, const Color(0xFF1DE9B6)],
                  onChanged: (v) => tempBreak = v.round(),
                  isDark: isDark,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          _svc.updateSettings(tempStudy, tempBreak);
                          await _svc.saveSettings();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required BuildContext ctx,
    required StateSetter setDlg,
    required IconData icon,
    required String label,
    required int value,
    required List<Color> colors,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[0].withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: colors[0], size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '$value min',
                style: TextStyle(color: colors[0], fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(ctx).copyWith(
              thumbColor: colors[0],
              activeTrackColor: colors[0],
              inactiveTrackColor: colors[0].withOpacity(0.12),
              overlayColor: colors[0].withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              trackHeight: 5,
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              min: 1,
              max: 60,
              value: value.toDouble().clamp(1.0, 60.0),
              onChanged: (v) => setDlg(() => onChanged(v)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: calmModeNotifier,
      builder: (context, isCalmMode, _) {
        if (isCalmMode && _glowCtrl.isAnimating) {
          _glowCtrl.stop();
        } else if (!isCalmMode && !_glowCtrl.isAnimating) {
          _glowCtrl.repeat(reverse: true);
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scale = widget.compact ? 0.9 : 1.0;
        final size = 260.0 * scale;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(widget.compact ? 20 : 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(widget.compact ? 24 : 32),
            border: isDark ? Border.all(color: const Color(0xFF334155), width: 1) : null,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header del Pomodoro
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pomodoro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Enfoque profundo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Círculo del timer
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: CustomPaint(
                        painter: _ThickTimerPainter(
                          progress: _svc.progress,
                          isStudy: _svc.isStudyTime,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          _svc.formattedTime,
                          style: TextStyle(
                            fontSize: 54 * scale,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -2,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          _svc.isStudyTime ? 'Enfoque' : 'Descanso',
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 70 * scale,
                          height: 70 * scale,
                          child: Image.asset('assets/gifs/upicora.gif', fit: BoxFit.contain),
                        ).animate(onPlay: (c) { if(!isCalmMode) c.repeat(reverse: true); })
                         .moveY(begin: -2, end: 2, duration: 2.seconds, curve: Curves.easeInOut),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botones de control inferiores
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _svc.resetTimer,
                    icon: Icon(Icons.refresh_rounded, size: 24, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _svc.toggleTimer,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _svc.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: _showSettings,
                    icon: Icon(Icons.tune_rounded, size: 24, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Siguiente: ${_svc.isStudyTime ? 'Descanso ${_svc.breakTime} min' : 'Estudio ${_svc.studyTime} min'}',
                style: TextStyle(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter – Diseño limpio tipo Ring para el timer
// ─────────────────────────────────────────────────────────────────────────────
class _ThickTimerPainter extends CustomPainter {
  final double progress;
  final bool isStudy;
  final bool isDark;

  _ThickTimerPainter({
    required this.progress,
    required this.isStudy,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 16.0;

    // Track de fondo
    final trackColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    // Gradiente de progreso
    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final colors = isStudy
        ? [AppColors.cyan, AppColors.secondary]
        : [AppColors.success, const Color(0xFF1DE9B6)];

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + 2 * math.pi,
          colors: [colors[0], colors[1], colors[0]],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _ThickTimerPainter old) =>
      old.progress != progress || old.isStudy != isStudy || old.isDark != isDark;
}
