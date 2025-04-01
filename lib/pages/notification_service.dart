import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final supabase = Supabase.instance.client;
  bool _subscriptionsSetup = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Initialize the notification plugin
    await AwesomeNotifications().initialize('resource://drawable/app_icon', [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Channel for basic notifications',
        defaultColor: Colors.black,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ]);

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      print("Requesting notification permissions");
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
        ],
      );
    } else {
      print("Notification permissions already granted");
    }

    if (!_subscriptionsSetup) {
      _setupRealtimeSubscriptions();
      _subscriptionsSetup = true;
    }
  }

  void _setupRealtimeSubscriptions() {
    // Subscribe to signals table changes for new signal notifications

    print("Setting up realtime subscriptions for notifications");
    supabase
        .channel('notification_signals')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'signals',
          callback: (payload) {
            print(
              "New signal detected in NotificationService: ${payload.toString()}",
            );
            // Extract information from the payload to create a more informative notification
            final Map<String, dynamic> newRecord =
                payload.newRecord as Map<String, dynamic>;
            final String currencyPair = newRecord['currency_pair'] as String;
            final bool isBuy = newRecord['is_buy'] as bool;
            _showNewSignalNotification(currencyPair, isBuy);
          },
        )
        .subscribe();

    // Subscribe to webinars table changes for new webinar notifications
    supabase
        .channel('notification_webinars')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'webinars',
          callback: (payload) {
            print(
              "New webinar detected in NotificationService: ${payload.toString()}",
            );
            // Extract information from the payload to create a more informative notification
            final Map<String, dynamic> newRecord =
                payload.newRecord as Map<String, dynamic>;
            final String title = newRecord['title'] as String;
            final String dateTimeStr = newRecord['date_time'] as String;
            _showNewWebinarNotification(title, dateTimeStr);
          },
        )
        .subscribe();
  }

  Future<void> _showNewSignalNotification(
    String currencyPair,
    bool isBuy,
  ) async {
    print("'}");

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 100000, // Ensure unique ID
        channelKey: 'basic_channel',
        title: 'Notification',
        body: 'You have a new message',
        notificationLayout: NotificationLayout.Default,

        // Add importance and priority to ensure the notification is shown
        category: NotificationCategory.Event,
      ),
    );
  }

  Future<void> _showNewWebinarNotification(
    String title,
    String dateTimeStr,
  ) async {
    print("Showing new webinar notification for $title at $dateTimeStr");

    // Parse the datetime to a more readable format if possible
    String formattedDate = dateTimeStr;
    try {
      final DateTime dateTime = DateTime.parse(dateTimeStr);
      formattedDate =
          "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      // If parsing fails, just use the original string
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 100000, // Ensure unique ID
        channelKey: 'basic_channel',
        title: 'New Webinar Scheduled',
        body: '$title - $formattedDate',
        notificationLayout: NotificationLayout.Default,

        // Add importance and priority to ensure the notification is shown
        category: NotificationCategory.Event,
      ),
    );
  }

  // Add this to notification_service.dart
  Future<void> testNotification() async {
    print("Sending test notification");
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: 'Test Notification',
        body: 'This is a test notification',
        notificationLayout: NotificationLayout.Default,
      ),
    );
    print("Test notification sent");
  }
}
