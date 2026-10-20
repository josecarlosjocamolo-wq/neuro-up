import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_db.dart';

/// Usuario autenticado en el dispositivo.
class AuthUser {
  final String id;
  final String email;
  final String? name;
  const AuthUser({required this.id, required this.email, this.name});
}

/// Error de autenticación con mensaje listo para mostrar al usuario.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Autenticación 100% local, sin servidores.
///
/// - Email/contraseña: las cuentas y el hash se guardan en SQLite.
/// - Google: usa `google_sign_in` para obtener el perfil y crea/recupera
///   la cuenta local correspondiente.
class AuthService {
  static const _kSessionKey = 'current_user_id';

  static AuthUser? _current;
  static AuthUser? get current => _current;
  static bool get isLoggedIn => _current != null;

  /// Restaura la sesión guardada (llamar al arrancar la app).
  static Future<void> init() async {
    await LocalDb.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kSessionKey);
    if (id == null) return;

    final db = await LocalDb.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      await prefs.remove(_kSessionKey);
      return;
    }
    final row = rows.first;
    final prof = await db.query('profiles', where: 'id = ?', whereArgs: [id], limit: 1);
    _current = AuthUser(
      id: id,
      email: row['email'] as String? ?? '',
      name: prof.isNotEmpty
          ? (prof.first['full_name'] ?? prof.first['name']) as String?
          : null,
    );
  }

  static String _hash(String email, String password) {
    final raw = '${email.trim().toLowerCase()}::neuro_up::${password.trim()}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1 << 32)}';

  static Future<void> _persistSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionKey, id);
  }

  static Future<AuthUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (name.trim().length < 2) {
      throw AuthException('El nombre debe tener al menos 2 caracteres.');
    }
    if (password.length < 6) {
      throw AuthException('La contraseña debe tener al menos 6 caracteres.');
    }

    final db = await LocalDb.instance.database;
    final exists = await db.query('users',
        where: 'email = ?', whereArgs: [cleanEmail], limit: 1);
    if (exists.isNotEmpty) {
      throw AuthException('Ya existe una cuenta con ese correo.');
    }

    final id = _newId();
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': id,
      'email': cleanEmail,
      'password_hash': _hash(cleanEmail, password),
      'provider': 'email',
      'created_at': now,
    });
    await db.insert('profiles', {
      'id': id,
      'email': cleanEmail,
      'full_name': name.trim(),
      'name': name.trim(),
      'daily_reminders': 1,
      'share_progress': 1,
      'achievement_notifications': 1,
      'updated_at': now,
    });

    _current = AuthUser(id: id, email: cleanEmail, name: name.trim());
    await _persistSession(id);
    return _current!;
  }

  static Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final db = await LocalDb.instance.database;
    final rows = await db.query('users',
        where: 'email = ?', whereArgs: [cleanEmail], limit: 1);
    if (rows.isEmpty) {
      throw AuthException('No existe una cuenta con ese correo.');
    }

    final row = rows.first;
    if (row['password_hash'] == null) {
      throw AuthException('Esta cuenta se creó con Google. Inicia sesión con Google.');
    }
    if (row['password_hash'] != _hash(cleanEmail, password)) {
      throw AuthException('Contraseña incorrecta.');
    }

    final id = row['id'] as String;
    final prof = await db.query('profiles', where: 'id = ?', whereArgs: [id], limit: 1);
    _current = AuthUser(
      id: id,
      email: cleanEmail,
      name: prof.isNotEmpty
          ? (prof.first['full_name'] ?? prof.first['name']) as String?
          : null,
    );
    await _persistSession(id);
    return _current!;
  }

  /// Inicia sesión con Google. Devuelve `null` si el usuario cancela.
  static Future<AuthUser?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);

    GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } catch (e) {
      throw AuthException(
        'No se pudo iniciar con Google. Revisa que Google Sign-In esté '
        'configurado para esta app. ($e)',
      );
    }
    if (account == null) return null;

    final email = account.email.trim().toLowerCase();
    final name = account.displayName ?? email.split('@').first;
    final db = await LocalDb.instance.database;

    var rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    String id;
    if (rows.isEmpty) {
      id = _newId();
      await db.insert('users', {
        'id': id,
        'email': email,
        'password_hash': null,
        'provider': 'google',
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      id = rows.first['id'] as String;
    }

    final prof = await db.query('profiles', where: 'id = ?', whereArgs: [id], limit: 1);
    if (prof.isEmpty) {
      await db.insert('profiles', {
        'id': id,
        'email': email,
        'full_name': name,
        'name': name,
        'profile_image': account.photoUrl,
        'daily_reminders': 1,
        'share_progress': 1,
        'achievement_notifications': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    _current = AuthUser(id: id, email: email, name: name);
    await _persistSession(id);
    return _current;
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Google no disponible en esta plataforma: se ignora.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionKey);
    _current = null;
  }
}
