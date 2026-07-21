import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_details.dart';

/// Thin data layer over Supabase for settings + bookings.
class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Fetch admin-controlled pricing. Returns null on any failure so the UI
  /// can fall back to its built-in defaults.
  Future<AppSettings?> fetchSettings() async {
    try {
      final row = await _db
          .from('settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return null;
      return AppSettings.fromMap(row);
    } catch (_) {
      return null;
    }
  }

  /// Persist a booking. Returns the created row's booking_code, or throws.
  Future<String> createBooking(
    OrderDetails order, {
    required String paymentMethod, // 'online' | 'cash'
    required String status, // 'confirmed' | 'pending'
  }) async {
    final payload = {
      'booking_code': order.bookingId,
      'event_type': order.eventType,
      'cans': order.cans,
      'per_can_rate': order.perCanRate,
      'subtotal': order.subtotal,
      'delivery_charge': order.deliveryCharge,
      'grand_total': order.grandTotal,
      'advance': order.advance,
      'balance': order.balance,
      'village': order.village,
      'mobile': order.mobile,
      'address': order.address,
      'event_date': _dateOnly(order.eventDate),
      'event_time': order.eventTimeLabel,
      'payment_method': paymentMethod,
      'status': status,
    };
    final inserted = await _db
        .from('bookings')
        .insert(payload)
        .select('booking_code')
        .single();
    return inserted['booking_code'] as String;
  }

  /// Bookings for a given mobile number, newest first.
  Future<List<Map<String, dynamic>>> bookingsForMobile(String mobile) async {
    final rows = await _db
        .from('bookings')
        .select()
        .eq('mobile', mobile)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Admin-controlled settings mirrored from the `settings` table.
class AppSettings {
  const AppSettings({
    required this.perCanRate,
    required this.deliveryCharge,
    required this.deliveryFreeThreshold,
    required this.freeDeliveryVillage,
    required this.plantName,
    required this.plantPhone,
  });

  final int perCanRate;
  final int deliveryCharge;
  final int deliveryFreeThreshold;
  final String freeDeliveryVillage;
  final String plantName;
  final String plantPhone;

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        perCanRate: (m['per_can_rate'] as num).toInt(),
        deliveryCharge: (m['delivery_charge'] as num).toInt(),
        deliveryFreeThreshold: (m['delivery_free_threshold'] as num).toInt(),
        freeDeliveryVillage: m['free_delivery_village'] as String,
        plantName: m['plant_name'] as String,
        plantPhone: m['plant_phone'] as String,
      );
}
