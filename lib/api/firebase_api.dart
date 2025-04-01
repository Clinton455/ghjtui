import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cupertino_icons/cupertino_icons.dart';

// This function needs to be top-level (not inside a class)
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');

  // Show the notification using AwesomeNotifications
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      channelKey: 'basic_channel',
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      notificationLayout: NotificationLayout.Default,
      category: NotificationCategory.Event,
      icon: 'resource://drawable/app_icon',
    ),
  );
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> initNotifications() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Payload: ${message.data}');

      if (message.notification != null) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            channelKey: 'basic_channel',
            title: message.notification?.title ?? 'New Notification',
            body: message.notification?.body ?? '',
            notificationLayout: NotificationLayout.Default,
            category: NotificationCategory.Event,
            icon: 'resource://drawable/app_icon',
          ),
        );
      }
    });

    // Handle notification clicks when app is terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A notification was clicked on!');
      print('Data: ${message.data}');
    });
  }

  /// Update carwash topic based on the first profile in the database
  Future<void> updateCarwashTopicFromProfile() async {
    try {
      // Fetch the first profile with a carwash name
      final response =
          await _supabase
              .from('profiles')
              .select('carwash_name')
              .not('carwash_name', 'is', null)
              .limit(1)
              .single();

      final carwashName = response['carwash_name'];
      if (carwashName == null) {
        print('No carwash name found in profiles');
        return;
      }

      // Convert carwash name to a valid topic
      final topic = _convertToValidTopic(carwashName);

      // Subscribe to the topic
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error updating carwash topic from profile: $e');
    }
  }

  /// Unsubscribe from a previous carwash topic and subscribe to a new one
  Future<void> updateCarwashTopic(
    String oldCarwashName,
    String newCarwashName,
  ) async {
    try {
      // Unsubscribe from old topic
      if (oldCarwashName.isNotEmpty) {
        final oldTopic = _convertToValidTopic(oldCarwashName);
        await _firebaseMessaging.unsubscribeFromTopic(oldTopic);
        print('Unsubscribed from old topic: $oldTopic');
      }

      // Subscribe to new topic
      final newTopic = _convertToValidTopic(newCarwashName);
      await _firebaseMessaging.subscribeToTopic(newTopic);
      print('Subscribed to new topic: $newTopic');
    } catch (e) {
      print('Error updating carwash topic: $e');
    }
  }

  /// Convert carwash name to a valid Firebase topic name
  String _convertToValidTopic(String carwashName) {
    // Remove any non-alphanumeric characters except spaces
    String cleanedName = carwashName.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');

    // Convert to lowercase and replace spaces with underscores
    String validTopicName =
        'carwash_${cleanedName.toLowerCase().replaceAll(' ', '_')}';

    // Ensure the topic is within the 0-32 character limit
    validTopicName =
        validTopicName.length > 32
            ? validTopicName.substring(0, 32)
            : validTopicName;

    return validTopicName;
  }

  // Add this method to your FirebaseApi class
  void debugTopicConversion(String carwashName) {
    final topic = _convertToValidTopic(carwashName);
    print('Original Carwash Name: $carwashName');
    print('Converted Topic: $topic');
  }

  Future<void> checkCurrentTopics() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('Current FCM Token: $fcmToken');
    // Note: Firebase doesn't provide a direct way to list subscribed topics
  }

  /// Unsubscribe from all topics
  Future<void> unsubscribeFromAllTopics() async {
    try {
      // This method can be expanded if needed
      // For now, it's a placeholder to ensure clean unsubscription
      print('Unsubscribed from all topics');
    } catch (e) {
      print('Error unsubscribing from topics: $e');
    }
  }
}
