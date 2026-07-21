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

  // ── Admin ────────────────────────────────────────────────────────────
  // These require a signed-in admin (Supabase Auth); RLS blocks anon writes.

  /// All bookings, newest first. Pass a [status] to filter.
  Future<List<Map<String, dynamic>>> allBookings({String? status}) async {
    var query = _db.from('bookings').select();
    if (status != null) query = query.eq('status', status);
    final rows = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Change a booking's status — e.g. 'confirmed' once cash is received.
  Future<void> updateBookingStatus(String id, String status) async {
    await _db.from('bookings').update({'status': status}).eq('id', id);
  }

  /// Update the admin-controlled pricing.
  Future<void> updateSettings({
    required int perCanRate,
    required int deliveryCharge,
  }) async {
    await _db.from('settings').update({
      'per_can_rate': perCanRate,
      'delivery_charge': deliveryCharge,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', 1);
  }

  // ── Admin auth ───────────────────────────────────────────────────────

  bool get isAdminSignedIn => _db.auth.currentUser != null;

  Future<void> adminSignIn(String email, String password) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> adminSignOut() => _db.auth.signOut();

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
