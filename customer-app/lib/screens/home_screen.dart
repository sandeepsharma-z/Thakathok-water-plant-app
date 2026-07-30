import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/product_pack.dart';
import '../services/booking_service.dart';
import '../services/home_content_service.dart';
import '../services/plant_config.dart';
import '../services/profile_store.dart';
import '../services/notification_store.dart';
import '../services/auth_service.dart';
import '../services/app_config_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../widgets/content_image.dart';
import 'all_product_packs_screen.dart';
import 'bulk_order_form_screen.dart';
import 'help_support_screen.dart';
import 'my_bookings_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'product_pack_details_screen.dart';
import 'product_search_screen.dart';
import 'wallet_screen.dart';

const double _kPad = 14;

/// Uniform vertical rhythm between the home sections.
const double _kGap = 18;

/// Home screen built to the approved Figma design.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  CustomerProfile _profile = const CustomerProfile();
  RefreshIndicatorStatus? _refreshStatus;
  late final AnimationController _refreshController;
  bool _notificationsRead = false;
  int _notificationCount = 0;
  CustomerHomeSummary _summary = const CustomerHomeSummary();
  bool _bannerPrecacheStarted = false;
  Timer? _notificationPoller;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _loadProfile();
    _loadHomeData();
    _notificationPoller = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadNotificationState(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bannerPrecacheStarted) {
      _bannerPrecacheStarted = true;
      _precacheHeroBanners();
    }
  }

  void _precacheHeroBanners() {
    for (final banner in HomeContentService.instance.heroBanners) {
      if (banner.enabled &&
          (banner.image.startsWith('http://') ||
              banner.image.startsWith('https://'))) {
        unawaited(precacheImage(NetworkImage(banner.image), context));
      }
    }
  }

  @override
  void dispose() {
    _notificationPoller?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileStore.instance.load();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _loadNotificationState() async {
    final mobile = await AuthService.instance.currentMobile() ?? '';
    final unread = await NotificationStore.instance.unreadCount(mobile);
    if (mounted) {
      setState(() {
        _notificationsRead = unread == 0;
        _notificationCount = unread;
      });
    }
  }

  Future<void> _loadHomeData() async {
    await Future.wait([
      _loadNotificationState(),
      _loadFinancialSummary(),
    ]);
  }

  Future<void> _loadFinancialSummary() async {
    final mobile = await AuthService.instance.currentMobile() ?? '';
    try {
      final summary = await BookingService.instance.customerHomeSummary(mobile);
      if (mounted) setState(() => _summary = summary);
    } catch (_) {
      // Keep the last valid values when the network is unavailable.
    }
  }

  Future<void> _openNotifications() async {
    final mobile = await AuthService.instance.currentMobile() ?? '';
    await NotificationStore.instance.markAllRead(mobile);
    if (mounted) setState(() => _notificationsRead = true);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    await _loadNotificationState();
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    await _loadProfile();
  }

  Future<void> _openWallet() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletScreen(mobile: _profile.mobile),
      ),
    );
    await _loadFinancialSummary();
  }

  Future<void> _refreshHome() async {
    final started = DateTime.now();
    await Future.wait([
      PlantConfig.instance.load(),
      HomeContentService.instance.load(),
      AppConfigService.instance.load(),
      ProfileStore.instance.load().then((profile) {
        if (mounted) setState(() => _profile = profile);
      }),
      _loadHomeData(),
    ]);
    if (mounted) _precacheHeroBanners();
    final elapsed = DateTime.now().difference(started);
    if (elapsed < const Duration(milliseconds: 700)) {
      await Future<void>.delayed(
        const Duration(milliseconds: 700) - elapsed,
      );
    }
    if (mounted) setState(() {});
  }

  void _onRefreshStatus(RefreshIndicatorStatus? status) {
    if (!mounted) return;
    setState(() => _refreshStatus = status);
    if (status == RefreshIndicatorStatus.drag ||
        status == RefreshIndicatorStatus.armed ||
        status == RefreshIndicatorStatus.snap ||
        status == RefreshIndicatorStatus.refresh) {
      _refreshController.repeat();
    } else {
      _refreshController.stop();
      _refreshController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _AppDrawer(profile: _profile, onOpenProfile: _openProfile),
      body: Stack(
        children: [
          // Soft blue glow behind the top of the screen, fading into white.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.75),
                    radius: 1.15,
                    colors: [
                      Color(0xFFC9E3FF),
                      Color(0xFFE4F1FF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  profile: _profile,
                  unreadCount: _notificationsRead ? 0 : _notificationCount,
                  onOpenNotifications: _openNotifications,
                  onOpenProfile: _openProfile,
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      RefreshIndicator.noSpinner(
                        onRefresh: _refreshHome,
                        onStatusChange: _onRefreshStatus,
                        notificationPredicate: (notification) =>
                            notification.depth == 0,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Greeting(profile: _profile),
                              const SizedBox(height: 12),
                              const _SearchBar(),
                              const SizedBox(height: _kGap),
                              _BannerCarousel(
                                banners:
                                    HomeContentService.instance.heroBanners,
                              ),
                              const SizedBox(height: 12),
                              _QuickActions(
                                profile: _profile,
                                onOpenWallet: _openWallet,
                              ),
                              const SizedBox(height: _kGap),
                              _WalletDuesRow(
                                walletBalance: _summary.walletBalance,
                                pendingDues: _summary.pendingDues,
                                mobile: _profile.mobile,
                                onOpenWallet: _openWallet,
                              ),
                              if (PlantConfig.instance.offerEnabled) ...[
                                const SizedBox(height: _kGap),
                                _OfferCard(
                                  title: PlantConfig.instance.offerTitle,
                                  description:
                                      PlantConfig.instance.offerDescription,
                                  code: PlantConfig.instance.offerCode,
                                ),
                              ],
                              const SizedBox(height: _kGap),
                              _SectionHeader(
                                title: AppConfigService.instance.popularHeading,
                                trailing: 'View All',
                                onTrailingTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AllProductPacksScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const _PopularSlider(),
                              const SizedBox(height: _kGap),
                              if (HomeContentService
                                      .instance.promoBanners.isNotEmpty &&
                                  HomeContentService
                                      .instance.promoBanners.first.enabled)
                                _DynamicPromoBanner(
                                  banner: HomeContentService
                                      .instance.promoBanners.first,
                                ),
                              const SizedBox(height: _kGap),
                              _ShopByNeed(
                                categories:
                                    HomeContentService.instance.categories,
                              ),
                              const SizedBox(height: _kGap),
                              if (HomeContentService
                                          .instance.promoBanners.length >
                                      1 &&
                                  HomeContentService
                                      .instance.promoBanners[1].enabled)
                                _DynamicPromoBanner(
                                  banner: HomeContentService
                                      .instance.promoBanners[1],
                                ),
                              const SizedBox(height: _kGap),
                              const _TrustStrip(),
                            ],
                          ),
                        ),
                      ),
                      _WaterRefreshBadge(
                        status: _refreshStatus,
                        controller: _refreshController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _Footer(
        onOpenProfile: _openProfile,
        onOpenWallet: _openWallet,
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────
class _WaterRefreshBadge extends StatelessWidget {
  const _WaterRefreshBadge({
    required this.status,
    required this.controller,
  });

  final RefreshIndicatorStatus? status;
  final AnimationController controller;

  bool get _visible =>
      status == RefreshIndicatorStatus.drag ||
      status == RefreshIndicatorStatus.armed ||
      status == RefreshIndicatorStatus.snap ||
      status == RefreshIndicatorStatus.refresh;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      top: _visible ? 10 : -48,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: _visible ? 1 : 0,
          child: RotationTransition(
            turns: controller,
            child: Container(
              height: 42,
              width: 42,
              padding: EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.liveBrand.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: const _DottedLoaderPainter(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DottedLoaderPainter extends CustomPainter {
  const _DottedLoaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const dots = 12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2.5;

    for (var i = 0; i < dots; i++) {
      final angle = (math.pi * 2 * i / dots) - math.pi / 2;
      final opacity = 0.22 + (0.78 * (i + 1) / dots);
      final dotRadius = 1.5 + (0.8 * (i + 1) / dots);
      final paint = Paint()
        ..color = AppColors.liveBrand.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
        dotRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.profile,
    required this.unreadCount,
    required this.onOpenNotifications,
    required this.onOpenProfile,
  });
  final CustomerProfile profile;
  final int unreadCount;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 8, _kPad, 6),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Brand logo — truly centred on the screen.
            const BrandLogo(size: 44),
            // Menu — pinned left. Nudged out so the glyph's stroke lines up
            // with the greeting text below it, not the icon's padded box.
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-6, 0),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.menu_rounded,
                      color: AppColors.textDark, size: 26),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            // Notifications + profile — pinned right
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onOpenNotifications,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.asset('assets/images/Vector.png', height: 21),
                          if (unreadCount > 0)
                            Positioned(
                              right: -4,
                              top: -5,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE23D3D),
                                  shape: BoxShape.circle,
                                ),
                                child: Text('$unreadCount',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        height: 1,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: onOpenProfile,
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.hairline),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: profile.avatarUrl.isEmpty
                          ? Icon(Icons.person_rounded,
                              color: AppColors.liveBrand, size: 21)
                          : Image.network(
                              profile.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person_rounded,
                                color: AppColors.liveBrand,
                                size: 21,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notifications ─────────────────────────────────────────────────────
/// App notifications. Static for now — booking/payment updates will be wired
/// to Supabase once phone-OTP auth lands.
const List<({IconData icon, String title, String body})> _kNotifications = [
  (
    icon: Icons.water_drop_rounded,
    title: 'Welcome to ThakaThok 💧',
    body: 'Book bulk water for your weddings & events in just a few taps.',
  ),
  (
    icon: Icons.verified_rounded,
    title: 'How booking works',
    body: 'Pay a 30% advance to confirm your date. The balance is cash on '
        'delivery.',
  ),
  (
    icon: Icons.local_shipping_rounded,
    title: 'Free delivery in Kasara Balkunda',
    body: 'A delivery charge applies only on orders under 25 cans in other '
        'villages.',
  ),
];

// Legacy sheet retained temporarily for layout reference.
// ignore: unused_element
void _showNotifications(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.notifications_rounded,
                    color: AppColors.liveBrand, size: 22),
                const SizedBox(width: 8),
                const Text('Notifications',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                Spacer(),
                Text('${_kNotifications.length} new',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.liveBrand)),
              ],
            ),
            const SizedBox(height: 8),
            if (_kNotifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text("You're all caught up",
                      style: TextStyle(fontSize: 13.5, color: AppColors.body)),
                ),
              )
            else
              for (final n in _kNotifications) _NotificationTile(n),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.n);
  final ({IconData icon, String title, String body}) n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(n.icon, size: 19, color: AppColors.liveBrand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(n.body,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.body, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Side drawer ───────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.profile,
    required this.onOpenProfile,
  });
  final CustomerProfile profile;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  const BrandLogo(size: 44),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_firstName(profile.name),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      Text(AppConfigService.instance.plantDisplayName,
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.body)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.person_outline_rounded,
              label: AppConfigService.instance.label('drawer_profile'),
              onTap: () {
                Navigator.pop(context);
                onOpenProfile();
              },
            ),
            _DrawerItem(
              icon: Icons.water_drop_outlined,
              label: AppConfigService.instance.label('drawer_order'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BulkOrderFormScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.receipt_long_outlined,
              label: AppConfigService.instance.label('drawer_bookings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MyBookingsScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              label: AppConfigService.instance.label('drawer_wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WalletScreen(mobile: profile.mobile),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.headset_mic_outlined,
              label: AppConfigService.instance.label('drawer_support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const HelpSupportScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: AppConfigService.instance.label('drawer_logout'),
              onTap: () async {
                await AuthService.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ThakaThok · Mahalakshmi Water Plant',
                style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.body.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: AppColors.liveBrand, size: 25),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark)),
      onTap: onTap ??
          () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label — coming soon')),
            );
          },
      minLeadingWidth: 28,
      horizontalTitleGap: 12,
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  const _Greeting({required this.profile});
  final CustomerProfile profile;

  /// Customer name — comes from the profile once accounts are wired up.

  String get _timeOfDay {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_timeOfDay,',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.body, height: 1.2)),
          const SizedBox(height: 1),
          Row(
            children: [
              Text('${_firstName(profile.name)} ',
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.15)),
              Text('👋', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 2),
          Text(AppConfigService.instance.greetingTagline,
              style: const TextStyle(fontSize: 11.5, color: AppColors.body)),
        ],
      ),
    );
  }
}

