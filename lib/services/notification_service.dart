import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'neuro_up_v3', // Cambiado ID para que se aplique el nuevo sonido
    'Notificaciones Neuro Up',
    channelDescription: 'Canal para recordatorios y frases motivadoras',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    sound: RawResourceAndroidNotificationSound('neuro_sound'),
    playSound: true,
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  /// Muestra una notificación persistente (en ejecución) en la barra de notificaciones
  static Future<void> showOngoingNotification(int id, String title, String body) async {
    if (kIsWeb) return;
    const AndroidNotificationDetails ongoingDetails = AndroidNotificationDetails(
      'neuro_up_v3',
      'Notificaciones Neuro Up',
      channelDescription: 'Canal para notificaciones en curso',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('neuro_sound'),
      playSound: true,
    );
    const NotificationDetails notifDetails = NotificationDetails(android: ongoingDetails);
    await _localNotificationsPlugin.show(id, title, body, notifDetails);
  }

  /// Cancela una notificación por su ID
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _localNotificationsPlugin.cancel(id);
  }
  /// Inicializa los servicios de notificación
  static Future<void> initialize() async {
    if (kIsWeb) return;

    // Inicializar zonas horarias
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      print('Error al obtener la zona horaria: $e');
    }

    // 1. Solicitar permisos de Firebase
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Inicializar plugin de notificaciones locales
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: initAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(initSettings);

    // 3. Solicitar permiso de alarmas exactas (Android 13+)
    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Intentar solicitar permiso de alarmas exactas y notificaciones (Android 13+)
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
      
      // Crear canal de Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'neuro_up_v3',
        'Notificaciones Neuro Up',
        description: 'Canal para recordatorios y frases motivadoras',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('neuro_sound'),
        playSound: true,
      );

      await androidPlugin.createNotificationChannel(channel);
    }

    // 4. Manejar mensajes en primer plano (Firebase Push)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showImmediateNotification(
          notification.title ?? 'Neuro Up',
          notification.body ?? '',
        );
      }
    });

    // 5. Programar frases motivadoras diarias
    scheduleDailyPhrases();
  }

  /// Muestra una notificación inmediata (para el temporizador Pomodoro, etc.)
  static Future<void> showImmediateNotification(
      String title, String body) async {
    if (kIsWeb) return;
    await _localNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      _notificationDetails,
    );
  }

  /// Determina el modo de programación de Android según los permisos
  static Future<AndroidScheduleMode> _getScheduleMode() async {
    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final bool? canScheduleExact = await androidPlugin.canScheduleExactNotifications();
      if (canScheduleExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Programa una notificación a una fecha y hora exactas
  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledDate) async {
    if (kIsWeb) return;
    
    final scheduleMode = await _getScheduleMode();
    
    try {
      await _localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        _notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print("Error al programar notificación: $e");
      // Reintento con inexact si falla el exact por cualquier razón
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        await _localNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Programa las tres frases motivadoras diarias
  static void scheduleDailyPhrases() {
    _scheduleDaily(
        100, '☀️ ¡Buenos días!', '¡Hoy es una nueva oportunidad para brillar!', 8, 0);
    _scheduleDaily(
        101, '🌤️ Energía de tarde', '¡Vas por la mitad del día, lo estás haciendo genial!', 14, 0);
    _scheduleDaily(
        102, '🌙 Paz nocturna', 'Es hora de descansar. Agradece por algo bueno de hoy.', 21, 0);
  }

  /// Programa una notificación que se repite diariamente a la misma hora
  static Future<void> _scheduleDaily(
      int id, String title, String body, int hour, int minute) async {
    if (kIsWeb) return;
    
    final scheduleMode = await _getScheduleMode();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print("Error al programar notificación diaria: $e");
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        await _localNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }
}
