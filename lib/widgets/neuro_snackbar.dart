import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NeuroSnackBarType { success, error, info }

class NeuroSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    NeuroSnackBarType type = NeuroSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case NeuroSnackBarType.success:
        bgColor = isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5);
        textColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF064E3B);
        icon = Icons.check_circle_rounded;
        break;
      case NeuroSnackBarType.error:
        bgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
        textColor = isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D);
        icon = Icons.error_rounded;
        break;
      case NeuroSnackBarType.info:
        bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
        icon = Icons.info_outline_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: const Color(0xFF334155), width: 1) : null,
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
