import '../../../data/local_db.dart';
import '../../../services/ai_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/stats_service.dart';
import '../../../services/task_service.dart';
import 'chat_message_model.dart';

class ChatService {
  /// Obtiene el historial completo del usuario (ordenado cronológicamente).
  Future<List<ChatMessage>> getMessages() async {
    final user = AuthService.current;
    if (user == null) return [];

    final db = await LocalDb.instance.database;
    final rows = await db.query(
      'chat_messages',
      where: 'user_id = ?',
      whereArgs: [user.id],
      orderBy: 'timestamp ASC, id ASC',
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> _save(String text, bool isUser) async {
    final user = AuthService.current;
    if (user == null) return;

    final db = await LocalDb.instance.database;
    await db.insert('chat_messages', {
      'user_id': user.id,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveUserMessage(String text) => _save(text, true);

  Future<void> saveBotMessage(String text) => _save(text, false);

  Future<void> clearHistory() async {
    final user = AuthService.current;
    if (user == null) return;
    final db = await LocalDb.instance.database;
    await db.delete('chat_messages', where: 'user_id = ?', whereArgs: [user.id]);
  }

  /// Genera la respuesta de UPI.
  ///
  /// Si hay una IA configurada, usa el modelo (con contexto real del usuario).
  /// Si no, recurre a un motor de reglas local mejorado.
  Future<String> getBotResponse(String userMessage) async {
    final aiResponse = await _tryAi(userMessage);
    if (aiResponse != null) return aiResponse;
    return _localResponse(userMessage);
  }

  Future<String?> _tryAi(String userMessage) async {
    try {
      if (!await AiService.isConfigured()) return null;

      final stats = await StatsService.getQuickStats();
      final xp = await StatsService.getXPAndLevel();
      final tasks = await TaskService.loadUserTasks();
      final pending = tasks.where((t) => t['completed'] != true).length;
      final name = AuthService.current?.name ?? 'estudiante';

      final focusMin = (stats['focusTime'] as int? ?? 0) ~/ 60;

      final systemPrompt =
          'Eres "UPI", el asistente de bienestar y productividad de la app Neuro Up. '
          'Ayudas a estudiantes a organizar sus tareas, enfocarse (Pomodoro), cuidar su '
          'salud mental y entender sus resultados de tests cognitivos. '
          'Responde SIEMPRE en español, con un tono cálido, breve (máximo 120 palabras) y '
          'práctico. Usa listas o pasos cuando sea útil. Si detectas señales de estrés, '
          'ansiedad o crisis, valida la emoción y sugiere pausas y buscar apoyo humano.\n\n'
          'Contexto del usuario "$name": nivel ${xp['level']}, ${xp['totalXP']} XP, '
          '$focusMin minutos de enfoque, ${stats['tasksCompleted']} tareas completadas, '
          '${stats['testsCompleted']} tests realizados, $pending tareas pendientes.';

      final history = await _recentHistory();

      return await AiService.complete(
        systemPrompt: systemPrompt,
        history: [
          ...history,
          {'role': 'user', 'content': userMessage},
        ],
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, String>>> _recentHistory() async {
    final all = await getMessages();
    final recent = all.length > 10 ? all.sublist(all.length - 10) : all;
    return recent
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();
  }

  /// Motor de respuestas local (sin conexión ni API key).
  String _localResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    // Contención emocional
    if (_containsAny(msg, [
      'frustrado', 'estrés', 'estres', 'difícil', 'dificil', 'no puedo',
      'cansado', 'ansiedad', 'abrumado', 'triste', 'mal', 'solo',
    ])) {
      return 'Entiendo cómo te sientes. 💙 A veces todo se junta.\n\n'
          'Intenta esto:\n'
          '1. Respira profundo 5 veces y aléjate de la pantalla 5 minutos.\n'
          '2. Divide lo que te agobia en pasos muy pequeños.\n'
          '3. Comparte lo que sientes con alguien de confianza o un tutor.\n\n'
          'No estás solo en esto. ¿Quieres que anotemos una tarea pequeña para empezar?';
    }

    if (_containsAny(msg, ['organizar', 'agenda', 'planear', 'planificar'])) {
      return '¡Vamos a ordenar tu día! 📅\n'
          '1. Abre la **Agenda** y revisa lo que sigue.\n'
          '2. Anota en tus **tareas** solo 3 cosas importantes para hoy.\n'
          '3. Asigna un bloque de tiempo a cada una.\n\n'
          'Menos es más: elige 3 y hazlas una por una.';
    }

    if (_containsAny(msg, ['enfocar', 'concentr', 'distraig', 'procrastin'])) {
      return 'Para enfocarte, usa el **Pomodoro** ⏱️.\n'
          'Si te cuesta arrancar, pon solo 10 minutos y silencia el celular. '
          'Lo más difícil es empezar; después el ritmo llega solo. ';
    }

    if (_containsAny(msg, ['resultado', 'tests', 'calificaci', 'puntaje'])) {
      return 'Puedes ver tus resultados en la sección de **Tests → Resultados** 📊. '
          'Ahí verás en qué áreas brillas y cuáles conviene entrenar más.';
    }

    if (_containsAny(msg, ['pomodoro', 'temporizador', 'timer'])) {
      return 'El **Pomodoro** alterna bloques de estudio y descanso. '
          'Empieza con 25/5 y ajusta según tu energía. Cada sesión suma XP. 🍅';
    }

    if (_containsAny(msg, ['hola', 'buenas', 'hey', 'qué tal', 'que tal'])) {
      return '¡Hola! Soy UPI 🤖. Puedo ayudarte con tu agenda, el enfoque, '
          'tus resultados o simplemente escucharte. ¿Qué necesitas?';
    }

    if (_containsAny(msg, ['gracias', 'gracias!', 'genial', 'perfecto'])) {
      return '¡Con gusto! 💙 Estoy aquí cuando me necesites.';
    }

    return 'Te escucho. Puedo ayudarte a organizar tu agenda, enfocarte con el '
        'Pomodoro, revisar tus resultados o manejar el estrés. '
        '¿Qué te gustaría hacer primero?';
  }

  bool _containsAny(String text, List<String> keywords) =>
      keywords.any(text.contains);
}
