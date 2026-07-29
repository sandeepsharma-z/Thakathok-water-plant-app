import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_details.dart';
import 'customer_api_service.dart';

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
          .select(
            'id,per_can_rate,delivery_charge,delivery_free_threshold,'
            'free_delivery_village,plant_name,plant_phone,razorpay_key_id,'
            'offer_enabled,offer_title,offer_description,offer_code,'
            'offer_discount_percent,offer_min_subtotal',
          )
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return null;
      return AppSettings.fromMap(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> fetchVillages() async {
    try {
      final rows = await _db
          .from('villages')
          .select('name')
          .eq('enabled', true)
          .order('sort_order');
      return rows
          .map((row) => (row['name'] as String?)?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, int?>> fetchVillageDeliveryCharges() async {
    try {
      final rows = await _db
          .from('villages')
          .select('name,delivery_charge')
          .eq('enabled', true)
          .order('sort_order');
      return {
        for (final row in rows)
          if ('${row['name']}'.trim().isNotEmpty)
            '${row['name']}'.trim(): (row['delivery_charge'] as num?)?.round(),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<CustomerOrderEligibility> customerOrderEligibility(
    String mobile,
  ) async {
    try {
      final data = await CustomerApiService.instance.call('eligibility');
      final result = Map<String, dynamic>.from(data['eligibility'] as Map);
      return CustomerOrderEligibility(
        eligible: result['eligible'] == true,
        reason: '${result['reason'] ?? ''}',
        pendingDues: (result['pending_dues'] as num?)?.toInt() ?? 0,
        pendingCans: (result['pending_cans'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const CustomerOrderEligibility(
        eligible: false,
        reason: 'Could not verify your order eligibility. Please try again.',
      );
    }
  }

  Future<Set<String>> unavailableDates({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _db
        .from('blocked_dates')
        .select('blocked_date')
        .gte('blocked_date', _dateOnly(from))
        .lte('blocked_date', _dateOnly(to));
    return (rows as List)
        .map((row) => '${(row as Map)['blocked_date']}')
        .toSet();
  }

  Future<bool> isDateAvailable(DateTime date) async {
    final row = await _db
        .from('blocked_dates')
        .select('blocked_date')
        .eq('blocked_date', _dateOnly(date))
        .limit(1)
        .maybeSingle();
    return row == null;
  }

  /// Persist a booking. Returns the created row's booking_code, or throws.
  Future<String> createBooking(
    OrderDetails order, {
    required String paymentMethod, // 'online' | 'cash'
    required String status, // 'confirmed' | 'pending'
  }) async {
    final payload = {
      'name': order.name,
      'event_type': order.eventType,
      'cans': order.cans,
      'village': order.village,
      'address': order.address,
      'event_date': _dateOnly(order.eventDate),
      'event_time': order.eventTimeLabel,
      'offer_code': order.offerCode,
      'expected_advance': order.advance,
    };
    if (paymentMethod != 'cash' || status != 'pending') {
      throw StateError('This booking must be finalized by secure payment.');
    }
    final result =
        await CustomerApiService.instance.call('cash_booking', payload);
    return '${result['booking_code']}';
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
    await CustomerApiService.instance.call('update_profile', {
      'name': name,
      'village': village,
      'address': address,
    });
  }

  /// Upload a customer-selected avatar and return its public URL.
  Future<String> uploadAvatar({
    required String mobile,
    required Uint8List bytes,
    required String extension,
  }) async {
    return CustomerApiService.instance.uploadAvatar(bytes, extension);
  }

  Future<void> updateCustomerAvatar({
    required String mobile,
    required String avatarUrl,
  }) async {
    if (avatarUrl.isEmpty) {
      await CustomerApiService.instance.call('remove_avatar');
    }
  }

  /// Bookings for a given mobile number, newest first.
  Future<List<Map<String, dynamic>>> bookingsForMobile(String mobile) async {
    final result = await CustomerApiService.instance.call('bookings');
    return List<Map<String, dynamic>>.from(result['bookings'] as List);
  }

  Future<CustomerHomeSummary> customerHomeSummary(String mobile) async {
    if (mobile.length != 10) return const CustomerHomeSummary();
    final result = await CustomerApiService.instance.call('summary');
    return CustomerHomeSummary(
      walletBalance: (result['wallet_balance'] as num?)?.toInt() ?? 0,
      pendingDues: (result['pending_dues'] as num?)?.toInt() ?? 0,
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

class CustomerOrderEligibility {
  const CustomerOrderEligibility({
    required this.eligible,
    this.reason = '',
    this.pendingDues = 0,
    this.pendingCans = 0,
  });

  final bool eligible;
  final String reason;
  final int pendingDues;
  final int pendingCans;
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
