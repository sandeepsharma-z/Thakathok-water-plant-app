import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import 'bulk_order_form_screen.dart';

const double _kPad = 14;

/// Uniform vertical rhythm between the home sections.
const double _kGap = 18;

/// Home screen built to the approved Figma design.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 6),
                    _SearchBar(),
                    SizedBox(height: _kGap),
                    _BannerCarousel(),
                    SizedBox(height: _kGap),
                    _OfferCard(),
                    SizedBox(height: _kGap),
                    _SectionHeader(
                        title: 'Most Popular 🔥', trailing: 'View All →'),
                    SizedBox(height: 12),
                    _PopularSlider(),
                    SizedBox(height: _kGap),
                    _AssetBanner('assets/images/image 12.png', 419 / 207),
                    SizedBox(height: _kGap),
                    _ShopByNeed(),
                    SizedBox(height: _kGap),
                    _AssetBanner('assets/images/image 25.png', 428 / 109),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _Footer(),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 8, _kPad, 6),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Brand logo — truly centred on the screen
            const BrandLogo(size: 44),
            // Location — pinned left
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_on, color: AppColors.brand, size: 17),
                  SizedBox(width: 2),
                  Text('Noida,UP',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 17, color: Colors.black),
                ],
              ),
            ),
            // Bell — pinned right
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset('assets/images/Vector.png', height: 21),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _focus.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show the animated placeholder only while empty and unfocused.
    final showHint = _controller.text.isEmpty && !_focus.hasFocus;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focus,
                    cursorColor: AppColors.brand,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textDark),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.hairline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.brand, width: 1.3),
                      ),
                    ),
                  ),
                  if (showHint)
                    const Positioned(
                      left: 16,
                      child: IgnorePointer(child: _TypingHint()),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _SearchButton(),
        ],
      ),
    );
  }
}

/// The dark-blue search button with slow bubbles rising inside it.
class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 46,
        width: 46,
        color: AppColors.brand, // solid dark bluish
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: _RisingBubbles()),
            Icon(Icons.search, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Small white bubbles that rise slowly and fade — a subtle "water" motion
/// behind the search icon.
class _RisingBubbles extends StatefulWidget {
  const _RisingBubbles();

  @override
  State<_RisingBubbles> createState() => _RisingBubblesState();
}

class _RisingBubblesState extends State<_RisingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _bubbles = List.generate(
      7,
      (_) => _Bubble(
        x: rnd.nextDouble(),
        radius: 1.1 + rnd.nextDouble() * 2.1,
        phase: rnd.nextDouble(),
        speed: 0.55 + rnd.nextDouble() * 0.5,
        drift: (rnd.nextDouble() - 0.5) * 0.12,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _BubblePainter(_bubbles, _controller.value),
      ),
    );
  }
}

class _Bubble {
  const _Bubble({
    required this.x,
    required this.radius,
    required this.phase,
    required this.speed,
    required this.drift,
  });

  final double x; // 0..1 horizontal position
  final double radius;
  final double phase; // 0..1 starting offset
  final double speed; // rise speed multiplier
  final double drift; // horizontal sway amount
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.bubbles, this.t);
  final List<_Bubble> bubbles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final b in bubbles) {
      final p = ((t * b.speed) + b.phase) % 1.0; // 0 (bottom) → 1 (top)
      final y = size.height * (1 - p);
      final x = size.width *
          (b.x + b.drift * math.sin(p * math.pi * 2)).clamp(0.05, 0.95);
      final alpha = (0.38 * math.sin(p * math.pi)).clamp(0.0, 0.38);
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.t != t;
}

/// Placeholder that types itself out, holds, deletes and moves to the
/// next phrase — with a blinking caret.
class _TypingHint extends StatefulWidget {
  const _TypingHint();

  @override
  State<_TypingHint> createState() => _TypingHintState();
}

class _TypingHintState extends State<_TypingHint> {
  static const _phrases = [
    'Search  for water products',
    'Search  for Jar Water 20L',
    'Search  for Water Bottle 1.5L',
    'Search  for Jar Water 10L',
  ];

  int _phrase = 0;
  int _chars = 0;
  bool _deleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final full = _phrases[_phrase];
    final Duration delay;
    if (!_deleting) {
      delay = _chars < full.length
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 2200);
    } else {
      delay = _chars > 0
          ? const Duration(milliseconds: 55)
          : const Duration(milliseconds: 450);
    }

    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        final f = _phrases[_phrase];
        if (!_deleting) {
          if (_chars < f.length) {
            _chars++;
          } else {
            _deleting = true;
          }
        } else {
          if (_chars > 0) {
            _chars--;
          } else {
            _deleting = false;
            _phrase = (_phrase + 1) % _phrases.length;
          }
        }
      });
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            _phrases[_phrase].substring(0, _chars),
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: const TextStyle(color: AppColors.hint, fontSize: 13),
          ),
        ),
        const _Caret(),
      ],
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 1.5,
        height: 15,
        margin: const EdgeInsets.only(left: 2),
        color: AppColors.hint,
      ),
    );
  }
}

