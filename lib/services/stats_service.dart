import '../data/local_db.dart';
import 'auth_service.dart';

class StatsService {
  static String _today() => DateTime.now().toIso8601String().split('T')[0];

  /// Incrementa atómicamente una columna de las estadísticas del día.
  static Future<void> _increment(String column, int amount) async {
    final user = AuthService.current;
    if (user == null) return;
    try {
      final db = await LocalDb.instance.database;
      final today = _today();
      await db.transaction((txn) async {
        final rows = await txn.query(
          'user_stats',
          where: 'user_id = ? AND stat_date = ?',
          whereArgs: [user.id, today],
          limit: 1,
        );
        if (rows.isEmpty) {
          await txn.insert('user_stats', {
            'user_id': user.id,
            'stat_date': today,
            column: amount,
          });
        } else {
          final current = (rows.first[column] as int?) ?? 0;
          await txn.update(
            'user_stats',
            {column: current + amount},
            where: 'id = ?',
            whereArgs: [rows.first['id']],
          );
        }
      });
    } catch (e) {
      print('Error al registrar estadística ($column): $e');
    }
  }

  /// Registra tiempo de enfoque (Pomodoro).
  static Future<void> recordFocusTime(int seconds) =>
      _increment('focus_time_seconds', seconds);

  /// Registra un pomodoro completado.
  static Future<void> recordPomodoro() => _increment('pomodoros', 1);

  static Future<void> recordTaskCompleted() => _increment('tasks_completed', 1);

  static Future<void> recordTestCompleted() => _increment('tests_completed', 1);

  static Future<void> recordTaskAdded() => _increment('tasks_added', 1);

  /// Resumen rápido de estadísticas (acumulado histórico).
  static Future<Map<String, dynamic>> getQuickStats() async {
    final user = AuthService.current;
    final empty = {
      'focusTime': 0,
      'tasksCompleted': 0,
      'testsCompleted': 0,
      'pomodoros': 0,
      'tasksAdded': 0,
    };
    if (user == null) return empty;

    try {
      final db = await LocalDb.instance.database;
      final result = await db.rawQuery('''
        SELECT
          COALESCE(SUM(focus_time_seconds), 0) AS focus_time,
          COALESCE(SUM(tasks_completed), 0)    AS tasks_completed,
          COALESCE(SUM(tests_completed), 0)    AS tests_completed,
          COALESCE(SUM(pomodoros), 0)          AS pomodoros,
          COALESCE(SUM(tasks_added), 0)        AS tasks_added
        FROM user_stats WHERE user_id = ?
      ''', [user.id]);

      final row = result.first;
      return {
        'focusTime': (row['focus_time'] as num?)?.toInt() ?? 0,
        'tasksCompleted': (row['tasks_completed'] as num?)?.toInt() ?? 0,
        'testsCompleted': (row['tests_completed'] as num?)?.toInt() ?? 0,
        'pomodoros': (row['pomodoros'] as num?)?.toInt() ?? 0,
        'tasksAdded': (row['tasks_added'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return empty;
    }
  }

  /// Calcula la Experiencia (XP), Nivel y Rango del usuario.
  static Future<Map<String, dynamic>> getXPAndLevel() async {
    final stats = await getQuickStats();
    final int focusMinutes = (stats['focusTime'] as int) ~/ 60;
    final int tasks = stats['tasksCompleted'] as int;
    final int tests = stats['testsCompleted'] as int;

    // Fórmula de XP: 1 XP por minuto, 10 por tarea, 15 por test.
    final int totalXP = focusMinutes + (tasks * 10) + (tests * 15);

    // Cada nivel requiere 100 XP.
    final int level = (totalXP ~/ 100) + 1;
    final int currentLevelXP = totalXP % 100;
    const int nextLevelXP = 100;

    String rankName;
    if (level < 5) {
      rankName = 'Mente Novata 🌱';
    } else if (level < 10) {
      rankName = 'Explorador Neuronal 🧭';
    } else if (level < 20) {
      rankName = 'Maestro del Enfoque 🧠';
    } else {
      rankName = 'Gurú Cognitivo 👑';
    }

    return {
      'totalXP': totalXP,
      'level': level,
      'currentLevelXP': currentLevelXP,
      'nextLevelXP': nextLevelXP,
      'rankName': rankName,
    };
  }

  /// Obtiene los datos de actividad de los últimos 7 días (reales).
  static Future<List<double>> getWeeklyActivityStats() async {
    final user = AuthService.current;
    final now = DateTime.now();
    final List<double> weeklyStats = List.filled(7, 0.0);
    if (user == null) return weeklyStats;

    try {
      final db = await LocalDb.instance.database;
      final sevenDaysAgo = now
          .subtract(const Duration(days: 6))
          .toIso8601String()
          .split('T')[0];

      final rows = await db.query(
        'user_stats',
        where: 'user_id = ? AND stat_date >= ?',
        whereArgs: [user.id, sevenDaysAgo],
      );

      final Map<String, double> scoresByDate = {};
      for (final row in rows) {
        final date = row['stat_date'] as String;
        final focus = ((row['focus_time_seconds'] as int?) ?? 0) ~/ 60;
        final tasks = (row['tasks_completed'] as int?) ?? 0;
        final tests = (row['tests_completed'] as int?) ?? 0;
        scoresByDate[date] = (focus + (tasks * 10) + (tests * 15)).toDouble();
      }

      for (int i = 0; i < 7; i++) {
        final date = now
            .subtract(Duration(days: 6 - i))
            .toIso8601String()
            .split('T')[0];
        weeklyStats[i] = scoresByDate[date] ?? 0.0;
      }
      return weeklyStats;
    } catch (e) {
      print('Error al obtener weekly stats: $e');
      return weeklyStats;
    }
  }

  /// Racha actual: días consecutivos con actividad, contando desde hoy
  /// (o desde ayer si hoy aún no hay actividad).
  static Future<int> getStreak() async {
    final user = AuthService.current;
    if (user == null) return 0;

    try {
      final db = await LocalDb.instance.database;
      final rows = await db.query(
        'user_stats',
        columns: ['stat_date', 'focus_time_seconds', 'tasks_completed', 'tests_completed'],
        where: 'user_id = ?',
        whereArgs: [user.id],
      );

      final Set<String> activeDays = {};
      for (final row in rows) {
        final focus = (row['focus_time_seconds'] as int?) ?? 0;
        final tasks = (row['tasks_completed'] as int?) ?? 0;
        final tests = (row['tests_completed'] as int?) ?? 0;
        if (focus > 0 || tasks > 0 || tests > 0) {
          activeDays.add(row['stat_date'] as String);
        }
      }

      final now = DateTime.now();
      var day = DateTime(now.year, now.month, now.day);
      if (!activeDays.contains(_fmt(day))) {
        day = day.subtract(const Duration(days: 1));
      }

      int streak = 0;
      while (activeDays.contains(_fmt(day))) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }
      return streak;
    } catch (e) {
      print('Error al calcular racha: $e');
      return 0;
    }
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
