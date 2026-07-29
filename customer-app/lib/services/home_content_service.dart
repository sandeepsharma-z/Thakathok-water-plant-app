import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_pack.dart';

class HomeBanner {
  const HomeBanner({
    required this.image,
    this.enabled = true,
    this.action = 'none',
  });

  final String image;
  final bool enabled;
  final String action;

  factory HomeBanner.fromMap(Map<String, dynamic> map) => HomeBanner(
        image: '${map['image_url'] ?? ''}',
        enabled: map['enabled'] as bool? ?? true,
        action: '${map['action'] ?? 'none'}',
      );
}

class ShopCategory {
  const ShopCategory({
    required this.name,
    required this.image,
    required this.eventType,
    this.customQuantity = false,
    this.enabled = true,
  });

  final String name;
  final String image;
  final String eventType;
  final bool customQuantity;
  final bool enabled;

  factory ShopCategory.fromMap(Map<String, dynamic> map) => ShopCategory(
        name: '${map['name'] ?? ''}',
        image: '${map['image_url'] ?? ''}',
        eventType: '${map['event_type'] ?? 'Other'}',
        customQuantity: map['custom_quantity'] as bool? ?? false,
        enabled: map['enabled'] as bool? ?? true,
      );
}

class SupportFaq {
  const SupportFaq({required this.question, required this.answer});

  final String question;
  final String answer;

  factory SupportFaq.fromMap(Map<String, dynamic> map) => SupportFaq(
        question: '${map['question'] ?? ''}',
        answer: '${map['answer'] ?? ''}',
      );
}

class SupportContent {
  const SupportContent({
    required this.heading,
    required this.description,
    required this.sectionTitle,
    required this.faqs,
  });

  final String heading;
  final String description;
  final String sectionTitle;
  final List<SupportFaq> faqs;
}

class HomeContentService {
  HomeContentService._();
  static final HomeContentService instance = HomeContentService._();

  SupabaseClient get _db => Supabase.instance.client;

  List<HomeBanner> heroBanners = const [
    HomeBanner(image: 'assets/images/image 17.png'),
    HomeBanner(image: 'assets/images/image 14.png'),
  ];
  List<HomeBanner> promoBanners = const [
    HomeBanner(
      image: 'assets/images/image 12.png',
      action: 'order',
    ),
    HomeBanner(image: 'assets/images/image 25.png'),
  ];
  List<ShopCategory> categories = const [
    ShopCategory(
      name: 'Wedding',
      image: 'assets/images/Products/Jumbo Event Pack.png',
      eventType: 'Wedding',
    ),
    ShopCategory(
      name: 'Birthday',
      image: 'assets/images/Products/Mini Event Pack.png',
      eventType: 'Birthday',
    ),
    ShopCategory(
      name: 'Large Events',
      image: 'assets/images/Products/Large Event Pack.png',
      eventType: 'Other',
    ),
    ShopCategory(
      name: 'Custom Need',
      image: 'assets/images/Products/Custom Event Pack.png',
      eventType: 'Other',
      customQuantity: true,
    ),
  ];
  SupportContent support = const SupportContent(
    heading: 'Need help with an order?',
    description: 'Reach out to {plant_name} directly.',
    sectionTitle: 'Frequently asked',
    faqs: [
      SupportFaq(
        question: 'How do I place a bulk order?',
        answer:
            'Tap "Request Bulk Order" on the home screen, fill in your event details, and pay the 30% advance to confirm.',
      ),
      SupportFaq(
        question: 'Why do I pay 30% advance?',
        answer:
            'The 30% advance confirms your booking and blocks your event date. The remaining 70% is paid as cash on delivery.',
      ),
      SupportFaq(
        question: 'Is the advance refundable?',
        answer:
            'No — the 30% advance is non-refundable. If you cancel, the date is not unblocked.',
      ),
      SupportFaq(
        question: 'When is a delivery charge added?',
        answer:
            'A delivery charge applies only to orders under 25 cans, for every village except Kasara Balkunda (which is free).',
      ),
      SupportFaq(
        question: 'How will I know my booking is confirmed?',
        answer:
            'Online payments confirm instantly. For cash, the plant confirms once the advance is received — you can track it under "My Bookings".',
      ),
    ],
  );

  Future<void> load() async {
    try {
      final row = await _db
          .from('settings')
          .select(
            'home_hero_banners, home_promo_banners, home_products, '
            'home_categories, support_content',
          )
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return;

      final heroes = _maps(row['home_hero_banners'])
          .map(HomeBanner.fromMap)
          .where((item) => item.enabled && item.image.isNotEmpty)
          .toList();
      final promos = _maps(row['home_promo_banners'])
          .map(HomeBanner.fromMap)
          .where((item) => item.image.isNotEmpty)
          .toList();
      final products = _maps(row['home_products'])
          .where((item) => item['enabled'] as bool? ?? true)
          .map(ProductPack.fromMap)
          .where((item) => item.name.isNotEmpty && item.image.isNotEmpty)
          .toList();
      final categoryItems = _maps(row['home_categories'])
          .map(ShopCategory.fromMap)
          .where((item) => item.enabled && item.name.isNotEmpty)
          .toList();
      final supportMap = _map(row['support_content']);
      final faqItems =
          _maps(supportMap['faqs']).map(SupportFaq.fromMap).toList();

      if (heroes.isNotEmpty) heroBanners = heroes;
      promoBanners = promos;
      if (products.isNotEmpty) productPacks = products;
      categories = categoryItems;
      if (supportMap.isNotEmpty) {
        support = SupportContent(
          heading: '${supportMap['heading'] ?? support.heading}',
          description: '${supportMap['description'] ?? support.description}',
          sectionTitle:
              '${supportMap['section_title'] ?? support.sectionTitle}',
          faqs: faqItems.isEmpty ? support.faqs : faqItems,
        );
      }
    } catch (_) {
      // Existing local assets/content stay available when offline.
    }
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
}