// ── Banner carousel ───────────────────────────────────────────────────
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  static const _banners = [
    'assets/images/image 17.png',
    'assets/images/image 14.png',
  ];

  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % _banners.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPad),
          child: AspectRatio(
            aspectRatio: 428 / 202,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PageView.builder(
                controller: _controller,
                itemCount: _banners.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) =>
                    Image.asset(_banners[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 8,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.brand : const Color(0xFFBFD8F5),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Weekend splash offer ──────────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  const _OfferCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.offerBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Image.asset('assets/images/image 13.png', width: 74),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Weekend  Splash Offer',
                      style: TextStyle(
                          color: AppColors.heading,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  SizedBox(height: 3),
                  Text('Get up to 15% OFF on all orders above Rs.300',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.body, fontSize: 9)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _DashedCodeBox(),
          ],
        ),
      ),
    );
  }
}

class _DashedCodeBox extends StatelessWidget {
  const _DashedCodeBox();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Use Code',
                style: TextStyle(fontSize: 8.5, color: AppColors.body)),
            Text('SPLASH15',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading)),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dashed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(8)));

    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = math.min(dist + dash, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Section header ────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
          if (trailing != null)
            Text(trailing!,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brand)),
        ],
      ),
    );
  }
}

// ── Most popular slider ───────────────────────────────────────────────
class _PopularSlider extends StatelessWidget {
  const _PopularSlider();

  @override
  Widget build(BuildContext context) {
    const products = [
      ('Jar Water 20L', 'Rs. 150', 'assets/images/Jar Water 20L.png'),
      ('Water Bottle 1.5L', 'Rs. 35', 'assets/images/Water Bottle 1.5L.png'),
      (
        'Water Bottle 1.5L Pack (4)',
        'Rs. 120',
        'assets/images/Water Bottle 1.5L Pack (4).png'
      ),
      ('Jar Water 10L', 'Rs. 100', 'assets/images/Jar Water 10L.png'),
    ];
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _kPad),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _ProductCard(
          name: products[i].$1,
          price: products[i].$2,
          image: products[i].$3,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(
      {required this.name, required this.price, required this.image});
  final String name;
  final String price;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Image.asset(image, height: 100, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            width: double.infinity,
            child: Text(name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand)),
              SvgPicture.asset('assets/images/add-circle-svgrepo-com.svg',
                  width: 26, height: 26),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Full-bleed asset banner ───────────────────────────────────────────
class _AssetBanner extends StatelessWidget {
  const _AssetBanner(this.path, this.ratio);
  final String path;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: ratio,
          child: Image.asset(path, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// ── Shop by need ──────────────────────────────────────────────────────
class _ShopByNeed extends StatelessWidget {
  const _ShopByNeed();

  @override
  Widget build(BuildContext context) {
    const cats = [
      ('Jar 20L', 'assets/images/jar 20.png'),
      ('Jar 10L', 'assets/images/jar 10.png'),
      ('Bottle 1.5L', 'assets/images/Bottle 1.5L.png'),
      ('Jar 5L', 'assets/images/Jar 5L.png'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPad),
          child: Row(
            children: [
              const Text('Shop By Need',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
              const SizedBox(width: 6),
              Image.asset('assets/images/image 19.png', height: 19),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final c in cats)
                Container(
                  height: 88,
                  width: 88,
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tint),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(c.$2, height: 40),
                      const SizedBox(height: 5),
                      Text(c.$1,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────
class _Footer extends StatefulWidget {
  const _Footer();

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    // Gently swells past the circle's edge, then eases back — never tiny.
    _pulse = Tween<double>(begin: 1.55, end: 2.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          height: 82,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.tint,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(47)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                          child: _NavItem(Icons.home_filled, 'Home',
                              active: true)),
                      Expanded(
                          child: _NavItem(Icons.add_shopping_cart, 'Cart')),
                      SizedBox(width: 90),
                      Expanded(
                          child: _NavItem(
                              Icons.account_balance_wallet_outlined,
                              'Wallet')),
                      Expanded(
                          child: _NavItem(
                              Icons.person_outline_rounded, 'Profile')),
                    ],
                  ),
                ),
              ),
              // Centre "Products" button — droplet swells out of the circle
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BulkOrderFormScreen(),
                    ),
                  ),
                  child: Container(
                  height: 82,
                  width: 82,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 2,
                        child: ScaleTransition(
                          scale: _pulse,
                          child: Image.asset(
                              'assets/images/Footer Droplet.png',
                              height: 30),
                        ),
                      ),
                      const Positioned(
                        bottom: 16,
                        child: Text('Products',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.icon, this.label, {this.active = false});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand : const Color(0xFF5B6472);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}
