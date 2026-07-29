import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_details.dart';
import 'auth_service.dart';

class WalletBookingResult {
  const WalletBookingResult({required this.bookingCode, required this.balance});
  final String bookingCode;
  final int balance;
}

class WalletBookingService {
  WalletBookingService._();
  static final instance = WalletBookingService._();
  SupabaseClient get _db => Supabase.instance.client;

  Future<WalletBookingResult> pay(OrderDetails order) async {
    final mobile = await AuthService.instance.currentMobile() ?? '';
    final token = await AuthService.instance.currentToken() ?? '';
    if (mobile.length != 10 || token.isEmpty) {
      throw StateError('Please login again to pay from your wallet.');
    }
    final date =
        '${order.eventDate.year.toString().padLeft(4, '0')}-${order.eventDate.month.toString().padLeft(2, '0')}-${order.eventDate.day.toString().padLeft(2, '0')}';
    final requestId =
        'wallet_${mobile}_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    final response = await _db.functions.invoke('wallet-booking', body: {
      'mobile': mobile,
      'session_token': token,
      'request_id': requestId,
      'name': order.name,
      'event_type': order.eventType,
      'cans': order.cans,
      'village': order.village,
      'address': order.address,
      'event_date': date,
      'event_time': order.eventTimeLabel,
      'offer_code': order.offerCode ?? '',
      'expected_advance': order.advance,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['success'] != true) {
      throw StateError('${data['error'] ?? 'Wallet payment failed.'}');
    }
    return WalletBookingResult(
      bookingCode: '${data['booking_code'] ?? ''}',
      balance: (data['balance'] as num?)?.toInt() ?? 0,
    );
  }
}
