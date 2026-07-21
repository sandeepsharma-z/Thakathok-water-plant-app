import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../services/booking_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import 'booking_confirmed_screen.dart';

const String kPlantName = 'Mahalakshmi Water Plant';
const String kPlantPhone = '91XXXXXXXXXX';

/// Screen 3 — order summary + 30% non-refundable advance with two payment
/// options (online instant-confirm, or cash manual-confirm).
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key, required this.order});

  final OrderDetails order;

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
        centerTitle: true,
        title: const BrandLogo(size: 38),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: [
          const Text(
            'Confirm & Pay Advance',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pay 30% advance to confirm your booking for '
            '${order.eventType.toLowerCase()}.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.body),
          ),
          const SizedBox(height: 20),

          // ── Order summary card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.offerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Summary',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand)),
                const SizedBox(height: 14),
                _row('${order.cans} Cans × ₹${order.perCanRate}/Can',
                    '₹${order.subtotal}'),
                if (order.deliveryCharge > 0) ...[
                  const SizedBox(height: 8),
                  _row('Delivery Charge', '₹${order.deliveryCharge}'),
                ],
                const Divider(height: 22),
                _row('Total', '₹${order.grandTotal}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Non-refundable warning ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF5C2C2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ 30% Advance is NON-REFUNDABLE',
                  style: TextStyle(
                    color: Color(0xFFD32020),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'If cancelled, the event date will not be unblocked.',
                  style: TextStyle(color: Color(0xFF9A3A3A), fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Advance / balance split ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _row('30% Advance to Confirm Booking', '₹${order.advance}',
                    highlight: true, big: true),
                const SizedBox(height: 10),
                _row('Balance 70% (Cash on Delivery)', '₹${order.balance}'),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // ── Option 1: Pay online ────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () => _payOnline(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('PAY ₹${order.advance} ONLINE',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const Text('UPI • GPay • PhonePe',
                      style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Option 2: Pay cash ──────────────────────────────────────
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: () => _payCash(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('PAY ₹${order.advance} CASH',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('to $kPlantName',
                      style: const TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Date is blocked only after advance is paid/confirmed.',
              style: TextStyle(fontSize: 11, color: AppColors.hint),
            ),
          ),
        ],
      ),
    );
  }

  // Online → instant confirm (Amazon-Pay style).
  void _payOnline(BuildContext context) {
    _confirm(context,
        method: 'online', status: 'confirmed', paidOnline: true);
  }

  // Cash → show instructions; booking stays pending until admin confirms.
  void _payCash(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CashInstructionsSheet(
        order: order,
        onConfirm: () => _confirm(context,
            method: 'cash', status: 'pending', paidOnline: false),
      ),
    );
  }

  /// Saves the booking to Supabase, then shows the confirmation screen.
  Future<void> _confirm(
    BuildContext context, {
    required String method,
    required String status,
    required bool paidOnline,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      ),
    );

    Object? error;
    try {
      await BookingService.instance
          .createBooking(order, paymentMethod: method, status: status);
    } catch (e) {
      error = e;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss the loading spinner

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save booking. Please try again.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BookingConfirmedScreen(order: order, paidOnline: paidOnline),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, bool highlight = false, bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(label,
              style: TextStyle(
                fontSize: big ? 13.5 : (bold ? 15 : 13),
                fontWeight: bold || big ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppColors.brand : AppColors.body,
              )),
        ),
        Text(value,
            style: TextStyle(
              fontSize: big ? 20 : (bold ? 16 : 14),
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.brand
                  : (bold ? AppColors.textDark : AppColors.body),
            )),
      ],
    );
  }
}

/// Bottom sheet shown when the customer chooses to pay cash.
class _CashInstructionsSheet extends StatelessWidget {
  const _CashInstructionsSheet({required this.order, required this.onConfirm});
  final OrderDetails order;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Cash Payment Selected',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand)),
          const SizedBox(height: 16),
          _step('1', 'Note down Booking ID: ', bold: order.bookingId),
          _step('2',
              'Pay ₹${order.advance} cash to $kPlantName within 24 hours'),
          _step('3',
              'Call / WhatsApp $kPlantPhone with your Booking ID'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '⚠️ Booking will be CONFIRMED only after cash is received.\n'
              'Date is not blocked until the advance is paid.',
              style: TextStyle(
                  color: Color(0xFFD32020),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close sheet
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('I WILL PAY CASH',
                  style: TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String n, String text, {String? bold}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: Text(n,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textDark, height: 1.35),
                children: [
                  TextSpan(text: text),
                  if (bold != null)
                    TextSpan(
                        text: bold,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
