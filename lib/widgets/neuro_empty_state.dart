import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'neuro_button.dart';
import 'neuro_card.dart';

class NeuroEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final String? imageAsset;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const NeuroEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.imageAsset,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: NeuroCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen de Upi o un icono calmado por defecto
              if (imageAsset != null)
                Image.asset(
                  imageAsset!,
                  height: 120,
                )
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                ),
              ),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NeuroButton.primary(
                      text: actionText!,
                      onPressed: onAction,
                      icon: Icons.add_rounded,
                    ),
                    if (secondaryActionText != null && onSecondaryAction != null) ...[
                      const SizedBox(height: 12),
                      NeuroButton.secondary(
                        text: secondaryActionText!,
                        onPressed: onSecondaryAction,
                        icon: Icons.timer_outlined,
                      ),
                    ]
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
