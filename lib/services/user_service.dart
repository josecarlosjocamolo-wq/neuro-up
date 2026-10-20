import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/local_db.dart';
import '../models/user_model.dart' as models;
import 'auth_service.dart';

class UserService {
  /// Obtener el perfil del usuario actual desde SQLite.
  static Future<models.User?> getCurrentUser() async {
    try {
      final authUser = AuthService.current;
      if (authUser == null) return null;

      final db = await LocalDb.instance.database;
      final rows = await db.query(
        'profiles',
        where: 'id = ?',
        whereArgs: [authUser.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        // Perfil aún no creado: devolver uno mínimo.
        return models.User(
          id: authUser.id,
          email: authUser.email,
          name: authUser.name ?? '',
        );
      }

      final r = rows.first;
      return models.User(
        id: r['id'] as String,
        email: (r['email'] ?? authUser.email) as String,
        name: (r['full_name'] ?? r['name'] ?? '') as String,
        matricula: r['matricula'] as String?,
        sexo: r['sexo'] as String?,
        career: r['career'] as String?,
        semestre: r['semestre'] as int?,
        fechaNacimiento: r['fecha_nacimiento'] as String?,
        profileImage: r['profile_image'] as String?,
        dailyReminders: (r['daily_reminders'] ?? 1) == 1,
        shareProgress: (r['share_progress'] ?? 1) == 1,
        achievementNotifications: (r['achievement_notifications'] ?? 1) == 1,
      );
    } catch (e) {
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  /// Actualizar los datos del perfil en SQLite.
  static Future<bool> updateProfile(models.User user) async {
    try {
      final authUser = AuthService.current;
      if (authUser == null) return false;

      final db = await LocalDb.instance.database;
      final data = {
        'email': user.email,
        'full_name': user.name,
        'name': user.name,
        'matricula': user.matricula,
        'sexo': user.sexo,
        'career': user.career,
        'semestre': user.semestre,
        'fecha_nacimiento': user.fechaNacimiento,
        'profile_image': user.profileImage,
        'daily_reminders': user.dailyReminders ? 1 : 0,
        'share_progress': user.shareProgress ? 1 : 0,
        'achievement_notifications': user.achievementNotifications ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final updated = await db.update(
        'profiles',
        data,
        where: 'id = ?',
        whereArgs: [authUser.id],
      );

      if (updated == 0) {
        await db.insert('profiles', {'id': authUser.id, ...data});
      }
      return true;
    } catch (e) {
      print('Error al actualizar perfil: $e');
      return false;
    }
  }

  /// Guarda la imagen de perfil en el almacenamiento local del dispositivo
  /// y devuelve la ruta del archivo.
  static Future<String?> uploadAvatar(String filePath) async {
    try {
      final source = File(filePath);
      if (!await source.exists()) return null;

      final dir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory(p.join(dir.path, 'avatars'));
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      final ext = p.extension(filePath);
      final fileName =
          'avatar-${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(avatarsDir.path, fileName);

      await source.copy(destPath);
      return destPath;
    } catch (e) {
      print('Error al guardar avatar: $e');
      return null;
    }
  }
}
