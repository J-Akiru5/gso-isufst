import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final markAllRead = ref.watch(markAllReadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: unreadCount == 0
                ? null
                : () async {
                    await markAllRead();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All notifications marked as read')),
                      );
                    }
                  },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) return const _EmptyNotifications();
          final grouped = _groupNotificationsByDate(notifications);

          return ListView(
            children: [
              if (grouped.today.isNotEmpty)
                _NotificationSection(title: 'Today', items: grouped.today),
              if (grouped.yesterday.isNotEmpty)
                _NotificationSection(title: 'Yesterday', items: grouped.yesterday),
              if (grouped.earlier.isNotEmpty)
                _NotificationSection(title: 'Earlier', items: grouped.earlier),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load notifications: $error')),
      ),
    );
  }
}

class _NotificationSection extends ConsumerWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const _NotificationSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markAsRead = ref.watch(markAsReadProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 0.4,
            ),
          ),
        ),
        ...items.map((item) {
          final id = item['id']?.toString() ?? '';
          final isRead = item['is_read'] == true;
          return Dismissible(
            key: ValueKey('notif-$id'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              if (!isRead) return true;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification is already marked as read')),
              );
              return false;
            },
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.done, color: Colors.white),
            ),
            onDismissed: (_) async {
              if (id.isEmpty) return;
              await markAsRead(id);
            },
            child: _NotificationTile(
              notification: item,
              onTap: () async {
                if (!isRead && id.isNotEmpty) {
                  await markAsRead(id);
                }
                if (context.mounted) _openNotificationLink(context, item);
              },
            ),
          );
        }),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['is_read'] == true;
    final title = notification['title']?.toString() ?? 'Notification';
    final body = notification['body']?.toString() ?? '';
    final createdAtText = notification['created_at']?.toString();
    final createdAt =
        createdAtText == null ? null : DateTime.tryParse(createdAtText)?.toLocal();
    final type = notification['type']?.toString() ?? 'system';
    final icon = _iconForType(type);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          if (!isRead)
            const Positioned(
              right: -1,
              top: -1,
              child: CircleAvatar(radius: 4, backgroundColor: Colors.blue),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Text(
        createdAt == null ? 'N/A' : timeago.format(createdAt),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

_GroupedNotifications _groupNotificationsByDate(List<Map<String, dynamic>> items) {
  final today = <Map<String, dynamic>>[];
  final yesterday = <Map<String, dynamic>>[];
  final earlier = <Map<String, dynamic>>[];
  final nowDate = DateUtils.dateOnly(DateTime.now());
  final yesterdayDate = nowDate.subtract(const Duration(days: 1));

  for (final item in items) {
    final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
    if (createdAt == null) {
      earlier.add(item);
      continue;
    }
    final date = DateUtils.dateOnly(createdAt.toLocal());
    if (date == nowDate) {
      today.add(item);
    } else if (date == yesterdayDate) {
      yesterday.add(item);
    } else {
      earlier.add(item);
    }
  }

  return _GroupedNotifications(today: today, yesterday: yesterday, earlier: earlier);
}

void _openNotificationLink(BuildContext context, Map<String, dynamic> item) {
  final actionUrl = item['action_url']?.toString();
  if (actionUrl != null && actionUrl.isNotEmpty) {
    context.push(actionUrl);
    return;
  }

  final referenceType = item['reference_type']?.toString();
  final referenceId = item['reference_id']?.toString();
  if (referenceId != null && referenceId.isNotEmpty) {
    switch (referenceType) {
      case 'maintenance_request':
        context.push('/maintenance/$referenceId');
        return;
      case 'equipment_loan':
        context.push('/borrowing/$referenceId');
        return;
      case 'inventory_item':
        context.push('/inventory/$referenceId');
        return;
      case 'profile':
        context.push('/profile');
        return;
    }
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'maintenance':
      return Icons.handyman_outlined;
    case 'loan':
      return Icons.assignment_outlined;
    case 'inventory':
      return Icons.inventory_2_outlined;
    case 'approval':
      return Icons.verified_outlined;
    default:
      return Icons.notifications_none_outlined;
  }
}

class _GroupedNotifications {
  final List<Map<String, dynamic>> today;
  final List<Map<String, dynamic>> yesterday;
  final List<Map<String, dynamic>> earlier;

  const _GroupedNotifications({
    required this.today,
    required this.yesterday,
    required this.earlier,
  });
}
