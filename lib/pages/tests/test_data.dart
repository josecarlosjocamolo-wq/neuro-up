import 'package:flutter/material.dart';
import 'test_model.dart';

class TestData {
  static List<MentalTest> getTests() {
    return [
      MentalTest(
        id: 'attention',
        title: 'Test de Atención',
        subtitle: 'Evalúa tu capacidad de concentración',
        description: 'Análisis detallado de tu atención sostenida y selectiva. Incluye ejercicios de discriminación visual y operaciones de complejidad variable adaptadas para neurodiversidad.',
        buttonText: 'Iniciar Evaluación de Atención',
        colorValue: Colors.blue,
      ),
      MentalTest(
        id: 'memory',
        title: 'Test de Memoria',
        subtitle: 'Mide tu capacidad de retención',
        description: 'Evaluación multinivel de memoria operativa y secuencial. Utiliza estímulos visuales y simbólicos para medir la capacidad de almacenamiento y recuperación de información.',
        buttonText: 'Iniciar Evaluación de Memoria',
        colorValue: Colors.green,
      ),
      MentalTest(
        id: 'speed',
        title: 'Test de Velocidad',
        subtitle: 'Analiza tu rapidez mental',
        description: 'Prueba de tiempo de reacción y velocidad de procesamiento cognitivo. Mide la agilidad mental ante diferentes estímulos controlados.',
        buttonText: 'Iniciar Evaluación de Velocidad',
        colorValue: Colors.orange,
      ),
      MentalTest(
        id: 'emotion',
        title: 'Test Emocional',
        subtitle: 'Explora tu inteligencia emocional',
        description: 'Cuestionario de autopercepción emocional diseñado para identificar perfiles afectivos y proporcionar recomendaciones personalizadas para la autorregulación.',
        buttonText: 'Iniciar Perfil Emocional',
        colorValue: Colors.purple,
      ),
    ];
  }

  static MentalTest? getTestById(String id) {
    try {
      return getTests().firstWhere((test) => test.id == id);
    } catch (e) {
      return null;
    }
  }
}