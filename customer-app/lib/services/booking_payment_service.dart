import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_details.dart';

class SecureBookingPaymentOrder {
  const SecureBookingPaymentOrder({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.plantName,
    required this.customerName,
  });
  final String keyId;
  final String orderId;
  final int amountPaise;
  final String plantName;
  final String customerName;
}

class BookingPaymentService {
  BookingPaymentService._();
  static final instance = BookingPaymentService._();
  SupabaseClient get _db => Supabase.instance.client;

  Future<SecureBookingPaymentOrder> createOrder(OrderDetails order) async {
    final date =
        '${order.eventDate.year.toString().padLeft(4, '0')}-${order.eventDate.month.toString().padLeft(2, '0')}-${order.eventDate.day.toString().padLeft(2, '0')}';
    final response = await _db.functions.invoke('booking-payment', body: {
      'action': 'create',
      'name': order.name,
      'mobile': order.mobile,
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
    return SecureBookingPaymentOrder(
      keyId: '${data['key_id']}',
      orderId: '${data['order_id']}',
      amountPaise: (data['amount_paise'] as num).toInt(),
      plantName: '${data['plant_name']}',
      customerName: '${data['customer_name']}',
    );
  }

  Future<String> verify({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _db.functions.invoke('booking-payment', body: {
      'action': 'verify',
      'order_id': orderId,
      'payment_id': paymentId,
      'signature': signature,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['success'] != true) {
      throw StateError('${data['error'] ?? 'Payment verification failed.'}');
    }
    return '${data['booking_code'] ?? ''}';
  }
}
