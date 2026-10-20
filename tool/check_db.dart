// Verifica una base de datos de Neuro Up: versión, usuarios y perfil.
// Uso: dart run tool/check_db.dart ruta.db
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'tool/pulled.db';
  final db = sqlite3.open(path);
  final v = db.select('PRAGMA user_version').first.columnAt(0);
  print('user_version = $v');
  for (final r in db.select('SELECT id, email, provider FROM users')) {
    print('user: ${r['id']} | ${r['email']} | ${r['provider']}');
  }
  for (final r in db.select('SELECT id, full_name, name, career FROM profiles')) {
    print('perfil: ${r['full_name']} | ${r['career']}');
  }
  print('tareas: ${db.select('SELECT COUNT(*) c FROM user_tasks').first['c']}');
  print('stats:  ${db.select('SELECT COUNT(*) c FROM user_stats').first['c']}');
  db.dispose();
}
