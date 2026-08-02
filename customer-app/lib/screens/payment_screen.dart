import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/order_details.dart';
import '../services/booking_payment_service.dart';
import '../services/booking_service.dart';
import '../services/plant_config.dart';
import '../services/app_config_service.dart';
import '../services/language_service.dart';
import '../services/wallet_booking_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import 'booking_confirmed_screen.dart';

// Contact details are admin-controlled and loaded live from settings.
String get kPlantName => PlantConfig.instance.plantName;
String get kPlantPhone => PlantConfig.instance.plantPhone;

/// Screen 3 — order summary + 30% non-refundable advance with two payment
/// options (online instant-confirm, or cash manual-confirm).
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.order});

  final OrderDetails order;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late OrderDetails order;
  late final Razorpay _razorpay;
  final _offerCode = TextEditingController();
  bool _checkingOffer = false;
  bool _creatingOnlineOrder = false;
  bool _verifyingOnlinePayment = false;
  String? _secureOrderId;
  int _walletBalance = 0;
  bool _walletPaying = false;

  @override
  void initState() {
    super.initState();
    LanguageService.instance.addListener(_onLanguageChanged);
    order = widget.order;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final summary =
          await BookingService.instance.customerHomeSummary(order.mobile);
      if (mounted) setState(() => _walletBalance = summary.walletBalance);
    } catch (_) {}
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    _razorpay.clear();
    _offerCode.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfigService.instance;
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
        centerTitle: true,
        title: const BrandLogo(size: 38),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: [
          Text(
            config.label('payment_title'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.liveBrand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pay ${config.advancePercent}% advance to confirm your booking for '
            '${order.eventType.toLowerCase()}.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.body),
          ),
          const SizedBox(height: 20),

          // ── Order summary card ──────────────────────────────────────
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.offerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.liveBrand.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.label('payment_summary_heading'),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.liveBrand)),
                const SizedBox(height: 14),
                _row('${order.cans} Cans × ₹${order.perCanRate}/Can',
                    '₹${order.subtotal}'),
                if (order.deliveryCharge > 0) ...[
                  const SizedBox(height: 8),
                  _row('Delivery Charge', '₹${order.deliveryCharge}'),
                ],
                if (order.hasDiscount) ...[
                  const SizedBox(height: 8),
                  _row(
                    'Offer ${order.offerCode} (${order.offerDiscountPercent}%)',
                    '-₹${order.discountAmount}',
                  ),
                ],
                const Divider(height: 22),
                _row(tr('Total'), '₹${order.grandTotal}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Have an offer code?'),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _offerCode,
                        enabled: !order.hasDiscount && !_checkingOffer,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: tr('Enter code'),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF7FAFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.hairline),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    TextButton(
                      onPressed: _checkingOffer
                          ? null
                          : order.hasDiscount
                              ? _removeOffer
                              : _applyOffer,
                      child: _checkingOffer
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.liveBrand),
                            )
                          : Text(tr(order.hasDiscount ? 'Remove' : 'Apply')),
                    ),
                  ],
                ),
                if (order.hasDiscount) ...[
                  const SizedBox(height: 6),
                  Text(
                    'You saved ₹${order.discountAmount} with ${order.offerCode}.',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF166B40)),
                  ),
                ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ ${config.advancePercent}% ${config.paymentText('advance_warning')}',
                  style: const TextStyle(
                    color: Color(0xFFD32020),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('If cancelled, the event date will not be unblocked.'),
                  style:
                      const TextStyle(color: Color(0xFF9A3A3A), fontSize: 11.5),
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
                _row(
                    '${config.advancePercent}% ${tr('Advance to Confirm Booking')}',
                    '₹${order.advance}',
                    highlight: true,
                    big: true),
                const SizedBox(height: 10),
                _row(
                    '${tr('Balance')} ${config.balancePercent}% (${tr('Cash on Delivery')})',
                    '₹${order.balance}'),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // ── Option 1: Pay online ────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _creatingOnlineOrder || _verifyingOnlinePayment
                  ? null
                  : _payOnline,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.liveBrand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${tr('PAY')} ₹${order.advance} ${tr('ONLINE')}',
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

          SizedBox(
            height: 58,
            child: OutlinedButton.icon(
              onPressed: _walletPaying ? null : _payFromWallet,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF12855A),
                side: const BorderSide(color: Color(0xFF28A772), width: 1.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _walletPaying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF12855A)))
                  : const Icon(Icons.account_balance_wallet_rounded),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tr('PAY')} ₹${order.advance} ${tr('FROM WALLET')}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${tr('Available balance')}: ₹$_walletBalance',
                      style: const TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),

          // ── Option 3: Pay cash ──────────────────────────────────────
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: _payCash,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.liveBrand,
                side: BorderSide(color: AppColors.liveBrand, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${tr('PAY')} ₹${order.advance} ${tr('CASH')}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('${tr('to')} $kPlantName',
                      style: const TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              tr('Date is blocked only after advance is paid/confirmed.'),
              style: TextStyle(fontSize: 11, color: AppColors.hint),
            ),
          ),
        ],
      ),
    );
  }

  // Online → open Razorpay checkout for the 30% advance.
  Future<void> _applyOffer() async {
    final entered = _offerCode.text.trim().toUpperCase();
    if (entered.isEmpty) {
      _showOfferMessage('Enter an offer code.');
      return;
    }
    setState(() => _checkingOffer = true);
    final settings = await BookingService.instance.fetchSettings();
    if (!mounted) return;
    setState(() => _checkingOffer = false);

    if (settings == null) {
      _showOfferMessage('Could not check the offer. Please try again.');
      return;
    }
    if (!settings.offerEnabled) {
      _showOfferMessage('This offer is currently inactive.');
      return;
    }
    if (entered != settings.offerCode.trim().toUpperCase()) {
      _showOfferMessage('This offer code is invalid.');
      return;
    }
    if (order.subtotal < settings.offerMinSubtotal) {
      _showOfferMessage(
          'Minimum product subtotal is ₹${settings.offerMinSubtotal}.');
      return;
    }

    final discount =
        (order.subtotal * settings.offerDiscountPercent / 100).round();
    setState(() {
      order = order.withOffer(
        code: settings.offerCode.trim().toUpperCase(),
        percent: settings.offerDiscountPercent,
        discount: discount,
      );
      _offerCode.text = order.offerCode!;
    });
  }

  void _removeOffer() {
    setState(() {
      order = order.withoutOffer();
      _offerCode.clear();
    });
  }

  void _showOfferMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(message))),
    );
  }

  Future<void> _payOnline() async {
    setState(() => _creatingOnlineOrder = true);
    try {
      final secureOrder =
          await BookingPaymentService.instance.createOrder(order);
      if (!mounted) return;
      _secureOrderId = secureOrder.orderId;
      _razorpay.open({
        'key': secureOrder.keyId,
        'order_id': secureOrder.orderId,
        'amount': secureOrder.amountPaise,
        'currency': 'INR',
        'name': secureOrder.plantName,
        'description': 'Advance for booking ${order.bookingId}',
        'prefill': {'contact': order.mobile},
        'theme': {'color': '#004FDA'},
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_paymentError(error)),
      ));
    } finally {
      if (mounted) setState(() => _creatingOnlineOrder = false);
    }
  }

  // The client callback is not trusted. The server verifies signature, exact
  // amount, captured payment and paid order before inserting the booking.
  Future<void> _onPaySuccess(PaymentSuccessResponse response) async {
    if (_verifyingOnlinePayment) return;
    final orderId = response.orderId ?? _secureOrderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(
              'Incomplete secure payment response. Please contact support.')),
        ));
      }
      return;
    }
    setState(() => _verifyingOnlinePayment = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppColors.liveBrand),
      ),
    );
    try {
      await BookingPaymentService.instance.verify(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              BookingConfirmedScreen(order: order, paidOnline: true),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_paymentError(error)),
      ));
    } finally {
      if (mounted) setState(() => _verifyingOnlinePayment = false);
    }
  }

  String _paymentError(Object error) {
    final text = error.toString();
    final match = RegExp(r'error:\s*([^,}\]]+)').firstMatch(text);
    return tr(match?.group(1)?.trim() ??
        'Secure payment could not be completed. Please try again.');
  }

  void _onPayError(PaymentFailureResponse response) {
    if (!mounted) return;
    final cancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr(cancelled
          ? 'Payment cancelled.'
          : 'Payment failed. Please try again or choose Cash.')),
    ));
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

  Future<void> _payFromWallet() async {
    if (_walletBalance < order.advance) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('Insufficient wallet balance. Add ₹{amount} more.')
            .replaceAll('{amount}', '${order.advance - _walletBalance}')),
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Pay from wallet?')),
        content: Text(
            tr('₹{amount} will be deducted from your wallet to confirm this booking.')
                .replaceAll('{amount}', '${order.advance}')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr('CANCEL'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(tr('PAY & CONFIRM'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _walletPaying = true);
    try {
      final result = await WalletBookingService.instance.pay(order);
      if (!mounted) return;
      setState(() => _walletBalance = result.balance);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              BookingConfirmedScreen(order: order, paidOnline: true),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_paymentError(error))),
      );
    } finally {
      if (mounted) setState(() => _walletPaying = false);
    }
  }

  // Cash → show instructions; booking stays pending until admin confirms.
  void _payCash() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CashInstructionsSheet(
        order: order,
        onConfirm: () =>
            _confirm(method: 'cash', status: 'pending', paidOnline: false),
      ),
    );
  }

  /// Saves the booking to Supabase, then shows the confirmation screen.
  Future<void> _confirm({
    required String method,
    required String status,
    required bool paidOnline,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppColors.liveBrand),
      ),
    );

    Object? error;
    try {
      await BookingService.instance
          .createBooking(order, paymentMethod: method, status: status);
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss the loading spinner

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(error.toString().contains('CUSTOMER_NOT_ELIGIBLE')
                ? 'Your ordering is temporarily on hold. Please contact Mahalakshmi Water Plant on 8080739807 to clear dues.'
                : error.toString().contains('DATE_UNAVAILABLE')
                    ? AppConfigService.instance.label('date_unavailable_error')
                    : AppConfigService.instance.label('booking_save_error')),
          ),
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
                color: highlight ? AppColors.liveBrand : AppColors.body,
              )),
        ),
        Text(value,
            style: TextStyle(
              fontSize: big ? 20 : (bold ? 16 : 14),
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.liveBrand
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
    final config = AppConfigService.instance;
    final replacements = {
      'advance': '₹${order.advance}',
      'plant_name': kPlantName,
      'plant_phone': kPlantPhone,
    };
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
          SizedBox(height: 18),
          Text(config.paymentText('cash_heading'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.liveBrand)),
          const SizedBox(height: 16),
          _step('1', '${config.paymentText('cash_step_1')} ',
              bold: order.bookingId),
          _step(
              '2',
              config.interpolate(
                  config.paymentText('cash_step_2'), replacements)),
          _step(
              '3',
              config.interpolate(
                  config.paymentText('cash_step_3'), replacements)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '⚠️ ${config.paymentText('cash_notice')}',
              style: const TextStyle(
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
                backgroundColor: AppColors.liveBrand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(config.paymentText('cash_button'),
                  style: const TextStyle(
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
            decoration: BoxDecoration(
              color: AppColors.liveBrand,
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
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.liveBrand)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
