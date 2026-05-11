import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return Stream.value(const []);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((rows) => rows.cast<Map<String, dynamic>>());
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).valueOrNull ?? const [];
  return notifications.where((item) => item['is_read'] == false).length;
});

final markAsReadProvider = Provider.autoDispose<Future<void> Function(String)>((ref) {
  return (id) async {
    await Supabase.instance.client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('is_read', false);
  };
});

final markAllReadProvider = Provider.autoDispose<Future<void> Function()>((ref) {
  return () async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    await Supabase.instance.client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id).eq('is_read', false);
  };
});
