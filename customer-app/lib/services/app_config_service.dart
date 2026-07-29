import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigService {
  AppConfigService._();
  static final instance = AppConfigService._();

  int advancePercent = 30;
  List<String> eventTypes = const ['Wedding', 'Birthday', 'Other'];
  List<int> quantityOptions = const [20, 50, 100, 150];
  String popularHeading = 'Most Popular 🔥';
  String shopHeading = 'Shop By Need';
  String greetingTagline = 'Stay Hydrated, Stay Healthy 💧';
  List<String> searchPhrases = const [
    'Search for water products',
    'Search for Jar Water 20L',
    'Search for Water Bottle 1.5L',
    'Search for Jar Water 10L',
  ];
  List<Map<String, String>> quickActions = const [
    {'title': 'Order Water', 'subtitle': 'New order'},
    {'title': 'Repeat Order', 'subtitle': 'Quick reorder'},
    {'title': 'My Orders', 'subtitle': 'Track & history'},
    {'title': 'My Wallet', 'subtitle': 'Balance & history'},
    {'title': 'Support', 'subtitle': 'Help & support'},
  ];
  List<String> trustItems = const [
    '100% Pure & Safe',
    'On-Time Delivery',
    'Easy Returns',
    'Best Price Guaranteed',
  ];

  String brandName = 'ThakaThok';
  String plantDisplayName = 'Mahalakshmi Water Plant';
  String logoUrl = 'assets/images/logo.png';
  Color primaryColor = const Color(0xFF004FDA);
  Color accentColor = const Color(0xFF37B6FF);

  Map<String, String> labels = const {
    'bottom_home': 'Home',
    'bottom_bookings': 'My Bookings',
    'bottom_products': 'Products',
    'bottom_wallet': 'Wallet',
    'bottom_profile': 'Profile',
    'drawer_profile': 'My Profile',
    'drawer_order': 'Request Bulk Order',
    'drawer_bookings': 'My Bookings',
    'drawer_wallet': 'Wallet',
    'drawer_support': 'Help & Support',
    'drawer_logout': 'Logout',
    'booking_form_title': 'Bulk Order Enquiry',
    'request_order_button': 'REQUEST BULK ORDER',
    'payment_title': 'Payment',
    'payment_summary_heading': 'Order Summary',
    'booking_confirmed_title': 'Booking Confirmed!',
    'booking_pending_title': 'Booking Pending',
    'back_home_button': 'BACK TO HOME',
    'screen_my_bookings': 'My Bookings',
    'screen_wallet': 'My Wallet',
    'screen_profile': 'My Profile',
    'screen_notifications': 'Notifications',
    'screen_support': 'Help & Support',
    'screen_all_products': 'All Product Packs',
    'screen_product_details': 'Pack Details',
    'screen_search': 'Search Products',
    'login_heading': 'Welcome back',
    'register_heading': 'Create your account',
    'login_subtitle': 'Login with your mobile number and password.',
    'register_subtitle':
        'Sign up once with your mobile number — no OTP needed.',
    'full_name_label': 'Full Name',
    'mobile_label': 'Mobile Number',
    'password_label': 'Password',
    'login_button': 'LOGIN',
    'register_button': 'CREATE ACCOUNT',
    'have_account_text': 'Already have an account?',
    'no_account_text': "Don't have an account?",
    'login_link': 'Login',
    'register_link': 'Create ID',
    'name_required_error': 'Enter your name',
    'mobile_invalid_error': 'Enter a valid 10-digit mobile number',
    'password_invalid_error': 'Password must be at least 6 characters',
    'account_exists_error': 'An account already exists for this mobile number.',
    'invalid_login_error': 'Mobile number or password is incorrect.',
    'connection_error':
        'Could not continue. Check your connection and try again.',
    'date_required_error': 'Please select event date & time',
    'booking_save_error': 'Could not save booking. Please try again.',
    'date_unavailable_error':
        'This event date is no longer available. Please choose another date.',
  };
  Map<String, String> payment = const {
    'advance_warning': 'Advance is NON-REFUNDABLE',
    'cash_heading': 'Cash Payment Selected',
    'cash_step_1': 'Note down Booking ID:',
    'cash_step_2': 'Pay {advance} cash to {plant_name} within 24 hours',
    'cash_step_3': 'Call / WhatsApp {plant_phone} with your Booking ID',
    'cash_notice':
        'Booking will be CONFIRMED only after cash is received. Date is not blocked until the advance is paid.',
    'cash_button': 'I WILL PAY CASH',
    'confirmed_message': 'Your advance is received and the date is blocked.',
    'pending_message':
        'Pay the cash advance to confirm. Date is not blocked yet.',
    'non_refundable_note':
        'Note: Advance paid is non-refundable as per policy.',
  };

  int get balancePercent => 100 - advancePercent;
  String label(String key) => labels[key] ?? key;
  String paymentText(String key) => payment[key] ?? key;

  Future<void> load() async {
    try {
      final row = await Supabase.instance.client
          .from('settings')
          .select(
            'advance_percent,booking_event_types,booking_quantity_options,'
            'home_ui_content,app_branding,app_labels,payment_content',
          )
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return;
      advancePercent = (row['advance_percent'] as num?)?.toInt() ?? 30;
      eventTypes = _strings(row['booking_event_types'], eventTypes);
      quantityOptions = _ints(row['booking_quantity_options'], quantityOptions);
      final home = _map(row['home_ui_content']);
      popularHeading = '${home['popular_heading'] ?? popularHeading}';
      shopHeading = '${home['shop_heading'] ?? shopHeading}';
      greetingTagline = '${home['greeting_tagline'] ?? greetingTagline}';
      searchPhrases = _strings(home['search_phrases'], searchPhrases);
      final quick = _maps(home['quick_actions']);
      if (quick.length >= 5) {
        quickActions = quick
            .take(5)
            .map((item) => {
                  'title': '${item['title'] ?? ''}',
                  'subtitle': '${item['subtitle'] ?? ''}',
                })
            .toList();
      }
      final trust = _maps(home['trust_items'])
          .map((item) => '${item['title'] ?? ''}')
          .where((item) => item.isNotEmpty)
          .toList();
      if (trust.length >= 4) trustItems = trust.take(4).toList();

      final branding = _map(row['app_branding']);
      brandName = '${branding['brand_name'] ?? brandName}';
      plantDisplayName =
          '${branding['plant_display_name'] ?? plantDisplayName}';
      logoUrl = '${branding['logo_url'] ?? logoUrl}';
      primaryColor = _color('${branding['primary_color'] ?? ''}', primaryColor);
      accentColor = _color('${branding['accent_color'] ?? ''}', accentColor);
      labels = {...labels, ..._stringMap(row['app_labels'])};
      payment = {...payment, ..._stringMap(row['payment_content'])};
    } catch (_) {
      // Keep built-in defaults while offline.
    }
  }

  String interpolate(String value, Map<String, String> replacements) {
    var result = value;
    for (final entry in replacements.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  static Color _color(String value, Color fallback) {
    final hex = value.replaceFirst('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null || hex.length != 6
        ? fallback
        : Color(0xFF000000 | parsed);
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
      : const [];
  static Map<String, String> _stringMap(dynamic value) =>
      _map(value).map((key, value) => MapEntry(key, '$value'));
  static List<String> _strings(dynamic value, List<String> fallback) {
    if (value is! List) return fallback;
    final values =
        value.map((item) => '$item').where((item) => item.isNotEmpty).toList();
    return values.isEmpty ? fallback : values;
  }

  static List<int> _ints(dynamic value, List<int> fallback) {
    if (value is! List) return fallback;
    final values = value
        .map((item) => item is num ? item.toInt() : int.tryParse('$item'))
        .whereType<int>()
        .where((item) => item > 0)
        .toList();
    return values.isEmpty ? fallback : values;
  }
}
