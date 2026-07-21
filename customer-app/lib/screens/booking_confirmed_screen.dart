import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

const String _kPlantName = 'Mahalakshmi Water Plant';

/// Screen 4 — shown after the advance is paid (online) or the customer has
/// committed to paying cash. Online = confirmed now; cash = pending until the
/// plant confirms the received cash.
class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({
    super.key,
    required this.order,
    required this.paidOnline,
  });

  final OrderDetails order;

  /// true → paid online (confirmed immediately); false → cash (pending).
  final bool paidOnline;

  @override
  Widget build(BuildContext context) {
    final confirmed = paidOnline;
    final accent = confirmed ? const Color(0xFF1B9C5A) : AppColors.brand;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  confirmed
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  color: accent,
                  size: 58,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                confirmed ? 'Booking Confirmed!' : 'Booking Pending',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                confirmed
                    ? 'Your advance is received and the date is blocked.'
                    : 'Pay the cash advance to confirm. Date is not blocked yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.body),
              ),
              const SizedBox(height: 26),

              // Booking details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.offerBg,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    _kv('Booking ID', order.bookingId, big: true),
                    const Divider(height: 24),
                    _kv('Event', order.eventType),
                    const SizedBox(height: 10),
                    _kv('Cans', '${order.cans}'),
                    const SizedBox(height: 10),
                    _kv('Date & Time',
                        '${_fmtDate(order.eventDate)}, ${order.eventTime.format(context)}'),
                    const SizedBox(height: 10),
                    _kv('Village', order.village),
                    const Divider(height: 24),
                    _kv(confirmed ? 'Advance Paid' : 'Advance Due',
                        '₹${order.advance}'),
                    const SizedBox(height: 10),
                    _kv('Balance (COD)', '₹${order.balance}'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Status note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: confirmed
                      ? const Color(0xFFEAF7EF)
                      : const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      confirmed
                          ? Icons.phone_in_talk_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: confirmed
                          ? const Color(0xFF1B9C5A)
                          : const Color(0xFFB26A00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        confirmed
                            ? '$_kPlantName staff will call you in 5 mins.'
                            : 'We received your request. $_kPlantName will '
                                'confirm once the cash advance is paid.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: confirmed
                              ? const Color(0xFF166B40)
                              : const Color(0xFF8A5200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Note: Advance paid is non-refundable as per policy.',
                style: TextStyle(fontSize: 10.5, color: AppColors.hint),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('BACK TO HOME',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k,
            style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.body,
                fontWeight: FontWeight.w500)),
        Text(v,
            style: TextStyle(
                fontSize: big ? 18 : 13.5,
                color: big ? AppColors.brand : AppColors.textDark,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
