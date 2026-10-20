import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'data/local_db.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'pages/tests/results_repository.dart';
import 'theme/theme_notifier.dart';
import 'theme/app_prefs.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    print("Error al inicializar Firebase: $e");
  }

  // Inicializar base de datos local (SQLite) y sesión guardada
  await LocalDb.ensureInitialized();
  await AuthService.init();

  // Cargar preferencias de accesibilidad (tema y Modo Calma)
  await AppPrefs.load();

  // Inicializar Repositorio de Resultados
  await ResultsRepository.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'Neuro Up',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'),
            Locale('en', 'US'),
          ],
          locale: const Locale('es', 'ES'),
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        );
      },
    );
  }
}
