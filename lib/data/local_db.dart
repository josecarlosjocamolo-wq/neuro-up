import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Capa de base de datos local (SQLite).
///
/// Reemplaza por completo a Supabase: toda la información del usuario
/// vive dentro del dispositivo, sin necesidad de internet ni servidores.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  static Database? _db;
  static bool _factoryReady = false;

  /// Prepara la fábrica de SQLite según la plataforma.
  /// Debe llamarse una sola vez antes de usar la base de datos.
  static Future<void> ensureInitialized() async {
    if (_factoryReady) return;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // En escritorio se usa la implementación FFI de SQLite.
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _factoryReady = true;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    await ensureInitialized();
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'neuro_up.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cuentas locales (autenticación)
    await db.execute('''
      CREATE TABLE users (
        id            TEXT PRIMARY KEY,
        email         TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        provider      TEXT NOT NULL DEFAULT 'email',
        created_at    TEXT NOT NULL
      )
    ''');

    // Perfil del usuario
    await db.execute('''
      CREATE TABLE profiles (
        id                        TEXT PRIMARY KEY,
        email                     TEXT,
        full_name                 TEXT,
        name                      TEXT,
        matricula                 TEXT,
        sexo                      TEXT,
        career                    TEXT,
        semestre                  INTEGER,
        fecha_nacimiento          TEXT,
        profile_image             TEXT,
        daily_reminders           INTEGER NOT NULL DEFAULT 1,
        share_progress            INTEGER NOT NULL DEFAULT 1,
        achievement_notifications INTEGER NOT NULL DEFAULT 1,
        updated_at                TEXT
      )
    ''');

    // Tareas
    await db.execute('''
      CREATE TABLE user_tasks (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    TEXT NOT NULL,
        title      TEXT NOT NULL,
        due_date   TEXT NOT NULL,
        completed  INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Estadísticas diarias
    await db.execute('''
      CREATE TABLE user_stats (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id             TEXT NOT NULL,
        stat_date           TEXT NOT NULL,
        focus_time_seconds  INTEGER NOT NULL DEFAULT 0,
        tasks_completed     INTEGER NOT NULL DEFAULT 0,
        tasks_added         INTEGER NOT NULL DEFAULT 0,
        tests_completed     INTEGER NOT NULL DEFAULT 0,
        pomodoros           INTEGER NOT NULL DEFAULT 0,
        UNIQUE(user_id, stat_date)
      )
    ''');

    // Configuración del Pomodoro
    await db.execute('''
      CREATE TABLE user_settings (
        user_id    TEXT PRIMARY KEY,
        study_time INTEGER NOT NULL DEFAULT 25,
        break_time INTEGER NOT NULL DEFAULT 5
      )
    ''');

    // Logros desbloqueados
    await db.execute('''
      CREATE TABLE user_achievements (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id        TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        unlocked_at    TEXT NOT NULL,
        UNIQUE(user_id, achievement_id)
      )
    ''');

    // Mensajes del chat
    await db.execute('''
      CREATE TABLE chat_messages (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id   TEXT NOT NULL,
        text      TEXT NOT NULL,
        is_user   INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Eventos de la agenda
    await db.execute('''
      CREATE TABLE calendar_events (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    TEXT NOT NULL,
        title      TEXT NOT NULL,
        event_date TEXT NOT NULL,
        start_time TEXT,
        event_type TEXT NOT NULL DEFAULT 'study',
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Borra por completo la base de datos (útil en desarrollo).
  Future<void> reset() async {
    final db = await database;
    for (final table in [
      'users',
      'profiles',
      'user_tasks',
      'user_stats',
      'user_settings',
      'user_achievements',
      'chat_messages',
      'calendar_events',
    ]) {
      await db.delete(table);
    }
  }
}
