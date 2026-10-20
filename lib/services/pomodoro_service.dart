import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../data/local_db.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'stats_service.dart';

/// Singleton que mantiene el estado del temporizador Pomodoro
/// independientemente del ciclo de vida del widget.
class PomodoroService extends ChangeNotifier {
  PomodoroService._();
  static final PomodoroService instance = PomodoroService._();

  // ── Estado ──────────────────────────────────────────
  int studyTime = 25;
  int breakTime = 5;
  int remainingTime = 25 * 60;
  bool isRunning = false;
  bool isStudyTime = true;

  Timer? _timer;

  // ── Helpers ─────────────────────────────────────────
  double get progress {
    final total = (isStudyTime ? studyTime : breakTime) * 60;
    if (total == 0) return 0;
    return 1.0 - (remainingTime / total);
  }

  String get formattedTime {
    final m = remainingTime ~/ 60;
    final s = remainingTime % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Control ──────────────────────────────────────────
  void toggleTimer() {
    if (isRunning) {
      _timer?.cancel();
      isRunning = false;
      NotificationService.cancelNotification(1000);
    } else {
      isRunning = true;
      final title = isStudyTime ? 'Pomodoro - Estudio' : 'Pomodoro - Descanso';
      final body  = isStudyTime ? 'Enfócate en tu estudio' : 'Tiempo de descanso';
      NotificationService.showOngoingNotification(1000, title, body);

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (remainingTime > 0) {
          remainingTime--;
          notifyListeners();
        } else {
          t.cancel();
          _handleCompletion();
        }
      });
    }
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    isRunning = false;
    remainingTime = (isStudyTime ? studyTime : breakTime) * 60;
    NotificationService.cancelNotification(1000);
    notifyListeners();
  }

  void updateSettings(int newStudy, int newBreak) {
    studyTime = newStudy;
    breakTime = newBreak;
    resetTimer();
  }

  Future<void> loadSettings() async {
    try {
      final user = AuthService.current;
      if (user == null) return;
      final db = await LocalDb.instance.database;
      final rows = await db.query(
        'user_settings',
        columns: ['study_time', 'break_time'],
        where: 'user_id = ?',
        whereArgs: [user.id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        studyTime = (rows.first['study_time'] as int?) ?? 25;
        breakTime = (rows.first['break_time'] as int?) ?? 5;
        if (!isRunning) remainingTime = studyTime * 60;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PomodoroService.loadSettings error: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final user = AuthService.current;
      if (user == null) return;
      final db = await LocalDb.instance.database;
      await db.insert(
        'user_settings',
        {
          'user_id': user.id,
          'study_time': studyTime,
          'break_time': breakTime,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('PomodoroService.saveSettings error: $e');
    }
  }

  void _handleCompletion() {
    isRunning = false;
    if (isStudyTime) {
      StatsService.recordFocusTime(studyTime * 60);
      StatsService.recordPomodoro();
      isStudyTime = false;
      remainingTime = breakTime * 60;
      NotificationService.showImmediateNotification(
          '¡Sesión terminada!', 'Buen trabajo. Es hora de un descanso.');
    } else {
      isStudyTime = true;
      remainingTime = studyTime * 60;
      NotificationService.showImmediateNotification(
          '¡Descanso terminado!', '¿Listo para otra sesión?');
    }
    NotificationService.cancelNotification(1000);
    notifyListeners();
  }
}