// ── Wallet balance + pending dues ─────────────────────────────────────
String _firstName(String fullName) {
  final trimmed = fullName.trim();
  return trimmed.isEmpty ? 'Customer' : trimmed.split(RegExp(r'\s+')).first;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.profile,
    required this.onOpenWallet,
  });

  final CustomerProfile profile;
  final VoidCallback onOpenWallet;

  @override
  Widget build(BuildContext context) {
    final copy = AppConfigService.instance.quickActions;
    final actions =
        <({IconData icon, String title, String subtitle, VoidCallback onTap})>[
      (
        icon: Icons.water_drop_rounded,
        title: copy[0]['title']!,
        subtitle: copy[0]['subtitle']!,
        onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BulkOrderFormScreen()),
            ),
      ),
      (
        icon: Icons.sync_rounded,
        title: copy[1]['title']!,
        subtitle: copy[1]['subtitle']!,
        onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyBookingsScreen(initialMobile: profile.mobile),
              ),
            ),
      ),
      (
        icon: Icons.receipt_long_rounded,
        title: copy[2]['title']!,
        subtitle: copy[2]['subtitle']!,
        onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyBookingsScreen(initialMobile: profile.mobile),
              ),
            ),
      ),
      (
        icon: Icons.account_balance_wallet_rounded,
        title: copy[3]['title']!,
        subtitle: copy[3]['subtitle']!,
        onTap: onOpenWallet,
      ),
      (
        icon: Icons.headset_mic_rounded,
        title: copy[4]['title']!,
        subtitle: copy[4]['subtitle']!,
        onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Container(
        padding: EdgeInsets.fromLTRB(5, 13, 5, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.hairline),
          boxShadow: [
            BoxShadow(
              color: AppColors.liveBrand.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final action in actions)
              Expanded(
                child: InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 43,
                          width: 43,
                          decoration: BoxDecoration(
                            color: AppColors.tint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            action.icon,
                            size: 23,
                            color: AppColors.liveBrand,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.3,
                            fontWeight: FontWeight.w700,
                            color: AppColors.liveBrand,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          action.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 7.4,
                            color: AppColors.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WalletDuesRow extends StatelessWidget {
  const _WalletDuesRow({
    required this.walletBalance,
    required this.pendingDues,
    required this.mobile,
    required this.onOpenWallet,
  });

  final int walletBalance;
  final int pendingDues;
  final String mobile;
  final VoidCallback onOpenWallet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      // IntrinsicHeight gives the Row a bounded height so both cards can
      // stretch to match — a bare `stretch` would be unbounded in a scroll view.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _MoneyCard(
                icon: Icons.account_balance_wallet_rounded,
                iconBg: AppColors.tint,
                iconColor: AppColors.liveBrand,
                title: 'Wallet Balance',
                titleColor: AppColors.liveBrand,
                amount: '₹$walletBalance',
                paise: '.00',
                action: 'Add Money',
                actionFilled: true,
                onAction: onOpenWallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MoneyCard(
                icon: Icons.receipt_long_rounded,
                iconBg: Color(0xFFFDECEC),
                iconColor: Color(0xFFE23D3D),
                title: 'Pending Dues',
                titleColor: const Color(0xFFE23D3D),
                amount: '₹$pendingDues',
                paise: '.00',
                action: 'View Details',
                actionFilled: false,
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MyBookingsScreen(initialMobile: mobile),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.amount,
    required this.paise,
    required this.action,
    required this.actionFilled,
    this.onAction,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String amount;
  final String paise;
  final String action;
  final bool actionFilled;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: titleColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.1)),
              Text(paise,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.body)),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 34,
            width: double.infinity,
            child: actionFilled
                ? ElevatedButton(
                    onPressed: onAction ?? () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.liveBrand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(action,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Icon(Icons.add_circle_outline, size: 13),
                      ],
                    ),
                  )
                : OutlinedButton(
                    onPressed: onAction ?? () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE23D3D),
                      side: const BorderSide(color: Color(0x55E23D3D)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(action,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 13),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Trust strip ───────────────────────────────────────────────────────
class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  static const _icons = [
    Icons.verified_user_outlined,
    Icons.local_shipping_outlined,
    Icons.sync_rounded,
    Icons.workspace_premium_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final titles = AppConfigService.instance.trustItems;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.offerBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _icons.length; i++) ...[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icons[i], size: 19, color: AppColors.liveBrand),
                    const SizedBox(height: 5),
                    Text(
                      titles[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                ),
              ),
              if (i != _icons.length - 1)
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.black.withValues(alpha: 0.07),
                ),
            ],
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
  int _hintCycle = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _focus.addListener(_onChange);
  }

  void _onChange() {
    if (!_focus.hasFocus && _controller.text.isEmpty) {
      _hintCycle++;
    }
    setState(() {});
  }

  void _searchProducts() {
    final query = _controller.text.trim();
    _focus.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductSearchScreen(initialQuery: query),
      ),
    );
  }

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
                    onTapOutside: (_) => _focus.unfocus(),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchProducts(),
                    cursorColor: AppColors.liveBrand,
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
                        borderSide: BorderSide(color: AppColors.hairline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppColors.liveBrand, width: 1.3),
                      ),
                    ),
                  ),
                  if (showHint)
                    Positioned(
                      left: 16,
                      right: 12,
                      child: IgnorePointer(
                        child: _TypingHint(key: ValueKey(_hintCycle)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SearchButton(onTap: _searchProducts),
        ],
      ),
    );
  }
}

