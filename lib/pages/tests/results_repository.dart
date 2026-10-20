import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_model.dart';

class ResultsRepository {
  static List<TestResultData> _results = [];
  static const String _storageKey = 'test_results_v2';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? resultsJson = prefs.getString(_storageKey);
    if (resultsJson != null) {
      final List<dynamic> decoded = jsonDecode(resultsJson);
      _results = decoded.map((item) => TestResultData.fromMap(item)).toList();
      _results.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  static List<TestResultData> getResults() {
    return List.from(_results);
  }

  static Future<void> addResult(TestResultData result) async {
    _results.add(result);
    _results.sort((a, b) => b.date.compareTo(a.date));
    await _saveToDisk();
  }

  static Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_results.map((r) => r.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> clearResults() async {
    _results.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static List<TestResultData> getResultsByTestId(String testId) {
    return _results.where((result) => result.testId == testId).toList();
  }

  static double getAverageScore() {
    if (_results.isEmpty) return 0.0;
    return _results.map((r) => r.score).reduce((a, b) => a + b) / _results.length;
  }
}