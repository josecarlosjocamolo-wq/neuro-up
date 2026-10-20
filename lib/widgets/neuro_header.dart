import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NeuroHeader — componente reutilizable con DOS modos:
//   • mode: NeuroHeaderMode.minimal  → cabecera limpia estilo "¡Hola, Nombre!"
//   • mode: NeuroHeaderMode.banner   → bloque con gradiente y mascota (legacy)
// ─────────────────────────────────────────────────────────────────────────────

enum NeuroHeaderMode { minimal, banner }

class NeuroHeader extends StatelessWidget {
  // Modo minimal
  final String? greeting;
  final String? greetingName;
  final String? subtitle;
  final Widget? action;

  // Modo banner (legacy)
  final String? title;
  final String? imageAsset;
  final Widget? trailingWidget;

  // Modo
  final NeuroHeaderMode mode;

  // Constructor principal (minimal, nuevo)
  const NeuroHeader({
    super.key,
    this.greeting,
    this.greetingName,
    this.subtitle,
    this.action,
    this.mode = NeuroHeaderMode.minimal,
    // Banner fields (null en modo minimal)
    this.title,
    this.imageAsset,
    this.trailingWidget,
  });

  // Constructor semántico para el modo banner (retrocompatibilidad)
  const NeuroHeader.banner({
    super.key,
    required String bannerTitle,
    String? bannerSubtitle,
    required String bannerImage,
    Widget? bannerTrailing,
  })  : mode = NeuroHeaderMode.banner,
        title = bannerTitle,
        imageAsset = bannerImage,
        trailingWidget = bannerTrailing,
        greeting = null,
        greetingName = null,
        subtitle = bannerSubtitle,
        action = null;

  @override
  Widget build(BuildContext context) {
    return mode == NeuroHeaderMode.minimal
        ? _buildMinimal(context)
        : _buildBanner(context);
  }

  // ─── Modo Minimal (nuevo, inspirado en la referencia visual) ─────────────
  Widget _buildMinimal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final subtitleColor = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      fontFamily: 'Outfit',
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(text: greeting ?? '¡Hola'),
                      if (greetingName != null) ...[
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: greetingName!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const TextSpan(text: '! 👋'),
                    ],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }

  // ─── Modo Banner (legacy, mantiene compatibilidad con otras pantallas) ───
  Widget _buildBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Stack(
        children: [
          // Círculos decorativos
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                if (imageAsset != null)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.star_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      Text(
                        title ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingWidget != null) trailingWidget!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
