import 'package:flutter/material.dart';

class MentalTest {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String buttonText;
  final Color colorValue;

  const MentalTest({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonText,
    required this.colorValue,
  });
}

class TestResultData {
  final String testId;
  final int score;
  final int timeSpent;
  final DateTime date;
  final Map<String, dynamic> details;

  TestResultData({
    required this.testId,
    required this.score,
    required this.timeSpent,
    required this.date,
    this.details = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'score': score,
      'timeSpent': timeSpent,
      'date': date.toIso8601String(),
      'details': details,
    };
  }

  factory TestResultData.fromMap(Map<String, dynamic> map) {
    return TestResultData(
      testId: map['testId'] ?? '',
      score: map['score'] ?? 0,
      timeSpent: map['timeSpent'] ?? 0,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      details: map['details'] is Map ? Map<String, dynamic>.from(map['details']) : {},
    );
  }
}