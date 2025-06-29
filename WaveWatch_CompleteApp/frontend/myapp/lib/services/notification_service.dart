import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final BehaviorSubject<String?> _selectNotificationSubject =
      BehaviorSubject<String?>();

  Stream<String?> get onNotificationClick => _selectNotificationSubject.stream;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _selectNotificationSubject.add(response.payload);
      },
    );
    
    // Request permissions for iOS
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    
    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    // Feedback channel
    const AndroidNotificationChannel feedbackChannel = AndroidNotificationChannel(
      'feedback_channel',
      'Feedback Notifications',
      description: 'Notifications to request user feedback',
      importance: Importance.high,
    );
    
    // Service channel
    const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
      'network_monitor_channel',
      'Network Monitor Service',
      description: 'This channel is used for network monitoring service notifications.',
      importance: Importance.low,
    );
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(feedbackChannel);
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(serviceChannel);
  }

  Future<void> showFeedbackNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'feedback_channel',
      'Feedback Notifications',
      channelDescription: 'Notifications to request user feedback',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher', // Use the app icon
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    try {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload ?? 'feedback',
      );
      debugPrint('📢 Feedback notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing feedback notification: $e');
      // Don't rethrow - notifications are not critical
    }
  }

  Future<void> showNetworkIssueNotification({
    required String title,
    required String body,
    required Map<String, dynamic> networkData,
  }) async {
    // Convert network data to JSON string for payload
    final payload = 'network_issue:${networkData['carrier']}:${networkData['networkType']}';
    
    await showFeedbackNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  void dispose() {
    _selectNotificationSubject.close();
  }
}
