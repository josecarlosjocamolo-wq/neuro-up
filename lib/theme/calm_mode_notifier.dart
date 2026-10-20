import 'package:flutter/material.dart';

/// Notificador global para el "Modo Calma" (Calm Mode)
/// Cuando es true, se desactivan las animaciones innecesarias, brillos y excesos visuales.
final ValueNotifier<bool> calmModeNotifier = ValueNotifier(false);
