import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/app_config_service.dart';
import '../theme/app_colors.dart';
import '../widgets/dotted_loader.dart';

/// Shows bookings belonging to the currently signed-in customer account.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.initialMobile = ''});

  final String initialMobile;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _accountMobile = '';
  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<Map<String, dynamic>> _bookings = const [];

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    final signedInMobile = await AuthService.instance.currentMobile();
    final m = signedInMobile ?? widget.initialMobile.trim();
    if (!mounted) return;
    if (m.length != 10) {
      if (mounted) {
        setState(() {
          _searched = true;
          _error = 'Please sign in again to view your bookings.';
        });
      }
      return;
    }
    setState(() {
      _accountMobile = m;
      _loading = true;
      _error = null;
    });
    try {
      final rows = await BookingService.instance.bookingsForMobile(m);
      setState(() {
        _bookings = rows;
        _searched = true;
      });
    } catch (_) {
      setState(() => _error = 'Could not load bookings. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.liveBrand),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(AppConfigService.instance.label('screen_my_bookings'),
            style: TextStyle(
                color: AppColors.liveBrand,
                fontWeight: FontWeight.w700,
                fontSize: 19)),
      ),
      body: Column(children: [
        if (_accountMobile.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Row(children: [
              Icon(Icons.verified_user_outlined,
                  size: 17, color: AppColors.liveBrand),
              const SizedBox(width: 7),
              const Text('Your account booking history',
                  style: TextStyle(fontSize: 12, color: AppColors.body)),
            ]),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFE23D3D),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        Expanded(
            child: _loading ? const Center(child: DottedLoader()) : _body()),
      ]),
    );
  }

  Widget _body() {
    if (!_searched) return const SizedBox.shrink();
    if (_bookings.isEmpty) {
      return _hint(
        icon: Icons.inbox_outlined,
        title: 'No bookings found',
        body:
            'No bookings are linked to this account yet. Place a bulk order to get '
            'started.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
      itemCount: _bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _BookingTile(_bookings[i]),
    );
  }

  Widget _hint({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: AppColors.liveBrand),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.body)),
          ],
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile(this.b);
  final Map<String, dynamic> b;

  @override
  Widget build(BuildContext context) {
    final status = (b['status'] as String?) ?? 'pending';
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
              Text('${b['booking_code']}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.liveBrand)),
              _StatusPill(status),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Event', '${b['event_type']} Â· ${b['cans']} cans'),
          _kv('Date', '${b['event_date']}  ${b['event_time']}'),
          _kv('Village', '${b['village']}'),
          if (((b['discount_amount'] as num?)?.toInt() ?? 0) > 0)
            _kv('Offer',
                '${b['offer_code']}  -Ã¢â€šÂ¹${(b['discount_amount'] as num).toInt()}'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amt('Total', 'â‚¹${b['grand_total']}'),
              _amt('Advance', 'â‚¹${b['advance']}', accent: true),
              _amt('Balance', 'â‚¹${b['balance']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
                width: 58,
                child: Text(k,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.hint))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark))),
          ],
        ),
      );

  Widget _amt(String k, String v, {bool accent = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(fontSize: 10.5, color: AppColors.hint)),
          Text(v,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: accent ? AppColors.liveBrand : AppColors.textDark)),
        ],
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
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
        fg = Color(0xFFD32020);
        break;
      case 'delivered':
        bg = AppColors.offerBg;
        fg = AppColors.liveBrand;
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
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.4)),
    );
  }
}
