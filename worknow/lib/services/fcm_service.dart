import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  static FCMService get instance => _instance;

  // Global navigator key for navigation from background
  static GlobalKey<NavigatorState>? navigatorKey;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize FCM
  Future<void> initNotifications() async {
    // Request permission
    await requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    await updateFcmToken();

    // Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _saveFcmToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if the app was opened from a terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // Request notification permissions
  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional permission');
    } else {
      print('❌ User declined notification permission');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  // Update FCM token in Firestore
  Future<void> updateFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFcmToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'notificationToken': token});

      print('✅ FCM Token saved: $token');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // Delete FCM token
  Future<void> deleteFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'notificationToken': FieldValue.delete()});

      await _firebaseMessaging.deleteToken();
      print('✅ FCM Token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Foreground message received: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📬 Message opened app: ${message.notification?.title}');
    
    // Navigate to job details if jobId is present
    final jobId = message.data['jobId'] as String?;
    if (jobId != null && navigatorKey?.currentContext != null) {
      _navigateToJobDetails(jobId);
    }
  }

  // Handle notification tap
  void _handleNotificationTap(String? payload) {
    print('👆 Notification tapped: $payload');
    
    if (payload != null && payload.isNotEmpty) {
      // Try to extract jobId from payload
      try {
        // Payload format: "jobId:xxx" or just the jobId
        final jobId = payload.contains(':') 
            ? payload.split(':').last 
            : payload;
        
        if (jobId.isNotEmpty && navigatorKey?.currentContext != null) {
          _navigateToJobDetails(jobId);
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'worknow_channel',
      'WorkNow Notifications',
      channelDescription: 'Notifications for job updates and messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Navigate to job details screen
  void _navigateToJobDetails(String jobId) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    // Use delayed navigation to ensure the app is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      if (navigatorKey?.currentContext != null) {
        // Navigate using named route with arguments
        Navigator.of(navigatorKey!.currentContext!).pushNamed(
          '/job-details',
          arguments: {'jobId': jobId},
        );
      }
    });
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.notification?.title}');
}

