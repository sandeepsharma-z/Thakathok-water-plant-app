import 'package:flutter/material.dart';

import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import 'admin_settings_screen.dart';

/// Bookings list for the plant owner: filter by status and confirm the cash
/// bookings once payment is received.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _filters = ['pending', 'confirmed', 'all'];
  String _filter = 'pending';

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() => BookingService.instance
      .allBookings(status: _filter == 'all' ? null : _filter);

  void _refresh() => setState(() => _future = _load());

  Future<void> _confirm(Map<String, dynamic> b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm this booking?'),
        content: Text(
          'Confirm ${b['booking_code']} — ${b['cans']} cans.\n\n'
          'Only confirm after the ₹${b['advance']} cash advance is received. '
          'The event date will be blocked.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await BookingService.instance
          .updateBookingStatus(b['id'] as String, 'confirmed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${b['booking_code']} confirmed')),
      );
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Rates & charges',
            icon: const Icon(Icons.settings_outlined, color: AppColors.brand),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
              );
              _refresh();
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppColors.brand),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1),
                      ),
                      selected: _filter == f,
                      onSelected: (_) {
                        setState(() => _filter = f);
                        _refresh();
                      },
                      selectedColor: AppColors.brand,
                      labelStyle: TextStyle(
                        color: _filter == f ? Colors.white : AppColors.body,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      backgroundColor: AppColors.offerBg,
                      side: BorderSide.none,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
                  );
                }
                if (snap.hasError) {
                  return _Message(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load bookings',
                    body: 'Check your connection, and make sure the database '
                        'tables have been created.',
                    onRetry: _refresh,
                  );
                }
                final rows = snap.data ?? const [];
                if (rows.isEmpty) {
                  return _Message(
                    icon: Icons.inbox_outlined,
                    title: 'No $_filter bookings',
                    body: 'New bookings will appear here as customers place '
                        'them.',
                    onRetry: _refresh,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  color: AppColors.brand,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _BookingCard(
                      booking: rows[i],
                      onConfirm: () => _confirm(rows[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onConfirm});

  final Map<String, dynamic> booking;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isCash = (booking['payment_method'] as String?) == 'cash';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${booking['booking_code']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 10),
          _kv('Event', '${booking['event_type']}'),
          _kv('Cans', '${booking['cans']} × ₹${booking['per_can_rate']}'),
          _kv('Date', '${booking['event_date']}  ${booking['event_time']}'),
          _kv('Village', '${booking['village']}'),
          _kv('Mobile', '+91 ${booking['mobile']}'),
          _kv('Address', '${booking['address']}'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ₹${booking['grand_total']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Advance ₹${booking['advance']} · ${isCash ? 'Cash' : 'Online'}',
                style: const TextStyle(fontSize: 12, color: AppColors.body),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('CONFIRM — ₹${booking['advance']} received'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B9C5A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 68,
              child: Text(
                k,
                style: const TextStyle(fontSize: 12, color: AppColors.hint),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    late final Color bg, fg;
    switch (status) {
      case 'confirmed':
        bg = const Color(0xFFEAF7EF);
        fg = const Color(0xFF166B40);
        break;
      case 'cancelled':
        bg = const Color(0xFFFDECEC);
        fg = const Color(0xFFD32020);
        break;
      case 'delivered':
        bg = AppColors.offerBg;
        fg = AppColors.brand;
        break;
      default:
        bg = const Color(0xFFFFF4E5);
        fg = const Color(0xFF8A5200);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.hint),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.body),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
