// Genera una base de datos SQLite de demostración con el MISMO esquema que
// lib/data/local_db.dart. Se usa solo para producir capturas de pantalla con
// datos realistas. No forma parte de la app.
//
// Uso:
//   dart run tool/seed_demo.dart [ruta_salida.db]
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final out = args.isNotEmpty ? args.first : 'demo.db';
  final db = sqlite3.open(out);

  db.execute('PRAGMA foreign_keys = ON');
  for (final t in [
    'users', 'profiles', 'user_tasks', 'user_stats', 'user_settings',
    'user_achievements', 'chat_messages', 'calendar_events',
  ]) {
    db.execute('DROP TABLE IF EXISTS $t');
  }

  db.execute('''
    CREATE TABLE users (
      id            TEXT PRIMARY KEY,
      email         TEXT NOT NULL UNIQUE,
      password_hash TEXT,
      provider      TEXT NOT NULL DEFAULT 'email',
      created_at    TEXT NOT NULL
    )''');
  db.execute('''
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
    )''');
  db.execute('''
    CREATE TABLE user_tasks (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    TEXT NOT NULL,
      title      TEXT NOT NULL,
      due_date   TEXT NOT NULL,
      completed  INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )''');
  db.execute('''
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
    )''');
  db.execute('''
    CREATE TABLE user_settings (
      user_id    TEXT PRIMARY KEY,
      study_time INTEGER NOT NULL DEFAULT 25,
      break_time INTEGER NOT NULL DEFAULT 5
    )''');
  db.execute('''
    CREATE TABLE user_achievements (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id        TEXT NOT NULL,
      achievement_id TEXT NOT NULL,
      unlocked_at    TEXT NOT NULL,
      UNIQUE(user_id, achievement_id)
    )''');
  db.execute('''
    CREATE TABLE chat_messages (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id   TEXT NOT NULL,
      text      TEXT NOT NULL,
      is_user   INTEGER NOT NULL,
      timestamp TEXT NOT NULL
    )''');
  db.execute('''
    CREATE TABLE calendar_events (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    TEXT NOT NULL,
      title      TEXT NOT NULL,
      event_date TEXT NOT NULL,
      start_time TEXT,
      event_type TEXT NOT NULL DEFAULT 'study',
      created_at TEXT NOT NULL
    )''');

  final now = DateTime.now();
  String day(int offset) {
    final d = now.add(Duration(days: offset));
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  const uid = 'demo-user-001';
  final nowIso = now.toIso8601String();

  db.execute('''INSERT INTO users VALUES (?,?,?,?,?)''', [
    uid, 'ana@universidad.mx', 'hash_demo', 'email', nowIso,
  ]);
  db.execute('''INSERT INTO profiles
      (id,email,full_name,name,matricula,sexo,career,semestre,fecha_nacimiento,updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?)''', [
    uid, 'ana@universidad.mx', 'Ana López Ríos', 'Ana', 'A01734562', 'Femenino',
    'Ingeniería en Sistemas Computacionales', 5, '2004-03-18', nowIso,
  ]);

  final tasks = [
    ['Revisar parcial de Cálculo Integral', 0, 0],
    ['Entregar reporte de laboratorio de Bases de Datos', 0, 0],
    ['Leer capítulo 4 de Redes de Computadoras', 1, 0],
    ['Terminar el proyecto de Neuro Up', 0, 1],
    ['Preparar presentación de Ingeniería de Software', 2, 0],
  ];
  for (final t in tasks) {
    db.execute(
      'INSERT INTO user_tasks (user_id,title,due_date,completed,created_at) VALUES (?,?,?,?,?)',
      [uid, t[0] as String, day(t[1] as int), t[2] as int, nowIso],
    );
  }

  final stats = [
    [0, 3720, 3, 4, 2, 4],
    [-1, 5400, 5, 5, 1, 6],
    [-2, 1800, 2, 3, 0, 2],
    [-3, 4500, 4, 4, 1, 5],
    [-4, 900, 1, 1, 0, 1],
  ];
  for (final s in stats) {
    db.execute(
      'INSERT INTO user_stats (user_id,stat_date,focus_time_seconds,tasks_completed,tasks_added,tests_completed,pomodoros) VALUES (?,?,?,?,?,?,?)',
      [uid, day(s[0] as int), s[1], s[2], s[3], s[4], s[5]],
    );
  }

  db.execute('INSERT INTO user_settings (user_id,study_time,break_time) VALUES (?,?,?)',
      [uid, 25, 5]);

  final achievements = ['fire_discovery', 'mj_dance', 'moon_landing'];
  for (final a in achievements) {
    db.execute('INSERT INTO user_achievements (user_id,achievement_id,unlocked_at) VALUES (?,?,?)',
        [uid, a, nowIso]);
  }

  final chat = [
    [uid, 'Hola Upi, hoy tengo demasiadas tareas y no sé por dónde empezar.', 1, nowIso],
    [uid, 'Hola Ana 😊. Vamos a dividirlo: elige SOLO una tarea de las que vencen hoy y comprométete a 25 minutos. Te acompaño con el temporizador.', 0, nowIso],
    [uid, 'Perfecto, empiezo con el reporte de laboratorio.', 1, nowIso],
    [uid, 'Buena elección. Cuando termines los 25 minutos, descansa 5 y me avisas para registrarlo.', 0, nowIso],
  ];
  for (final c in chat) {
    db.execute('INSERT INTO chat_messages (user_id,text,is_user,timestamp) VALUES (?,?,?,?)', c);
  }

  final events = [
    ['Examen parcial de Cálculo', 0, '10:00', 'exam'],
    ['Entrega de proyecto de Bases de Datos', 1, '23:59', 'task'],
    ['Sesión de enfoque grupal', 2, '17:00', 'study'],
  ];
  for (final e in events) {
    db.execute(
      'INSERT INTO calendar_events (user_id,title,event_date,start_time,event_type,created_at) VALUES (?,?,?,?,?,?)',
      [uid, e[0] as String, day(e[1] as int), e[2] as String, e[3] as String, nowIso],
    );
  }

  // sqflite compara user_version con la versión pedida en openDatabase.
  // Sin esto la app ejecutaría onCreate y trataría de crear tablas que ya
  // existen, y el arranque fallaría.
  db.execute('PRAGMA user_version = 1');

  db.dispose();
  stdout.writeln('Base de datos creada: $out');
}
