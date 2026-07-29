import 'booking_service.dart';

/// Live plant settings (rate, delivery, contact) loaded once from Supabase at
/// app start. The admin edits these from the panel — the app never hard-codes
/// them. Defaults below are only a fallback if the network fetch fails.
class PlantConfig {
  PlantConfig._();
  static final PlantConfig instance = PlantConfig._();

  int perCanRate = 30;
  int deliveryCharge = 10;
  int deliveryFreeThreshold = 25;
  String freeDeliveryVillage = 'Kasara Balkunda';
  String plantName = 'Mahalakshmi Water Plant';
  String plantPhone = '8080739807';
  List<String> villages = const [
    'Kasara Balkunda',
    'Sardarwadi',
    'Tambala',
    'Chilwantwadi',
    'Pirupatelvadi',
    'Devi Hallali',
    'Mamdapur',
  ];
  Map<String, int?> villageDeliveryCharges = const {};

  int deliveryChargeForVillage(String village) =>
      villageDeliveryCharges[village] ?? deliveryCharge;

  /// Razorpay publishable Key ID. Empty until the owner adds it in the panel —
  /// the payment screen falls back to cash-only when this is empty.
  String razorpayKeyId = '';
  bool offerEnabled = true;
  String offerTitle = 'Weekend Splash Offer';
  String offerDescription = 'Get up to 15% OFF on all orders above Rs.300';
  String offerCode = 'SPLASH15';
  int offerDiscountPercent = 15;
  int offerMinSubtotal = 300;

  bool loaded = false;

  /// Pull the latest settings row. Safe to call more than once.
  Future<void> load() async {
    final results = await Future.wait([
      BookingService.instance.fetchSettings(),
      BookingService.instance.fetchVillages(),
      BookingService.instance.fetchVillageDeliveryCharges(),
    ]);
    final s = results[0] as AppSettings?;
    final liveVillages = results[1] as List<String>;
    final liveVillageCharges = results[2] as Map<String, int?>;
    if (liveVillages.isNotEmpty) villages = liveVillages;
    if (liveVillageCharges.isNotEmpty) {
      villageDeliveryCharges = liveVillageCharges;
    }
    if (s == null) return;
    perCanRate = s.perCanRate;
    deliveryCharge = s.deliveryCharge;
    deliveryFreeThreshold = s.deliveryFreeThreshold;
    freeDeliveryVillage = s.freeDeliveryVillage;
    plantName = s.plantName;
    plantPhone = s.plantPhone;
    razorpayKeyId = s.razorpayKeyId;
    offerEnabled = s.offerEnabled;
    offerTitle = s.offerTitle;
    offerDescription = s.offerDescription;
    offerCode = s.offerCode;
    offerDiscountPercent = s.offerDiscountPercent;
    offerMinSubtotal = s.offerMinSubtotal;
    loaded = true;
  }
}

/// Normalise a stored number to international form (digits only, with the
/// India country code). "8080739807" → "918080739807". Already-prefixed or
/// longer numbers are returned as their digits unchanged.
String intlPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return '91$digits';
  return digits;
}
