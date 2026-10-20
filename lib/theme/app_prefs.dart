import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calm_mode_notifier.dart';
import 'theme_notifier.dart';

/// Persistencia de las preferencias de accesibilidad y apariencia.
///
/// Para personas neurodivergentes es importante que el entorno sea
/// consistente: si eligen tema oscuro o Modo Calma, debe mantenerse
/// entre sesiones sin tener que reactivarlo cada vez.
class AppPrefs {
  static const _kTheme = 'settings_theme_mode';
  static const _kCalm = 'settings_calm_mode';

  static bool _listenersAttached = false;

  /// Carga las preferencias guardadas y sincroniza los notificadores.
  /// Llamar una sola vez al arrancar la app.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    themeModeNotifier.value =
        prefs.getString(_kTheme) == 'dark' ? ThemeMode.dark : ThemeMode.light;
    calmModeNotifier.value = prefs.getBool(_kCalm) ?? false;

    if (_listenersAttached) return;
    _listenersAttached = true;

    themeModeNotifier.addListener(() async {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _kTheme,
        themeModeNotifier.value == ThemeMode.dark ? 'dark' : 'light',
      );
    });

    calmModeNotifier.addListener(() async {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kCalm, calmModeNotifier.value);
    });
  }

  /// Indica si se deben reducir las animaciones, considerando tanto el
  /// Modo Calma de la app como el ajuste "reducir movimiento" del sistema.
  static bool reduceMotion(BuildContext context) =>
      calmModeNotifier.value || MediaQuery.of(context).disableAnimations;
}
