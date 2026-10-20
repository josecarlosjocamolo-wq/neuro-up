import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NeuroButtonType { primary, secondary, ghost }

class NeuroButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NeuroButtonType type;
  final bool isFullWidth;
  final bool isLoading;

  const NeuroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.type = NeuroButtonType.primary,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  const NeuroButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : type = NeuroButtonType.primary;

  const NeuroButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : type = NeuroButtonType.secondary;

  const NeuroButton.ghost({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : type = NeuroButtonType.ghost;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Altura mínima para accesibilidad TDAH (grandes y claros)
    const double minHeight = 56.0;

    Widget child = isLoading
        ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          );

    ButtonStyle style;

    switch (type) {
      case NeuroButtonType.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, minHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        );
        break;
      case NeuroButtonType.secondary:
        style = ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
          minimumSize: const Size(0, minHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        );
        break;
      case NeuroButtonType.ghost:
        style = TextButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
          minimumSize: const Size(0, minHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        );
        break;
    }

    Widget button;
    if (type == NeuroButtonType.ghost) {
      button = TextButton(onPressed: isLoading ? null : onPressed, style: style, child: child);
    } else {
      button = ElevatedButton(onPressed: isLoading ? null : onPressed, style: style, child: child);
    }

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
