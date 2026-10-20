import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../registro/registro_page.dart';
import '../login/login_page.dart';
import '../../widgets/smooth_page_route.dart';

class BienvenidaPage extends StatefulWidget {
  const BienvenidaPage({super.key});

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  VideoPlayerController? _logoVideoController;
  bool _isLogoVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      // Video del Logo — solo en nativo
      _logoVideoController = VideoPlayerController.asset('assets/videos/logo.mp4')
        ..initialize().then((_) {
          setState(() => _isLogoVideoInitialized = true);
          _logoVideoController!.play();
          _logoVideoController!.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _logoVideoController?.dispose();
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
            // Logo Grande Superior (Idéntico en tamaño, posición y altura al Splash Screen)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: kIsWeb
                    ? Image.asset(
                        'assets/gifs/logo.gif',
                        fit: BoxFit.contain,
                      )
                    : (_isLogoVideoInitialized
                        ? FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _logoVideoController!.value.size.width,
                              height: _logoVideoController!.value.size.height,
                              child: VideoPlayer(_logoVideoController!),
                            ),
                          )
                        : const SizedBox.shrink()),
              ),
            ),
            const SizedBox(height: 40),
            // Botones Inferiores Premium (Cápsulas)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildPremiumButton(
                    text: 'CREAR CUENTA NUEVA',
                    icon: Icons.person_add_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const RegistroPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumButton(
                    text: 'INICIAR SESIÓN',
                    icon: Icons.login_rounded,
                    isSecondary: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const LoginPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumButton({
    required String text,
    required IconData icon,
    bool isSecondary = false,
    required VoidCallback onPressed,
  }) {
    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: isSecondary ? const Color(0xFF1B2A47) : Colors.white,
    );

    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: isSecondary
            ? null
            : const LinearGradient(
                colors: [Color(0xFF2D8CFF), Color(0xFF8A2BEF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isSecondary ? Colors.white : null,
        boxShadow: [
          BoxShadow(
            color: isSecondary
                ? Colors.black.withOpacity(0.06)
                : const Color(0xFF2D8CFF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(text, style: textStyle),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSecondary
                        ? const Color(0xFFF1F5F9)
                        : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSecondary ? const Color(0xFF1B2A47) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
