import 'package:flutter/material.dart';

/// Transición ultra-fluida reutilizable para toda la app.
/// Combina un fade suave + deslizamiento sutil desde abajo.
/// Se usa en lugar de MaterialPageRoute en toda la navegación.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Curva suave de entrada
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Fade (opacidad)
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

            // Slide sutil desde abajo (solo 5% de la pantalla)
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(curved);

            // La pantalla que se va se desvanece y se mueve ligeramente hacia arriba
            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            );
            final secondaryFade = Tween<double>(begin: 1.0, end: 0.92).animate(secondaryCurved);
            final secondarySlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0.0, -0.02),
            ).animate(secondaryCurved);

            return SlideTransition(
              position: secondarySlide,
              child: FadeTransition(
                opacity: secondaryFade,
                child: SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}

/// Transición especial para reemplazos completos de stack (login -> home, logout, etc.)
/// Usa un fade más largo y elegante.
class SmoothReplaceRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothReplaceRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );

            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

            final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(curved);

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}
