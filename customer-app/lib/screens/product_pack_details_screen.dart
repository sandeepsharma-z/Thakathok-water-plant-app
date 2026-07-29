import 'package:flutter/material.dart';

import '../models/product_pack.dart';
import '../services/plant_config.dart';
import '../services/app_config_service.dart';
import '../theme/app_colors.dart';
import '../widgets/content_image.dart';
import 'bulk_order_form_screen.dart';

class ProductPackDetailsScreen extends StatelessWidget {
  const ProductPackDetailsScreen({super.key, required this.pack});

  final ProductPack pack;

  @override
  Widget build(BuildContext context) {
    final rate = PlantConfig.instance.perCanRate;
    final total = pack.cans == null ? null : pack.cans! * rate;
    final advance = total == null
        ? null
        : (total * AppConfigService.instance.advancePercent / 100).round();
    final freeVillage = PlantConfig.instance.freeDeliveryVillage;
    final threshold = PlantConfig.instance.deliveryFreeThreshold;
    final deliveryCharge = PlantConfig.instance.deliveryCharge;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.liveBrand),
        ),
        title: Text(
          AppConfigService.instance.label('screen_product_details'),
          style: TextStyle(
            color: AppColors.liveBrand,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 118),
        children: [
          Hero(
            tag: pack.image,
            child: Container(
              height: 310,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.hairline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ContentImage(
                  source: pack.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            pack.name,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _Pill(
                icon: Icons.water_drop_rounded,
                label: pack.quantityLabel,
              ),
              const SizedBox(width: 8),
              const _Pill(
                icon: Icons.verified_rounded,
                label: 'Sealed & Safe',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            pack.description,
            style: const TextStyle(
              color: AppColors.body,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          _DetailCard(
            icon: Icons.celebration_outlined,
            title: 'Ideal for',
            body: pack.idealFor,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            icon: Icons.currency_rupee_rounded,
            title: 'Current rate',
            body: '₹$rate per can · controlled by Mahalakshmi Water Plant',
          ),
          const SizedBox(height: 12),
          _DetailCard(
            icon: Icons.local_shipping_outlined,
            title: 'Delivery policy for this pack',
            body: _deliveryMessage(
              pack: pack,
              freeVillage: freeVillage,
              threshold: threshold,
              deliveryCharge: deliveryCharge,
            ),
            highlighted: true,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            icon: Icons.location_on_outlined,
            title: 'Available delivery areas',
            body: PlantConfig.instance.villages.join(', '),
          ),
          if (total != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.offerBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.liveBrand.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                children: [
                  _PriceRow(
                    label: '${pack.cans} cans × ₹$rate',
                    value: '₹$total',
                    bold: true,
                  ),
                  const Divider(height: 24),
                  _PriceRow(
                    label:
                        '${AppConfigService.instance.advancePercent}% advance',
                    value: '₹$advance',
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: 'Balance on delivery',
                    value: '₹${total - advance!}',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BulkOrderFormScreen(
                    initialCans: pack.cans,
                    startWithCustomQuantity: pack.isCustom,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.liveBrand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                pack.isCustom ? 'CHOOSE QUANTITY' : 'BOOK THIS PACK',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _deliveryMessage({
  required ProductPack pack,
  required String freeVillage,
  required int threshold,
  required int deliveryCharge,
}) {
  final villageCount = PlantConfig.instance.villages.length;
  final otherVillages = villageCount > 0 ? villageCount - 1 : 0;
  if (pack.isCustom) {
    return '$freeVillage always has free delivery. In the other $otherVillages villages, '
        'orders below $threshold cans include the delivery charge configured '
        'for the selected village (₹$deliveryCharge global fallback); '
        'orders of $threshold cans or more are delivered free.';
  }
  if (pack.cans! >= threshold) {
    return 'FREE delivery in all $villageCount villages because this pack contains '
        '${pack.cans} cans (minimum free-delivery quantity: $threshold cans).';
  }
  return 'FREE delivery in $freeVillage. For the other $otherVillages villages, '
      'the configured village delivery charge applies (₹$deliveryCharge global fallback) because this pack contains '
      '${pack.cans} cans, which is below the $threshold-can free-delivery limit.';
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.liveBrand),
            SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: AppColors.liveBrand,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.body,
    this.highlighted = false,
  });
  final IconData icon;
  final String title;
  final String body;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.offerBg : Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: highlighted
                ? AppColors.liveBrand.withValues(alpha: 0.2)
                : AppColors.hairline,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.liveBrand, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.body,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppColors.liveBrand : AppColors.body,
              fontSize: 12.5,
              fontWeight: bold || highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.liveBrand : AppColors.textDark,
              fontSize: highlight ? 18 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}
