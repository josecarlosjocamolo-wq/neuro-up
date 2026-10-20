import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../pages/home/home_page.dart';
import '../pages/bienvenida/bienvenida_page.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      // Solo en nativo: cargar video splash
      _videoController = VideoPlayerController.asset('assets/videos/logo.mp4')
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _isVideoInitialized = true);
          _videoController!.play();
          _videoController!.setLooping(false);
        }).catchError((_) {
          // Video no disponible: se usa el GIF del logo en su lugar.
          if (mounted) setState(() {});
        });
    }

    // Navegación automática
    Timer(const Duration(milliseconds: 4500), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final isLoggedIn = AuthService.isLoggedIn;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isLoggedIn ? const HomePage() : const BienvenidaPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Logo (Mismo tamaño y posición que bienvenida_page)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: kIsWeb
                    ? Image.asset(
                        'assets/gifs/logo.gif',
                        fit: BoxFit.contain,
                      )
                    : (_isVideoInitialized
                        ? FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          )
                        : Image.asset(
                            'assets/gifs/logo.gif',
                            fit: BoxFit.contain,
                          )),
              ),
            ),
            // Espacio fantasma exacto que ocupan los botones en bienvenida_page
            // (SizedBox 40 + Boton 65 + SizedBox 16 + Boton 65 + SizedBox 30) = 216
            const SizedBox(height: 216),
          ],
        ),
      ),
    );
  }
}
