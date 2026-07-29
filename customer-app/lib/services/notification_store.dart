import 'customer_api_service.dart';

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
  Future<List<AppNotification>> notifications(String mobile) async {
    if (mobile.length != 10) return const [];
    final result = await CustomerApiService.instance.call('notifications');
    final rows =
        List<Map<String, dynamic>>.from(result['notifications'] as List);
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
    await CustomerApiService.instance.call(
      'notifications_update',
      {'operation': 'mark_all'},
    );
  }

  Future<void> remove(String mobile, String notificationId) async {
    await CustomerApiService.instance.call(
      'notifications_update',
      {'operation': 'remove', 'id': notificationId},
    );
  }

  Future<void> removeAll(
      String mobile, Iterable<String> notificationIds) async {
    final ids = notificationIds.toList();
    if (ids.isEmpty) return;
    await CustomerApiService.instance.call(
      'notifications_update',
      {'operation': 'remove_all', 'ids': ids},
    );
  }
}
