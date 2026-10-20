import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente para modelos de IA compatibles con la API de OpenAI.
///
/// La clave de API nunca se incluye en el código: el usuario la introduce
/// en la app (se guarda solo en su dispositivo) o se inyecta en tiempo de
/// compilación con `--dart-define=AI_API_KEY=...`.
class AiService {
  static const _kApiKey = 'ai_api_key';
  static const _kBaseUrl = 'ai_base_url';
  static const _kModel = 'ai_model';

  static const String defaultBaseUrl = 'https://api.openai.com/v1';
  static const String defaultModel = 'gpt-4o-mini';

  static String? _cachedKey;

  /// Clave proporcionada en tiempo de compilación (opcional).
  static const String _envKey = String.fromEnvironment('AI_API_KEY');
  static const String _envBaseUrl = String.fromEnvironment('AI_BASE_URL');
  static const String _envModel = String.fromEnvironment('AI_MODEL');

  static Future<String?> _apiKey() async {
    if (_cachedKey != null) return _cachedKey!.isEmpty ? null : _cachedKey;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kApiKey);
    _cachedKey = (stored != null && stored.isNotEmpty)
        ? stored
        : (_envKey.isNotEmpty ? _envKey : '');
    return _cachedKey!.isEmpty ? null : _cachedKey;
  }

  static Future<String> _baseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBaseUrl) ??
        (_envBaseUrl.isNotEmpty ? _envBaseUrl : defaultBaseUrl);
  }

  static Future<String> _model() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kModel) ??
        (_envModel.isNotEmpty ? _envModel : defaultModel);
  }

  static Future<bool> isConfigured() async => (await _apiKey()) != null;

  /// Base URL actualmente en uso (guardada o por defecto).
  static Future<String> currentBaseUrl() => _baseUrl();

  /// Modelo actualmente en uso (guardado o por defecto).
  static Future<String> currentModel() => _model();

  static Future<void> configure({
    required String apiKey,
    String? baseUrl,
    String? model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, apiKey.trim());
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      await prefs.setString(_kBaseUrl, baseUrl.trim());
    }
    if (model != null && model.trim().isNotEmpty) {
      await prefs.setString(_kModel, model.trim());
    }
    _cachedKey = apiKey.trim();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kApiKey);
    await prefs.remove(_kBaseUrl);
    await prefs.remove(_kModel);
    _cachedKey = '';
  }

  /// Envía el historial de conversación y devuelve la respuesta del modelo.
  /// Devuelve `null` si no hay clave configurada o si ocurre un error.
  static Future<String?> complete({
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final key = await _apiKey();
    if (key == null) return null;

    final baseUrl = await _baseUrl();
    final model = await _model();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'model': model,
              'temperature': 0.6,
              'max_tokens': 500,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                ...history,
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode < 200 || res.statusCode >= 300) return null;

      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final content = decoded['choices']?[0]?['message']?['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
