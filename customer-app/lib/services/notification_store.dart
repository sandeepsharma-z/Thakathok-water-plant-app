import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.actionType,
    required this.createdAt,
    required this.isRead,
  });
  final String id;
  final String title;
  final String body;
  final String type;
  final String actionType;
  final DateTime createdAt;
  final bool isRead;
}

class NotificationStore {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<AppNotification>> notifications(String mobile) async {
    if (mobile.length != 10) return const [];
    final rows = await _db
        .from('customer_notifications')
        .select(
            'id,read_at,created_at,notification_campaigns(title,body,notification_type,action_type)')
        .eq('mobile', mobile)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return rows.map((row) {
      final campaign =
          Map<String, dynamic>.from(row['notification_campaigns'] as Map);
      return AppNotification(
        id: '${row['id']}',
        title: '${campaign['title'] ?? ''}',
        body: '${campaign['body'] ?? ''}',
        type: '${campaign['notification_type'] ?? 'custom'}',
        actionType: '${campaign['action_type'] ?? 'none'}',
        createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
        isRead: row['read_at'] != null,
      );
    }).toList();
  }

  Future<int> unreadCount(String mobile) async {
    final rows = await notifications(mobile);
    return rows.where((item) => !item.isRead).length;
  }

  Future<bool> areAllRead(String mobile) async =>
      (await unreadCount(mobile)) == 0;

  Future<void> markAllRead(String mobile) async {
    if (mobile.length != 10) return;
    await _db
        .from('customer_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('mobile', mobile)
        .isFilter('read_at', null)
        .isFilter('deleted_at', null);
  }

  Future<void> remove(String mobile, String notificationId) async {
    await _db
        .from('customer_notifications')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId)
        .eq('mobile', mobile);
  }

  Future<void> removeAll(
      String mobile, Iterable<String> notificationIds) async {
    final ids = notificationIds.toList();
    if (ids.isEmpty) return;
    await _db
        .from('customer_notifications')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('mobile', mobile)
        .inFilter('id', ids);
  }
}
