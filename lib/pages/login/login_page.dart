import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../registro/registro_page.dart';
import '../home/home_page.dart';
import '../../services/auth_service.dart';
import '../../widgets/smooth_page_route.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // GIF DE OLAS
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: Image.asset('assets/gifs/olas2.gif', fit: BoxFit.cover),
            ),
          ),

          // GIF LOGO
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset('assets/gifs/logo2.gif'),
              ),
            ),
          ),

          // FORMULARIO
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 140),
                    _buildHeader(),
                    const SizedBox(height: 25),
                    _buildFormFields(),
                    const SizedBox(height: 16),
                    _buildRememberAndForgot(),
                    const SizedBox(height: 20),
                    _buildLoginButton(),
                    const SizedBox(height: 16),
                    _buildSeparator(),
                    const SizedBox(height: 12),
                    _buildGoogleButton(),
                    const SizedBox(height: 12),
                    _buildRegisterButton(context),
                  ],
                ),
              ),
            ),
          ),

          // BOTÓN BACK
          Positioned(
            top: 25,
            left: 16,
            child: _backButton(),
          ),

          // LOADING
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF4A90E2)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /* ---------------- WIDGETS DE UI ---------------- */

  Widget _buildHeader() {
    return Column(
      children: const [
        Text(
          'Bienvenido',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text('Inicia sesión en tu cuenta',
            style: TextStyle(fontSize: 15, color: Color(0xFF7F8C8D))),
        SizedBox(height: 2),
        Text(
          'Organiza tu mente, enfoca tu día.',
          style: TextStyle(
              fontSize: 11,
              color: Color(0xFF95A5A6),
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Correo electrónico',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Ingresa tu email';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email no válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _passwordController,
          label: 'Contraseña',
          isVisible: _passwordVisible,
          onToggle: () => setState(() => _passwordVisible = !_passwordVisible),
          validator: (value) =>
              value == null || value.isEmpty ? 'Ingresa tu contraseña' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
        prefixIcon: Icon(icon, color: Color(0xFF4A90E2), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFBDC3C7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFBDC3C7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
        prefixIcon:
            const Icon(Icons.lock_outline, color: Color(0xFF4A90E2), size: 20),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
              color: Color(0xFF4A90E2), size: 20),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFBDC3C7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFBDC3C7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (v) => setState(() => _rememberMe = v!),
          activeColor: Color(0xFF4A90E2),
        ),
        const Text('Recordarme',
            style: TextStyle(fontSize: 13, color: Color(0xFF2C3E50))),
        const Spacer(),
        TextButton(
          onPressed: () => _showForgotPasswordDialog(),
          child: const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(color: Color(0xFF4A90E2), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumButton({
    required String text,
    required IconData icon,
    bool isSecondary = false,
    bool isLoading = false,
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
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSecondary ? const Color(0xFF1B2A47) : Colors.white,
                          ),
                        ),
                      )
                    : Text(text, style: textStyle),
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

  Widget _buildLoginButton() {
    return _buildPremiumButton(
      text: 'INICIAR SESIÓN',
      icon: Icons.login_rounded,
      isLoading: _isLoading,
      onPressed: _login,
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Color(0xFFBDC3C7),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'O inicia sesión con',
            style: TextStyle(
              color: Color(0xFF7F8C8D),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFBDC3C7),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _loginWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF2C3E50),
          side: BorderSide(color: Color(0xFFBDC3C7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.google,
                    color: Color(0xFF4A90E2),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return _buildPremiumButton(
      text: 'CREAR CUENTA NUEVA',
      icon: Icons.person_add_rounded,
      isSecondary: true,
      onPressed: () {
        Navigator.push(
          context,
          SmoothPageRoute(page: const RegistroPage()),
        );
      },
    );
  }

  Widget _backButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4A90E2), size: 18),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
      ),
    );
  }

  /* ------------------- LÓGICA DE AUTENTICACIÓN LOCAL ------------------- */

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        SmoothReplaceRoute(page: const HomePage()),
        (route) => false,
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) return; // Cancelado por el usuario

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        SmoothReplaceRoute(page: const HomePage()),
        (route) => false,
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error al iniciar con Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    TextEditingController emailController = TextEditingController(
        text: _emailController.text.isNotEmpty ? _emailController.text : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: Color(0xFF4A90E2)),
            SizedBox(width: 10),
            Text('Recuperar contraseña', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingresa tu email para restablecer tu contraseña:',
                style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty &&
                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(emailController.text)) {
                await _resetPassword(emailController.text.trim());
                Navigator.pop(context);
              } else {
                _showError('Ingresa un email válido');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
            ),
            child: Text('Enviar', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    // La app funciona sin conexión: no hay servidor de correo.
    // Se informa al usuario de las alternativas disponibles.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Esta app guarda todo en tu dispositivo, por lo que no envía correos. '
          'Si olvidaste tu contraseña, usa "Continuar con Google" o crea una cuenta nueva.',
        ),
        backgroundColor: Color(0xFF4A90E2),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
