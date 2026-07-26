import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_store.dart';
import '../theme/app_colors.dart';

const appNotifications = <AppNotification>[
  AppNotification(
    id: 'welcome',
    icon: Icons.water_drop_rounded,
    title: 'Welcome to ThakaThok 💧',
    body: 'Book bulk water for your weddings & events in just a few taps.',
  ),
  AppNotification(
    id: 'booking_guide',
    icon: Icons.verified_rounded,
    title: 'How booking works',
    body: 'Pay a 30% advance to confirm your date. The balance is cash on '
        'delivery.',
  ),
  AppNotification(
    id: 'delivery_guide',
    icon: Icons.local_shipping_rounded,
    title: 'Free delivery in Kasara Balkunda',
    body: 'A delivery charge applies only on orders under 25 cans in other '
        'villages.',
  ),
];

class AppNotification {
  const AppNotification({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String id;
  final IconData icon;
  final String title;
  final String body;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _mobile = '';
  Set<String> _removed = {};
  bool _loading = true;

  List<AppNotification> get _visible => appNotifications
      .where((notification) => !_removed.contains(notification.id))
      .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mobile = await AuthService.instance.currentMobile() ?? '';
    final removed = await NotificationStore.instance.removedIds(mobile);
    await NotificationStore.instance.markAllRead(mobile);
    if (!mounted) return;
    setState(() {
      _mobile = mobile;
      _removed = removed;
      _loading = false;
    });
  }

  Future<void> _remove(AppNotification notification) async {
    setState(() => _removed.add(notification.id));
    await NotificationStore.instance.remove(_mobile, notification.id);
  }

  Future<void> _clearAll() async {
    final ids = appNotifications.map((notification) => notification.id);
    setState(() => _removed.addAll(ids));
    await NotificationStore.instance.removeAll(_mobile, ids);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brand),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.brand,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (!_loading && visible.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text(
                'Clear all',
                style: TextStyle(
                  color: Color(0xFFE23D3D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            )
          : visible.isEmpty
              ? const _EmptyNotifications()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => Dismissible(
                    key: ValueKey(visible[index].id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _remove(visible[index]),
                    background: Container(
                      padding: const EdgeInsets.only(right: 22),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE23D3D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white),
                    ),
                    child: _NotificationCard(
                      visible[index],
                      onDelete: () => _remove(visible[index]),
                    ),
                  ),
                ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard(this.notification, {required this.onDelete});

  final AppNotification notification;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 7, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(notification.icon, color: AppColors.brand, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notification.body,
                  style: const TextStyle(
                    color: AppColors.body,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove notification',
            onPressed: onDelete,
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              color: AppColors.brand, size: 48),
          SizedBox(height: 12),
          Text(
            "You're all caught up",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
