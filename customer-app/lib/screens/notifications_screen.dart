import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_store.dart';
import '../services/app_config_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import '../widgets/dotted_loader.dart';
import 'bulk_order_form_screen.dart';
import 'help_support_screen.dart';
import 'my_bookings_screen.dart';
import 'wallet_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _mobile = '';
  bool _loading = true;
  String? _error;
  List<AppNotification> _items = const [];
  Timer? _poller;
  @override
  void initState() {
    super.initState();
    LanguageService.instance.addListener(_languageChanged);
    _load();
    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_languageChanged);
    _poller?.cancel();
    super.dispose();
  }

  void _languageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final mobile = await AuthService.instance.currentMobile() ?? '';
      final items = await NotificationStore.instance.notifications(mobile);
      await NotificationStore.instance.markAllRead(mobile);
      if (mounted) {
        setState(() {
          _mobile = mobile;
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = tr('Could not load notifications.');
          _loading = false;
        });
      }
    }
  }

  Future<void> _remove(AppNotification n) async {
    setState(() => _items.removeWhere((x) => x.id == n.id));
    await NotificationStore.instance.remove(_mobile, n.id);
  }

  Future<void> _clear() async {
    final ids = _items.map((x) => x.id).toList();
    setState(() => _items = []);
    await NotificationStore.instance.removeAll(_mobile, ids);
  }

  void _open(AppNotification n) {
    Widget? page;
    switch (n.actionType) {
      case 'bookings':
        page = const MyBookingsScreen();
        break;
      case 'wallet':
        page = WalletScreen(mobile: _mobile);
        break;
      case 'order':
        page = const BulkOrderFormScreen();
        break;
      case 'support':
        page = const HelpSupportScreen();
        break;
    }
    if (page != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page!));
    }
  }

  IconData _icon(String type) => switch (type) {
        'payment_due' => Icons.currency_rupee_rounded,
        'cash_pending' => Icons.payments_outlined,
        'booking' => Icons.receipt_long_rounded,
        'delivery' => Icons.local_shipping_rounded,
        'offer' => Icons.local_offer_rounded,
        'service' => Icons.campaign_rounded,
        _ => Icons.notifications_rounded
      };
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back_rounded, color: AppColors.liveBrand)),
          title: Text(AppConfigService.instance.label('screen_notifications'),
              style: TextStyle(
                  color: AppColors.liveBrand,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          actions: [
            if (!_loading && _items.isNotEmpty)
              TextButton(
                  onPressed: _clear,
                  child: Text(tr('Clear all'),
                      style: const TextStyle(
                          color: Color(0xFFE23D3D),
                          fontWeight: FontWeight.w700)))
          ]),
      body: _loading
          ? const Center(child: DottedLoader())
          : _error != null
              ? Center(child: Text(tr(_error!)))
              : _items.isEmpty
                  ? const _Empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            return Dismissible(
                                key: ValueKey(n.id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _remove(n),
                                background: Container(
                                    padding: const EdgeInsets.only(right: 22),
                                    alignment: Alignment.centerRight,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFE23D3D),
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white)),
                                child: _Card(n,
                                    icon: _icon(n.type),
                                    onDelete: () => _remove(n),
                                    onTap: () => _open(n)));
                          })));
}

class _Card extends StatelessWidget {
  const _Card(this.n,
      {required this.icon, required this.onDelete, required this.onTap});
  final AppNotification n;
  final IconData icon;
  final VoidCallback onDelete, onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: n.actionType == 'none' ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
          padding: EdgeInsets.fromLTRB(15, 15, 7, 15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairline),
              boxShadow: [
                BoxShadow(
                    color: AppColors.liveBrand.withValues(alpha: .06),
                    blurRadius: 18,
                    offset: const Offset(0, 7))
              ]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                    color: AppColors.tint,
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: AppColors.liveBrand, size: 21)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(tr(n.title),
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(tr(n.body),
                      style: const TextStyle(
                          color: AppColors.body, fontSize: 12, height: 1.45)),
                  const SizedBox(height: 7),
                  Text(_time(n.createdAt),
                      style: const TextStyle(
                          color: AppColors.hint, fontSize: 10.5)),
                  if (n.actionType != 'none') ...[
                    const SizedBox(height: 9),
                    Text(n.actionType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                            color: AppColors.liveBrand,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800))
                  ]
                ])),
            IconButton(
                tooltip: tr('Remove notification'),
                onPressed: onDelete,
                icon: const Icon(Icons.close_rounded,
                    size: 19, color: AppColors.textMuted))
          ])));
}

String _time(DateTime d) {
  final local = d.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${local.day}/${local.month}/${local.year} · $hour:$minute $period';
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.notifications_none_rounded,
            color: AppColors.liveBrand, size: 48),
        SizedBox(height: 12),
        Text(tr("You're all caught up"),
            style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700))
      ]));
}
