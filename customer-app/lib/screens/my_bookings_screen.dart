import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/booking_service.dart';
import '../theme/app_colors.dart';

/// Lets a customer look up their bookings by mobile number. Once phone-OTP
/// auth lands this can drop the input and use the signed-in number directly.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.initialMobile = ''});

  final String initialMobile;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late final TextEditingController _mobile =
      TextEditingController(text: widget.initialMobile);
  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<Map<String, dynamic>> _bookings = const [];

  @override
  void initState() {
    super.initState();
    if (widget.initialMobile.trim().length == 10) {
      _lookup();
    }
  }

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final m = _mobile.text.trim();
    if (m.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
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
          icon: const Icon(Icons.arrow_back, color: AppColors.brand),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('My Bookings',
            style: TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
                fontSize: 19)),
      ),
      body: Column(
        children: [
          // mobile lookup
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onSubmitted: (_) => _lookup(),
                    decoration: InputDecoration(
                      hintText: 'Your mobile number',
                      hintStyle: const TextStyle(
                          color: AppColors.hint, fontSize: 13.5),
                      prefixText: '+91  ',
                      prefixStyle: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF7FAFF),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.hairline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.brand, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _lookup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.search, size: 22),
                  ),
                ),
              ],
            ),
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
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (!_searched) {
      return _hint(
        icon: Icons.receipt_long_outlined,
        title: 'See your bookings',
        body: 'Enter the mobile number you booked with to view your orders.',
      );
    }
    if (_bookings.isEmpty) {
      return _hint(
        icon: Icons.inbox_outlined,
        title: 'No bookings found',
        body: 'No bookings for +91 ${_mobile.text}. Place a bulk order to get '
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
              child: Icon(icon, size: 32, color: AppColors.brand),
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
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand)),
              _StatusPill(status),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Event', '${b['event_type']} · ${b['cans']} cans'),
          _kv('Date', '${b['event_date']}  ${b['event_time']}'),
          _kv('Village', '${b['village']}'),
          if (((b['discount_amount'] as num?)?.toInt() ?? 0) > 0)
            _kv('Offer',
                '${b['offer_code']}  -â‚¹${(b['discount_amount'] as num).toInt()}'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amt('Total', '₹${b['grand_total']}'),
              _amt('Advance', '₹${b['advance']}', accent: true),
              _amt('Balance', '₹${b['balance']}'),
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
          Text(k,
              style: const TextStyle(fontSize: 10.5, color: AppColors.hint)),
          Text(v,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: accent ? AppColors.brand : AppColors.textDark)),
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
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.4)),
    );
  }
}
