import 'dart:typed_data';

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
      final row = await _db.from('settings').select().eq('id', 1).maybeSingle();
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
      'customer_name': order.name,
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
      'offer_code': order.offerCode,
      'offer_discount_percent': order.offerDiscountPercent,
      'discount_amount': order.discountAmount,
      'status': status,
    };
    final inserted = await _db
        .from('bookings')
        .insert(payload)
        .select('booking_code')
        .single();
    return inserted['booking_code'] as String;
  }

  /// Save/update the customer's profile in Supabase so the admin can see
  /// every registered user (even before they book). Best-effort — never throws
  /// to the caller; a failed sync just means the profile stays on-device.
  Future<void> upsertCustomer({
    required String mobile,
    required String name,
    required String village,
    required String address,
    String? avatarUrl,
  }) async {
    if (mobile.length != 10) return;
    try {
      await _db.from('customers').upsert({
        'mobile': mobile,
        'name': name,
        'village': village,
        'address': address,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'mobile');
    } catch (_) {
      // Ignore — profile is still saved locally on the device.
    }
  }

  /// Upload a customer-selected avatar and return its public URL.
  Future<String> uploadAvatar({
    required String mobile,
    required Uint8List bytes,
    required String extension,
  }) async {
    final safeMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final safeExtension =
        extension.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final path =
        '$safeMobile/${DateTime.now().millisecondsSinceEpoch}.${safeExtension.isEmpty ? 'jpg' : safeExtension}';
    await _db.storage.from('customer-avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );
    return _db.storage.from('customer-avatars').getPublicUrl(path);
  }

  Future<void> updateCustomerAvatar({
    required String mobile,
    required String avatarUrl,
  }) async {
    await _db.rpc('update_customer_avatar', params: {
      'p_mobile': mobile,
      'p_avatar_url': avatarUrl,
    });
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

  Future<CustomerHomeSummary> customerHomeSummary(String mobile) async {
    if (mobile.length != 10) return const CustomerHomeSummary();
    var walletBalance = 0;
    try {
      final customer = await _db
          .from('customers')
          .select('wallet_balance')
          .eq('mobile', mobile)
          .maybeSingle();
      walletBalance =
          (customer?['wallet_balance'] as num?)?.round() ?? walletBalance;
    } catch (_) {
      // Old schema fallback until wallet_balance migration is applied.
    }

    final bookings = await bookingsForMobile(mobile);
    final pendingDues =
        bookings.where((row) => row['status'] == 'confirmed').fold<int>(
              0,
              (total, row) => total + ((row['balance'] as num?)?.round() ?? 0),
            );
    return CustomerHomeSummary(
      walletBalance: walletBalance,
      pendingDues: pendingDues,
    );
  }

  static String _dateOnly(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class CustomerHomeSummary {
  const CustomerHomeSummary({
    this.walletBalance = 0,
    this.pendingDues = 0,
  });

  final int walletBalance;
  final int pendingDues;
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
    required this.razorpayKeyId,
    required this.offerEnabled,
    required this.offerTitle,
    required this.offerDescription,
    required this.offerCode,
    required this.offerDiscountPercent,
    required this.offerMinSubtotal,
  });

  final int perCanRate;
  final int deliveryCharge;
  final int deliveryFreeThreshold;
  final String freeDeliveryVillage;
  final String plantName;
  final String plantPhone;

  /// Razorpay publishable Key ID (safe in the client). The secret stays admin-side.
  final String razorpayKeyId;
  final bool offerEnabled;
  final String offerTitle;
  final String offerDescription;
  final String offerCode;
  final int offerDiscountPercent;
  final int offerMinSubtotal;

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        perCanRate: (m['per_can_rate'] as num).toInt(),
        deliveryCharge: (m['delivery_charge'] as num).toInt(),
        deliveryFreeThreshold: (m['delivery_free_threshold'] as num).toInt(),
        freeDeliveryVillage: m['free_delivery_village'] as String,
        plantName: m['plant_name'] as String,
        plantPhone: m['plant_phone'] as String,
        razorpayKeyId: (m['razorpay_key_id'] as String?) ?? '',
        offerEnabled: (m['offer_enabled'] as bool?) ?? true,
        offerTitle: (m['offer_title'] as String?) ?? 'Weekend Splash Offer',
        offerDescription: (m['offer_description'] as String?) ??
            'Get up to 15% OFF on all orders above Rs.300',
        offerCode: (m['offer_code'] as String?) ?? 'SPLASH15',
        offerDiscountPercent:
            (m['offer_discount_percent'] as num?)?.toInt() ?? 15,
        offerMinSubtotal: (m['offer_min_subtotal'] as num?)?.toInt() ?? 300,
      );
}
