import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../login/login_page.dart';
import '../home/home_page.dart';
import '../../services/auth_service.dart';
import '../../widgets/smooth_page_route.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _waveController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    // Controlador para las olas fluidas
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Controlador para los elementos flotantes (burbujas/estrellas)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _floatingController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F3FF), // Azul muy sutil
              Colors.white,      // Blanco centro
              Color(0xFFF3E8FF), // Morado muy sutil abajo
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
          // ───── OLAS INFERIORES ANIMADAS ─────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BottomWavesPainter(_waveController.value),
                );
              },
            ),
          ),

          // ───── BURBUJAS Y ESTRELLAS FLOTANTES ─────
          ..._buildDecorations(),

          // ───── OLA SUPERIOR ANIMADA (Igual a la imagen) ─────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240, // Altura suficiente para la ola
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TopWavePainter(_waveController.value),
                );
              },
            ),
          ),

          // ───── GIF LOGO2 - CONSERVADO (top: 70, 110x110) ─────
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  'assets/gifs/logo2.gif',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ───── CONTENIDO PRINCIPAL ─────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Espacio para la ola superior y el logo
                    const SizedBox(height: 175),

                    // Título
                    const Text(
                      'Registro',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Crea tu cuenta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Organiza tu mente, enfoca tu día.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ───── CAMPOS DE FORMULARIO ─────
                    _buildInputField(
                      controller: _nombreController,
                      label: 'Nombre completo',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu nombre';
                        }
                        if (value.length < 2) {
                          return 'El nombre debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Ingresa un email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      isVisible: _passwordVisible,
                      onToggle: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar contraseña',
                      isVisible: _confirmPasswordVisible,
                      onToggle: () => setState(() =>
                          _confirmPasswordVisible = !_confirmPasswordVisible),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor confirma tu contraseña';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // ───── BOTÓN CREAR CUENTA (GRADIENTE) ─────
                    _buildGradientButton(),

                    const SizedBox(height: 24),

                    // ───── SEPARADOR ─────
                    _buildSeparator(),

                    const SizedBox(height: 20),

                    // ───── BOTÓN GOOGLE ─────
                    _buildGoogleButton(),

                    const SizedBox(height: 32),

                    // ───── ENLACE INFERIOR ─────
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: '¿Ya tienes cuenta? ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                          children: [
                            TextSpan(
                              text: 'Inicia sesión',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6), // Azul vibrante
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    SmoothPageRoute(
                                        page: const LoginPage()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // ───── BOTÓN DE REGRESO (Cuadrado redondeado blanco) ─────
          Positioned(
            top: 25,
            left: 20,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14), // Cuadrado redondeado
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF3B82F6), size: 22),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // ───── LOADING OVERLAY ─────
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  // ──────────────────── DECORACIONES (Burbujas y Estrellas) ────────────────────

  List<Widget> _buildDecorations() {
    return [
      // Burbuja 3D derecha arriba (Morada)
      Positioned(
        top: 140,
        right: 30,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, cos(_floatingController.value * 2 * pi) * 10),
              child: child,
            );
          },
          child: _build3DSphere(
              size: 26,
              color1: const Color(0xFFB57AFF),
              color2: const Color(0xFFE2C4FF)),
        ),
      ),
      // Burbuja 3D izquierda media (Azul)
      Positioned(
        top: 280,
        left: 20,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, sin(_floatingController.value * 2 * pi) * 12),
              child: child,
            );
          },
          child: _build3DSphere(
              size: 20,
              color1: const Color(0xFF5A9CF9),
              color2: const Color(0xFFB9D8FF)),
        ),
      ),
      // Burbuja 3D abajo derecha (Pequeña azul)
      Positioned(
        bottom: 120,
        right: 40,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(sin(_floatingController.value * 2 * pi) * 8,
                  cos(_floatingController.value * 2 * pi) * 8),
              child: child,
            );
          },
          child: _build3DSphere(
              size: 14,
              color1: const Color(0xFF81C3F8),
              color2: const Color(0xFFD6EEFF)),
        ),
      ),
      // Estrella arriba centro-izquierda
      Positioned(
        top: 90,
        left: 110,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Opacity(
              opacity: (sin(_floatingController.value * 2 * pi) * 0.4 + 0.6),
              child: const Icon(Icons.star,
                  color: Color(0xFFE2C4FF), size: 14),
            );
          },
        ),
      ),
      // Estrella derecha
      Positioned(
        top: 300,
        right: 25,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Opacity(
              opacity: (cos(_floatingController.value * 2 * pi) * 0.3 + 0.7),
              child: const Icon(Icons.star,
                  color: Color(0xFFB57AFF), size: 16),
            );
          },
        ),
      ),
      // Estrella abajo izquierda
      Positioned(
        bottom: 80,
        left: 40,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Opacity(
              opacity: (sin(_floatingController.value * pi) * 0.5 + 0.5),
              child: const Icon(Icons.star,
                  color: Color(0xFFB57AFF), size: 12),
            );
          },
        ),
      ),
    ];
  }

  Widget _build3DSphere({
    required double size,
    required Color color1,
    required Color color2,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color2, color1],
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  // ──────────────────── INPUT FIELDS ────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
            color: Color(0xFF334155), fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
              color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: Icon(icon, color: const Color(0xFF60A5FA), size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        style: const TextStyle(
            color: Color(0xFF334155), fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
              color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w400),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20, right: 12),
            child: Icon(Icons.lock_outline_rounded,
                color: Color(0xFF60A5FA), size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF60A5FA),
                size: 22,
              ),
              onPressed: onToggle,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  // ──────────────────── BOTÓN PRINCIPAL GRADIENTE ────────────────────

  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)], // Azul a Morado como en la imagen
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA78BFA).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _registrarse,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '✦',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'CREAR CUENTA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          '✦',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ),
    );
  }

  // ──────────────────── SEPARADOR ────────────────────

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: const Color(0xFFE2E8F0), thickness: 1),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'O regístrate con',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: const Color(0xFFE2E8F0), thickness: 1),
        ),
      ],
    );
  }

  // ──────────────────── BOTÓN GOOGLE ────────────────────

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _signUpWithGoogle,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.google,
                  color: Color(0xFF4285F4),
                  size: 20,
                ),
                SizedBox(width: 14),
                Text(
                  'Continuar con Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────── LÓGICA DE REGISTRO ────────────────────

  Future<void> _registrarse() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await AuthService.signUpWithEmail(
          name: _nombreController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada exitosamente!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            SmoothReplaceRoute(page: const HomePage()),
            (route) => false,
          );
        }
      } on AuthException catch (e) {
        _showErrorSnackBar(e.message);
      } catch (e) {
        _showErrorSnackBar('Error al crear la cuenta: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) return; // Cancelado por el usuario

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          SmoothReplaceRoute(page: const HomePage()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar('Error al registrarse con Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ──────────────────── CUSTOM PAINTERS PARA OLAS ANIMADAS ────────────────────

class _TopWavePainter extends CustomPainter {
  final double progress;

  _TopWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradiente base de la ola superior (Azul -> Morado/Rosa) idéntico a la imagen
    final gradient = const LinearGradient(
      colors: [Color(0xFF6DB3FF), Color(0xFFD2A0FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paintBase = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    // Ola Principal
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(0, size.height * 0.6);

    for (double x = 0; x <= size.width; x++) {
      // Movimiento fluido con múltiples funciones seno/coseno
      double y = size.height * 0.6 +
          sin((x / size.width * 2 * pi) + (progress * 2 * pi)) * 25 +
          cos((x / size.width * pi) + (progress * 4 * pi)) * 15;
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, 0);
    path1.close();

    canvas.drawPath(path1, paintBase);

    // Ola Secundaria Translúcida (aporta profundidad)
    final paintSec = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, 0);
    path2.lineTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x++) {
      double y = size.height * 0.7 +
          sin((x / size.width * 2 * pi) + (progress * 2 * pi) + pi / 2) * 20 +
          cos((x / size.width * 1.5 * pi) + (progress * 3 * pi)) * 10;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, 0);
    path2.close();

    canvas.drawPath(path2, paintSec);

    // Línea Fina Brillante decorativa siguiendo la curva
    final paintLine = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pathLine = Path();
    pathLine.moveTo(0, size.height * 0.65);
    for (double x = 0; x <= size.width; x++) {
      double y = size.height * 0.65 +
          sin((x / size.width * 2 * pi) + (progress * 2 * pi) + pi) * 25;
      if (x == 0) {
        pathLine.moveTo(x, y);
      } else {
        pathLine.lineTo(x, y);
      }
    }
    canvas.drawPath(pathLine, paintLine);
  }

  @override
  bool shouldRepaint(covariant _TopWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BottomWavesPainter extends CustomPainter {
  final double progress;

  _BottomWavesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Ola inferior izquierda (Azul suave)
    final paintLeft = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x8893C5FD), Color(0x1193C5FD)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, size.height - 200, 250, 200))
      ..style = PaintingStyle.fill;

    final pathLeft = Path();
    pathLeft.moveTo(0, size.height);
    pathLeft.lineTo(0, size.height - 100);
    
    // Movimiento orgánico
    double cxLeft = 125 + sin(progress * 2 * pi) * 30;
    double cyLeft = size.height - 150 + cos(progress * 2 * pi) * 20;
    
    pathLeft.quadraticBezierTo(cxLeft, cyLeft, 200, size.height);
    pathLeft.close();
    canvas.drawPath(pathLeft, paintLeft);

    // Ola inferior derecha (Morado suave)
    final paintRight = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x88C4B5FD), Color(0x11C4B5FD)],
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
      ).createShader(
          Rect.fromLTWH(size.width - 300, size.height - 250, 300, 250))
      ..style = PaintingStyle.fill;

    final pathRight = Path();
    pathRight.moveTo(size.width, size.height);
    pathRight.lineTo(size.width, size.height - 180);
    
    double cxRight = size.width - 150 + cos(progress * 2 * pi) * 40;
    double cyRight = size.height - 220 + sin(progress * 2 * pi) * 20;

    pathRight.quadraticBezierTo(cxRight, cyRight, size.width - 250, size.height);
    pathRight.close();
    canvas.drawPath(pathRight, paintRight);
  }

  @override
  bool shouldRepaint(covariant _BottomWavesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