/// The dark-blue search button with slow bubbles rising inside it.
class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.liveBrand,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          height: 46,
          width: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: _RisingBubbles()),
              Icon(Icons.search, color: Colors.white, size: 22),
            ],
          ),
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
  const _TypingHint({super.key});

  @override
  State<_TypingHint> createState() => _TypingHintState();
}

class _TypingHintState extends State<_TypingHint> {
  List<String> get _phrases => AppConfigService.instance.searchPhrases;

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
  const _BannerCarousel({required this.banners});

  final List<HomeBanner> banners;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % widget.banners.length,
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
                itemCount: widget.banners.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => ContentImage(
                  source: widget.banners[i].image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 8,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.liveBrand : Color(0xFFBFD8F5),
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
  const _OfferCard({
    required this.title,
    required this.description,
    required this.code,
  });

  final String title;
  final String description;
  final String code;

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
                children: [
                  Text(title,
                      style: TextStyle(
                          color: AppColors.liveBrand,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.body,
                        fontSize: 9,
                        height: 1.35,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _DashedCodeBox(code: code),
          ],
        ),
      ),
    );
  }
}

class _DashedCodeBox extends StatelessWidget {
  const _DashedCodeBox({required this.code});

  final String code;

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
          children: [
            Text('Use Code',
                style: TextStyle(fontSize: 8.5, color: AppColors.body)),
            Text(code,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.liveBrand)),
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
  const _SectionHeader({
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

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
            InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(trailing!,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.liveBrand,
                            height: 1)),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.liveBrand,
                    ),
                  ],
                ),
              ),
            ),
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
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _kPad),
        itemCount: productPacks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _ProductCard(pack: productPacks[i]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.pack});
  final ProductPack pack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductPackDetailsScreen(pack: pack),
        ),
      ),
      child: Container(
        width: 150,
        padding: EdgeInsets.fromLTRB(9, 9, 9, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.liveBrand.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Hero(
                tag: pack.image,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ContentImage(
                    source: pack.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 36,
              width: double.infinity,
              child: Text(
                pack.name,
                maxLines: 2,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pack.quantityLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.liveBrand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full-bleed asset banner ───────────────────────────────────────────
class _DynamicPromoBanner extends StatelessWidget {
  const _DynamicPromoBanner({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: banner.action == 'order'
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BulkOrderFormScreen(),
                    ),
                  )
              : null,
          child: AspectRatio(
            aspectRatio: banner.action == 'order' ? 419 / 207 : 428 / 109,
            child: ContentImage(source: banner.image, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

// ── Shop by need ──────────────────────────────────────────────────────
class _ShopByNeed extends StatelessWidget {
  const _ShopByNeed({required this.categories});

  final List<ShopCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPad),
          child: Row(
            children: [
              Text(AppConfigService.instance.shopHeading,
                  style: const TextStyle(
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
            children: [
              for (final category in categories.take(4))
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BulkOrderFormScreen(
                          initialEventType: category.eventType,
                          startWithCustomQuantity: category.customQuantity,
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(60),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.tint,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: ClipOval(
                                child: ContentImage(
                                  source: category.image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.liveBrand,
                          ),
                        ),
                      ],
                    ),
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
  const _Footer({
    required this.onOpenProfile,
    required this.onOpenWallet,
  });
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenWallet;

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> with SingleTickerProviderStateMixin {
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
                    children: [
                      Expanded(
                          child: _NavItem(Icons.home_filled,
                              AppConfigService.instance.label('bottom_home'),
                              active: true)),
                      Expanded(
                          child: _NavItem(
                              Icons.receipt_long_outlined,
                              AppConfigService.instance
                                  .label('bottom_bookings'),
                              onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const MyBookingsScreen(),
                                    ),
                                  ))),
                      const SizedBox(width: 90),
                      Expanded(
                        child: _NavItem(
                          Icons.account_balance_wallet_outlined,
                          AppConfigService.instance.label('bottom_wallet'),
                          onTap: widget.onOpenWallet,
                        ),
                      ),
                      Expanded(
                          child: _NavItem(Icons.person_outline_rounded,
                              AppConfigService.instance.label('bottom_profile'),
                              onTap: widget.onOpenProfile)),
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
                      builder: (_) => BulkOrderFormScreen(),
                    ),
                  ),
                  child: Container(
                    height: 82,
                    width: 82,
                    decoration: BoxDecoration(
                      color: AppColors.liveBrand,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.liveBrand.withValues(alpha: 0.4),
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
                        Positioned(
                          bottom: 16,
                          child: Text(
                              AppConfigService.instance
                                  .label('bottom_products'),
                              style: const TextStyle(
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
  const _NavItem(this.icon, this.label, {this.active = false, this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.liveBrand : Color(0xFF5B6472);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
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
      ),
    );
  }
}
