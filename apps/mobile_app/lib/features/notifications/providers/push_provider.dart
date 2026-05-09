import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Can add background processing logic here
}

final pushProvider = Provider<PushService>((ref) {
  return PushService(ref);
});

// Stream for realtime unread notifications count
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return Stream.value(0);

  // Initial count fetch + realtime updates
  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .eq('is_read', false)
      .map((events) => events.length);
});

// Stream for realtime notifications list
final notificationsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return Stream.value([]);

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);
});

class PushService {
  final ProviderRef _ref;
  final _fcm = FirebaseMessaging.instance;
  final _localNotifs = FlutterLocalNotificationsPlugin();

  PushService(this._ref);

  Future<void> init() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications for foreground display
      const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettingsIOS = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: initSettingsAndroid,
        iOS: initSettingsIOS,
      );
      
      await _localNotifs.initialize(initSettings);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // Get FCM Token and save to Supabase
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }

      // Listen to token refreshes
      _fcm.onTokenRefresh.listen(_saveTokenToSupabase);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'isufst_gso_channel',
      'Important Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifs.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body,
      details,
    );
  }

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final platform = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web';

      await supabase.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving push token: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}
