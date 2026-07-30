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
      itemBuilder: (_, i) => _BookingTile(_bookings[i], onChanged: _lookup),
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

class _BookingTile extends StatefulWidget {
  const _BookingTile(this.b, {required this.onChanged});
  final Map<String, dynamic> b;
  final Future<void> Function() onChanged;

  @override
  State<_BookingTile> createState() => _BookingTileState();
}

class _BookingTileState extends State<_BookingTile> {
  bool _working = false;
  Map<String, dynamic> get b => widget.b;

  Map<String, dynamic>? get _pendingRequest {
    final requests =
        List<dynamic>.from(b['booking_requests'] as List? ?? const []);
    for (final item in requests) {
      final request = Map<String, dynamic>.from(item as Map);
      if (request['status'] == 'pending') return request;
    }
    return null;
  }

  Future<void> _cancelRequest() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Cancellation'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'The 30% advance is non-refundable. Admin approval is required.'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration:
                const InputDecoration(labelText: 'Reason for cancellation'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Submit Request')),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.length < 3) return;
    await _run(() => BookingService.instance.requestCancellation(
          bookingId: '${b['id']}',
          reason: reason,
        ));
  }

  Future<void> _changeRequest() async {
    final cans = TextEditingController();
    final address = TextEditingController();
    final reason = TextEditingController();
    DateTime? date;
    TimeOfDay? time;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Request for Change'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                  'Enter only the details you want changed. Admin approval is required.'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                  child: Text(date == null
                      ? 'New date'
                      : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 10, minute: 0));
                    if (picked != null) setDialogState(() => time = picked);
                  },
                  child:
                      Text(time == null ? 'New time' : time!.format(context)),
                )),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: cans,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'New quantity'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'New address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reason,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Reason for change *'),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Close')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit Request')),
          ],
        ),
      ),
    );
    if (submitted != true || reason.text.trim().length < 3) {
      cans.dispose();
      address.dispose();
      reason.dispose();
      return;
    }
    final dateValue = date == null
        ? null
        : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';
    final timeValue = time == null
        ? null
        : '${time!.hourOfPeriod == 0 ? 12 : time!.hourOfPeriod}:${time!.minute.toString().padLeft(2, '0')} ${time!.period == DayPeriod.am ? 'AM' : 'PM'}';
    final cansValue = int.tryParse(cans.text.trim());
    final addressValue = address.text.trim();
    final reasonValue = reason.text.trim();
    cans.dispose();
    address.dispose();
    reason.dispose();
    await _run(() => BookingService.instance.requestBookingChange(
          bookingId: '${b['id']}',
          reason: reasonValue,
          eventDate: dateValue,
          eventTime: timeValue,
          cans: cansValue,
          address: addressValue,
        ));
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _working = true);
    try {
      await task();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted to admin.')));
      await widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

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
          _kv('Event', '${b['event_type']} · ${b['cans']} cans'),
          _kv('Date', '${b['event_date']}  ${b['event_time']}'),
          _kv('Village', '${b['village']}'),
          if (((b['discount_amount'] as num?)?.toInt() ?? 0) > 0)
            _kv('Offer',
                '${b['offer_code']}  -₹${(b['discount_amount'] as num).toInt()}'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amt('Total', '₹${b['grand_total']}'),
              _amt('Advance', '₹${b['advance']}', accent: true),
              _amt('Balance', '₹${b['balance']}'),
            ],
          ),
          if (_pendingRequest != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_pendingRequest!['request_type'] == 'cancellation' ? 'Cancellation' : 'Change'} request pending admin review',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A5200)),
              ),
            ),
          ],
          if (['pending', 'confirmed'].contains(status) &&
              _pendingRequest == null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: _working ? null : _changeRequest,
                child: const Text('Request for Change'),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                onPressed: _working ? null : _cancelRequest,
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32020)),
                child: const Text('Request Cancellation'),
              )),
            ]),
          ],
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
