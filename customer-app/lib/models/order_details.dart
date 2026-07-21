import 'package:flutter/material.dart';

/// Immutable snapshot of a bulk-order enquiry, carried from the form
/// through the payment and confirmation screens.
class OrderDetails {
  const OrderDetails({
    required this.eventType,
    required this.cans,
    required this.perCanRate,
    required this.village,
    required this.mobile,
    required this.address,
    required this.eventDate,
    required this.eventTime,
    required this.deliveryCharge,
  });

  final String eventType;
  final int cans;
  final int perCanRate;
  final String village;
  final String mobile;
  final String address;
  final DateTime eventDate;
  final TimeOfDay eventTime;

  /// Delivery charge already resolved by the form (0 when not applicable).
  final int deliveryCharge;

  int get subtotal => cans * perCanRate;
  int get grandTotal => subtotal + deliveryCharge;
  int get advance => (grandTotal * 0.30).round();
  int get balance => grandTotal - advance;

  /// Context-free "10:30 AM" style label (for storage / display without a
  /// BuildContext).
  String get eventTimeLabel {
    final h = eventTime.hour;
    final m = eventTime.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  /// Booking id in the client's observed format, e.g. THK100MAY20.
  String get bookingId {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    final mon = months[eventDate.month - 1];
    return 'THK$cans$mon${eventDate.day}';
  }
}
