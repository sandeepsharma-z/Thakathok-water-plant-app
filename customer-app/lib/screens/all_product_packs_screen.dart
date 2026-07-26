import 'package:flutter/material.dart';

import '../models/product_pack.dart';
import '../theme/app_colors.dart';
import 'product_pack_details_screen.dart';

class AllProductPacksScreen extends StatelessWidget {
  const AllProductPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brand),
        ),
        title: const Text(
          'All Event Packs',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 800
              ? 4
              : constraints.maxWidth >= 560
                  ? 3
                  : 2;
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose the right pack',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Fresh, sealed water cans for every event size.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                sliver: SliverGrid.builder(
                  itemCount: productPacks.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) =>
                      _PackGridCard(pack: productPacks[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PackGridCard extends StatelessWidget {
  const _PackGridCard({required this.pack});

  final ProductPack pack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductPackDetailsScreen(pack: pack),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.hairline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0B5EC7),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: const Color(0xFFF0F7FF),
                  child: Hero(
                    tag: pack.image,
                    child: Image.asset(pack.image, fit: BoxFit.contain),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.water_drop_rounded,
                          size: 15,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pack.quantityLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.brand,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
