import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NeuroChipType { normal, success, warning, error, info }

class NeuroChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final NeuroChipType type;

  const NeuroChip({
    super.key,
    required this.label,
    this.icon,
    this.type = NeuroChipType.normal,
  });

  Color _getBackgroundColor(bool isDark) {
    if (isDark) {
      switch (type) {
        case NeuroChipType.success: return AppColors.success.withValues(alpha: 0.15);
        case NeuroChipType.warning: return AppColors.warning.withValues(alpha: 0.15);
        case NeuroChipType.error: return AppColors.error.withValues(alpha: 0.15);
        case NeuroChipType.info: return AppColors.cyan.withValues(alpha: 0.15);
        case NeuroChipType.normal: return const Color(0xFF334155); // Slate-700
      }
    } else {
      switch (type) {
        case NeuroChipType.success: return const Color(0xFFD1FAE5);
        case NeuroChipType.warning: return const Color(0xFFFEF3C7);
        case NeuroChipType.error: return const Color(0xFFFEE2E2);
        case NeuroChipType.info: return const Color(0xFFCFFAFE);
        case NeuroChipType.normal: return const Color(0xFFF1F5F9); // Slate-100
      }
    }
  }

  Color _getTextColor(bool isDark) {
    if (isDark) {
      switch (type) {
        case NeuroChipType.success: return AppColors.success;
        case NeuroChipType.warning: return AppColors.warning;
        case NeuroChipType.error: return AppColors.error;
        case NeuroChipType.info: return AppColors.cyan;
        case NeuroChipType.normal: return AppColors.textDarkSecondary;
      }
    } else {
      switch (type) {
        case NeuroChipType.success: return const Color(0xFF059669);
        case NeuroChipType.warning: return const Color(0xFFD97706);
        case NeuroChipType.error: return const Color(0xFFDC2626);
        case NeuroChipType.info: return const Color(0xFF0891B2);
        case NeuroChipType.normal: return AppColors.textSecondary;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = _getBackgroundColor(isDark);
    final Color textColor = _getTextColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
