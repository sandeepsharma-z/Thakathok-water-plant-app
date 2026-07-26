import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thakathok/models/order_details.dart';

void main() {
  final baseOrder = OrderDetails(
    eventType: 'Wedding',
    cans: 20,
    perCanRate: 30,
    village: 'Sardarwadi',
    mobile: '9999999999',
    address: 'Test Hall',
    eventDate: DateTime(2026, 8, 1),
    eventTime: const TimeOfDay(hour: 10, minute: 30),
    deliveryCharge: 10,
  );

  test('totals stay unchanged without an offer', () {
    expect(baseOrder.subtotal, 600);
    expect(baseOrder.grandTotal, 610);
    expect(baseOrder.advance, 183);
    expect(baseOrder.balance, 427);
  });

  test('offer discounts subtotal but not delivery charge', () {
    final discounted = baseOrder.withOffer(
      code: 'SPLASH15',
      percent: 15,
      discount: 90,
    );

    expect(discounted.grandTotal, 520);
    expect(discounted.advance, 156);
    expect(discounted.balance, 364);
    expect(discounted.hasDiscount, isTrue);
  });

  test('removing an offer restores original totals', () {
    final restored = baseOrder
        .withOffer(code: 'SPLASH15', percent: 15, discount: 90)
        .withoutOffer();

    expect(restored.offerCode, isNull);
    expect(restored.discountAmount, 0);
    expect(restored.grandTotal, baseOrder.grandTotal);
  });
}
