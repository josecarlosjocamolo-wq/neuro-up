// lib/models/user_model.dart
class User {
  final String id;
  final String email;

  // Datos personales
  final String? name;
  final String? matricula;
  final String? sexo;
  final String? career;
  final int? semestre;
  final String? fechaNacimiento;
  final String? profileImage;
  final String? university;
  final int? age;

  // Preferencias
  final bool dailyReminders;
  final bool shareProgress;
  final bool achievementNotifications;

  // Estadísticas
  final int totalFocusTime;
  final int completedTasks;
  final int testsCompleted;

  User({
    required this.id,
    required this.email,
    this.name,
    this.matricula,
    this.sexo,
    this.career,
    this.semestre,
    this.fechaNacimiento,
    this.profileImage,
    this.university,
    this.age,
    this.dailyReminders = true,
    this.shareProgress = false,
    this.achievementNotifications = true,
    this.totalFocusTime = 0,
    this.completedTasks = 0,
    this.testsCompleted = 0,
  });

  // =============================================================
  //  CREAR DESDE MAP (tabla profiles)
  //  Recibe el map obtenido de la consulta y el id del usuario
  // =============================================================
  factory User.fromMap(Map<String, dynamic>? map, String id) {
    final m = map ?? <String, dynamic>{};
    return User(
      id: id,
      email: m["email"] ?? "",
      name: m["full_name"],
      matricula: m["matricula"],
      sexo: m["sexo"],
      career: m["career"],
      semestre: (m["semestre"] is int)
          ? m["semestre"]
          : (m["semestre"] != null
              ? int.tryParse(m["semestre"].toString())
              : null),
      fechaNacimiento: m["fecha_nacimiento"],
      profileImage: m["profile_image"],
      university: m["university"],
      age: (m["age"] is int)
          ? m["age"]
          : (m["age"] != null ? int.tryParse(m["age"].toString()) : null),
      dailyReminders: m["daily_reminders"] ?? true,
      shareProgress: m["share_progress"] ?? false,
      achievementNotifications: m["achievement_notifications"] ?? true,
      totalFocusTime: m["total_focus_time"] ?? 0,
      completedTasks: m["completed_tasks"] ?? 0,
      testsCompleted: m["tests_completed"] ?? 0,
    );
  }

  // =============================================================
  //  CREAR DESDE SOLO id Y email (sesión de autenticación)
  // =============================================================
  factory User.fromAuth(String id, String? email) {
    return User(
      id: id,
      email: email ?? "",
    );
  }

  // =============================================================
  //  MAP PARA GUARDAR EN LA BASE DE DATOS LOCAL (tabla profiles)
  // =============================================================
  Map<String, dynamic> toMap() {
    return {
      "email": email,
      "full_name": name,
      "matricula": matricula,
      "sexo": sexo,
      "career": career,
      "semestre": semestre,
      "fecha_nacimiento": fechaNacimiento,
      "profile_image": profileImage,
      "university": university,
      "age": age,
      "daily_reminders": dailyReminders,
      "share_progress": shareProgress,
      "achievement_notifications": achievementNotifications,
      "total_focus_time": totalFocusTime,
      "completed_tasks": completedTasks,
      "tests_completed": testsCompleted,
      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  // =============================================================
  //  COPYWITH COMPLETO
  // =============================================================
  User copyWith({
    String? name,
    String? matricula,
    String? sexo,
    String? career,
    int? semestre,
    String? fechaNacimiento,
    String? profileImage,
    String? university,
    int? age,
    bool? dailyReminders,
    bool? shareProgress,
    bool? achievementNotifications,
    int? totalFocusTime,
    int? completedTasks,
    int? testsCompleted,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      matricula: matricula ?? this.matricula,
      sexo: sexo ?? this.sexo,
      career: career ?? this.career,
      semestre: semestre ?? this.semestre,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      profileImage: profileImage ?? this.profileImage,
      university: university ?? this.university,
      age: age ?? this.age,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      shareProgress: shareProgress ?? this.shareProgress,
      achievementNotifications:
          achievementNotifications ?? this.achievementNotifications,
      totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      completedTasks: completedTasks ?? this.completedTasks,
      testsCompleted: testsCompleted ?? this.testsCompleted,
    );
  }
}
