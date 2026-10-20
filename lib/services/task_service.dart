import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_db.dart';
import 'auth_service.dart';

class TaskService {
  static const String _tasksCacheKey = 'cached_user_tasks';

  /// Carga las tareas desde la caché local (instantáneo).
  static Future<List<Map<String, dynamic>>> getCachedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJson = prefs.getString(_tasksCacheKey);
      if (tasksJson == null) return [];

      final List<dynamic> decoded = jsonDecode(tasksJson);
      return decoded.map((task) {
        return {
          'id': task['id'].toString(),
          'title': task['title'],
          'dueDate': DateTime.parse(task['dueDate']),
          'completed': task['completed'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('Error loading cached tasks: $e');
      return [];
    }
  }

  static Future<void> _saveToCache(List<Map<String, dynamic>> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(tasks.map((task) {
        return {
          'id': task['id'],
          'title': task['title'],
          'dueDate': (task['dueDate'] as DateTime).toIso8601String(),
          'completed': task['completed'],
        };
      }).toList());
      await prefs.setString(_tasksCacheKey, encoded);
    } catch (e) {
      print('Error saving tasks to cache: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadUserTasks() async {
    final authUser = AuthService.current;
    if (authUser == null) return [];

    final db = await LocalDb.instance.database;
    final rows = await db.query(
      'user_tasks',
      where: 'user_id = ?',
      whereArgs: [authUser.id],
      orderBy: 'created_at DESC',
    );

    final List<Map<String, dynamic>> tasks = rows.map((task) {
      return {
        'id': task['id'].toString(),
        'title': task['title'] as String,
        'dueDate': DateTime.parse(task['due_date'] as String),
        'completed': (task['completed'] as int? ?? 0) == 1,
      };
    }).toList();

    await _saveToCache(tasks);
    return tasks;
  }

  static Future<void> addTask(String title, DateTime dueDate) async {
    final authUser = AuthService.current;
    if (authUser == null) return;

    final db = await LocalDb.instance.database;
    await db.insert('user_tasks', {
      'user_id': authUser.id,
      'title': title,
      'due_date': dueDate.toIso8601String(),
      'completed': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deleteTask(String taskId) async {
    final db = await LocalDb.instance.database;
    await db.delete('user_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  static Future<void> toggleTaskCompletion(
      String taskId, bool isCompleted) async {
    final db = await LocalDb.instance.database;
    await db.update(
      'user_tasks',
      {'completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}
