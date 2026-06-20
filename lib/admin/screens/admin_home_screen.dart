import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/dummy_data.dart' as dummy; // Keep for fallback or types if needed
import '../../screens/login_screen.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const kPrimary = Color(0xFFFF6B35);
const kPrimaryLight = Color(0xFFFFF3EE);
const kPrimaryDark = Color(0xFFCC4F1F);
const kBg = Color(0xFFF5F4F2);
const kSurface = Colors.white;
const kText = Color(0xFF111111);
const kTextSub = Color(0xFF666666);
const kTextHint = Color(0xFFBBBBBB);
const kBorder = Color(0xFFEDEBE8);
const kGreen = Color(0xFF16A34A);
const kBlue = Color(0xFF2563EB);
const kAmber = Color(0xFFD97706);
const kRed = Color(0xFFDC2626);
const kPurple = Color(0xFF7C3AED);

// ── Text Styles ───────────────────────────────────────────────────────────────
TextStyle get _displayXL => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: kText,
    letterSpacing: -1.2,
    height: 1.0);

TextStyle get _h1 => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: kText,
    letterSpacing: -0.8,
    height: 1.1);

TextStyle get _h2 => const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: kText,
    letterSpacing: -0.4);

TextStyle get _h3 => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: kText,
    letterSpacing: -0.2);

TextStyle get _body => const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, color: kTextSub, height: 1.5);

TextStyle get _caption => const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: kTextHint, letterSpacing: 0.3);

TextStyle get _label => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: kTextHint,
    letterSpacing: 1.2);

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN HOME SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  final List<({IconData icon, String label})> _navItems = const [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.storefront_rounded, label: 'Restaurants'),
    (icon: Icons.receipt_long_rounded, label: 'Orders'),
    (icon: Icons.bar_chart_rounded, label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: kBg,
        body: Row(
          children: [
            if (isWide) _buildSideNav(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildBody(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: !isWide ? _buildBottomNav() : null,
      ),
    );
  }

  // ── Side Navigation ──────────────────────────────────────────────────────────
  Widget _buildSideNav() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: kText, // Dark sidebar for contrast
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
              child: Row(
                children: [
                  _OrangeBadgeIcon(
                    icon: Icons.local_fire_department_rounded,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FoodAdmin',
                          style: _h2.copyWith(
                              color: Colors.white, letterSpacing: -0.6)),
                      Text('Control Panel',
                          style: _caption.copyWith(
                              color: Colors.white38, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('NAVIGATION',
                  style: _label.copyWith(color: Colors.white24)),
            ),

            // Nav items
            ..._navItems.asMap().entries.map((e) {
              final isActive = _selectedIndex == e.key;
              return _SideNavItem(
                icon: e.value.icon,
                label: e.value.label,
                isActive: isActive,
                onTap: () => setState(() => _selectedIndex = e.key),
              );
            }),

            const Spacer(),

            // Divider
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              height: 1,
              color: Colors.white10,
            ),

            // Admin profile + logout
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, kPrimaryDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin User',
                            style: _h3.copyWith(
                                color: Colors.white, fontSize: 12)),
                        Text('Super Admin',
                            style: _caption.copyWith(color: Colors.white38)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Logout button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: _LogoutButton(onTap: _confirmLogout),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: _navItems.asMap().entries.map((e) {
              final isActive = _selectedIndex == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? kPrimary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(e.value.icon,
                            color: isActive ? kPrimary : kTextHint, size: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(e.value.label,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isActive ? kPrimary : kTextHint)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardTab(onLogout: _confirmLogout);
      case 1:
        return const _RestaurantsTab();
      case 2:
        return const _OrdersTab();
      case 3:
        return const _AnalyticsTab();
      default:
        return const SizedBox();
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _LogoutDialog(onConfirm: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REUSABLE SMALL WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _OrangeBadgeIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const _OrangeBadgeIcon({required this.icon, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
              color: kPrimary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _SideNavItem(
      {required this.icon,
        required this.label,
        required this.isActive,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? kPrimary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: kPrimary.withOpacity(0.3))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isActive ? kPrimary : Colors.white38, size: 19),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? kPrimary : Colors.white54)),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration:
                const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kRed.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, color: kRed, size: 18),
            const SizedBox(width: 10),
            Text('Logout',
                style: _h3.copyWith(
                    color: kRed, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _LogoutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  color: kRed.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.power_settings_new_rounded,
                  color: kRed, size: 30),
            ),
            const SizedBox(height: 18),
            Text('Sign Out', style: _h1),
            const SizedBox(height: 8),
            Text('You will be logged out of the admin panel.',
                style: _body, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kBorder, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel', style: _h3.copyWith(color: kTextSub)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Sign Out',
                        style: _h3.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page Header ───────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onLogout;

  const _PageHeader(
      {required this.title, required this.subtitle, this.trailing, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 20),
      color: kSurface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _h1),
                const SizedBox(height: 3),
                Text(subtitle, style: _body),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (isNarrow && onLogout != null) ...[
            const SizedBox(width: 10),
            _MobileLogoutButton(onTap: onLogout!),
          ],
        ],
      ),
    );
  }
}

class _MobileLogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MobileLogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kRed.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, color: kRed, size: 15),
            const SizedBox(width: 5),
            Text('Logout',
                style: _caption.copyWith(
                    color: kRed, fontWeight: FontWeight.w800, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DASHBOARD TAB  ── with Firebase Backend
// ═════════════════════════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  final VoidCallback? onLogout;

  const _DashboardTab({this.onLogout});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
      builder: (context, restSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, orderSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu_items').snapshots(),
              builder: (context, menuSnap) {
                if (restSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final restaurantsList = restSnap.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
                final ordersList = orderSnap.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
                final menuItemsList = menuSnap.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];

                // Stats calculation
                final totalRestaurants = restaurantsList.length;
                final totalOrders = ordersList.length;
                final totalMenuItems = menuItemsList.length;
                
                double avgRating = 0;
                if (restaurantsList.isNotEmpty) {
                  final sum = restaurantsList.fold<double>(0, (s, r) => s + ((r['rating'] ?? 0.0) as num).toDouble());
                  avgRating = sum / restaurantsList.length;
                }

                final popularCount = menuItemsList.where((i) => i['isPopular'] == true).length;

                // Category breakdown
                final catMap = <String, int>{};
                for (final r in restaurantsList) {
                  final cat = (r['category'] ?? 'Other') as String;
                  catMap[cat] = (catMap[cat] ?? 0) + 1;
                }
                final topCategories = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _PageHeader(
                        title: 'Dashboard',
                        subtitle: 'Welcome back, Admin 👋',
                        onLogout: onLogout,
                        trailing: const _OrangeBadgeIcon(
                          icon: Icons.local_fire_department_rounded,
                          size: 42,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildHeroStats(totalRestaurants, totalOrders, avgRating, popularCount)),
                    SliverToBoxAdapter(child: _buildHighlightRow(totalMenuItems)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                        child: Text('Category Breakdown', style: _h2),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildCategoryBreakdown(topCategories.take(5).toList())),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Restaurants', style: _h2),
                            Text('$totalRestaurants total', style: _caption.copyWith(color: kPrimary)),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _RestaurantCard(r: restaurantsList[i]),
                        ),
                        childCount: restaurantsList.take(5).length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeroStats(int totalRestaurants, int totalOrders, double avgRating, int popularCount) {
    final stats = [
      _StatData(
        icon: Icons.storefront_rounded,
        value: '$totalRestaurants',
        label: 'Restaurants',
        color: kPrimary,
        trend: 'Live',
      ),
      _StatData(
        icon: Icons.receipt_long_rounded,
        value: '$totalOrders',
        label: 'Total Orders',
        color: kBlue,
        trend: 'Realtime',
      ),
      _StatData(
        icon: Icons.star_rounded,
        value: avgRating.toStringAsFixed(1),
        label: 'Avg Rating',
        color: kAmber,
        trend: 'Community',
      ),
      _StatData(
        icon: Icons.local_fire_department_rounded,
        value: '$popularCount',
        label: 'Popular Items',
        color: kRed,
        trend: 'Trending',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: stats.map((s) => _BigStatCard(data: s)).toList(),
      ),
    );
  }

  Widget _buildHighlightRow(int totalMenuItems) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(child: _RevenueCard()),
          const SizedBox(width: 10),
          Expanded(child: _ActivityCard(totalMenuItems: totalMenuItems)),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<MapEntry<String, int>> topCategories) {
    final maxVal = topCategories.isEmpty ? 1 : topCategories.first.value;
    final barColors = [kPrimary, kBlue, kAmber, kGreen, kPurple];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: topCategories.asMap().entries.map((entry) {
            final pct = entry.value.value / maxVal;
            final color = barColors[entry.key % barColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: Text(entry.value.key,
                        style: _h3.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor: kBg,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${entry.value.value}',
                      style: _caption.copyWith(
                          color: color, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String trend;
  const _StatData(
      {required this.icon,
        required this.value,
        required this.label,
        required this.color,
        required this.trend});
}

class _BigStatCard extends StatelessWidget {
  final _StatData data;
  const _BigStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(data.trend,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: data.color)),
              ),
            ],
          ),
          const Spacer(),
          Text(data.value,
              style: _displayXL.copyWith(color: data.color, fontSize: 28)),
          const SizedBox(height: 2),
          Text(data.label, style: _caption),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: kPrimary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: Colors.white70, size: 18),
              const Spacer(),
              Text('\$8,240',
                  style: _displayXL.copyWith(
                      color: Colors.white, fontSize: 26)),
              const SizedBox(height: 2),
              Text('Revenue', style: _caption.copyWith(color: Colors.white60)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final int totalMenuItems;
  const _ActivityCard({required this.totalMenuItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kText,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white54, size: 18),
          const Spacer(),
          Text('$totalMenuItems',
              style: _displayXL.copyWith(color: Colors.white, fontSize: 26)),
          const SizedBox(height: 2),
          Text('Menu Items', style: _caption.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RESTAURANTS TAB  ── with Firebase Backend
// ═════════════════════════════════════════════════════════════════════════════

class _RestaurantsTab extends StatefulWidget {
  const _RestaurantsTab();

  @override
  State<_RestaurantsTab> createState() => _RestaurantsTabState();
}

class _RestaurantsTabState extends State<_RestaurantsTab> {
  String _search = '';

  void _deleteRestaurant(Map<String, dynamic> r, String docId) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: kRed.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.delete_rounded, color: kRed, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Delete Restaurant', style: _h2),
              const SizedBox(height: 8),
              Text('Remove "${r['name']}" from the platform?',
                  style: _body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: _h3.copyWith(color: kTextSub)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('restaurants').doc(docId).delete();
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${r['name']} removed'),
                            backgroundColor: kRed,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text('Delete',
                          style: _h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRestaurantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRestaurantSheet(
        onAdd: (newRestaurant) async {
          await FirebaseFirestore.instance.collection('restaurants').add(newRestaurant);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${newRestaurant['name']} added!'),
              backgroundColor: kGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
            builder: (context, snapshot) {
              final restaurantsList = snapshot.data?.docs ?? [];
              final filtered = restaurantsList.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['name'] as String).toLowerCase().contains(_search.toLowerCase()) ||
                       (data['category'] as String).toLowerCase().contains(_search.toLowerCase());
              }).toList();

              return Expanded(
                child: Column(
                  children: [
                    _PageHeader(
                        title: 'Restaurants',
                        subtitle: '${restaurantsList.length} listed on platform'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _SearchBar(
                        hint: 'Search by name or category…',
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator())
                          : filtered.isEmpty
                              ? const _EmptyState(message: 'No restaurants found')
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final doc = filtered[i];
                                    final r = doc.data() as Map<String, dynamic>;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _RestaurantCard(
                                        r: r,
                                        onDelete: () => _deleteRestaurant(r, doc.id),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            }
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRestaurantSheet,
        backgroundColor: kPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Restaurant',
            style: _h3.copyWith(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ORDERS TAB  ── with Firebase Backend
// ═════════════════════════════════════════════════════════════════════════════

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _selectedStatus = 'All';

  final List<String> _statuses = [
    'All',
    'Pending',
    'Preparing',
    'Out for Delivery',
    'Delivered',
    'Cancelled'
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return kPrimary;
      case 'Preparing':
        return kBlue;
      case 'Out for Delivery':
        return kPurple;
      case 'Delivered':
        return kGreen;
      case 'Cancelled':
        return kRed;
      default:
        return kTextHint;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.access_time_rounded;
      case 'Preparing':
        return Icons.restaurant_rounded;
      case 'Out for Delivery':
        return Icons.delivery_dining_rounded;
      case 'Delivered':
        return Icons.check_circle_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline;
    }
  }

  void _showOrderDetail(Map<String, dynamic> order, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(
        order: order,
        statusColor: _statusColor,
        statusIcon: _statusIcon,
        onStatusChanged: (newStatus) async {
          await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': newStatus});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        final allOrders = snapshot.data?.docs ?? [];
        final filtered = _selectedStatus == 'All' 
            ? allOrders 
            : allOrders.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == _selectedStatus).toList();

        return Column(
          children: [
            _PageHeader(
              title: 'Orders',
              subtitle: '${allOrders.length} total · ${allOrders.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Pending').length} pending',
            ),
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _statuses.length,
                itemBuilder: (_, i) {
                  final s = _statuses[i];
                  final isActive = _selectedStatus == s;
                  final color = s == 'All' ? kText : _statusColor(s);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStatus = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? color : kSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isActive ? color : kBorder),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : kTextSub)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${filtered.length} order${filtered.length != 1 ? 's' : ''}', style: _caption),
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _EmptyState(message: 'No $_selectedStatus orders')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final doc = filtered[i];
                            final order = doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _OrderCard(
                                order: order,
                                statusColor: _statusColor,
                                statusIcon: _statusIcon,
                                onTap: () => _showOrderDetail(order, doc.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      }
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order['status']);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      order['restaurantImage'],
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: kBg,
                        child:
                        const Icon(Icons.restaurant, color: kTextHint, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(order['id'], style: _caption),
                            _StatusChip(
                                label: order['status'],
                                color: color,
                                icon: statusIcon(order['status'])),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(order['restaurantName'], style: _h3),
                        Text(order['customerName'], style: _body),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: kBorder),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: kTextHint),
                      const SizedBox(width: 4),
                      Text(order['time'], style: _body),
                    ],
                  ),
                  Text('\$${(order['total'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: kPrimary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final Function(String) onStatusChanged;

  const _OrderDetailSheet({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
    required this.onStatusChanged,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  late String _currentStatus;
  final List<String> _allStatuses = [
    'Pending',
    'Preparing',
    'Out for Delivery',
    'Delivered',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'];
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.statusColor(_currentStatus);
    final items = List<String>.from(widget.order['items']);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.order['id'],
                              style: _h2.copyWith(fontSize: 20)),
                          Text(widget.order['time'], style: _body),
                        ],
                      ),
                      _StatusChip(
                          label: _currentStatus,
                          color: color,
                          icon: widget.statusIcon(_currentStatus)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: kBg, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.order['restaurantImage'],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: kBorder,
                                child: const Icon(Icons.restaurant,
                                    color: kTextHint)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.order['restaurantName'], style: _h3),
                            Text('Restaurant', style: _body),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionDivider(label: 'Customer Details'),
                  const SizedBox(height: 12),
                  _DetailRow(Icons.person_rounded, widget.order['customerName']),
                  const SizedBox(height: 8),
                  _DetailRow(Icons.phone_rounded, widget.order['customerPhone']),
                  const SizedBox(height: 8),
                  _DetailRow(
                      Icons.location_on_rounded, widget.order['address']),
                  const SizedBox(height: 20),
                  _SectionDivider(label: 'Order Items'),
                  const SizedBox(height: 12),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: kPrimary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Text(item, style: _body.copyWith(color: kText)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount',
                            style: _h3.copyWith(color: kPrimary)),
                        Text(
                            '\$${(widget.order['total'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                color: kPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionDivider(label: 'Update Status'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allStatuses.map((s) {
                      final isActive = _currentStatus == s;
                      final sColor = widget.statusColor(s);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentStatus = s);
                          widget.onStatusChanged(s);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isActive
                                ? sColor
                                : sColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isActive
                                    ? sColor
                                    : sColor.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(widget.statusIcon(s),
                                  color: isActive ? Colors.white : sColor,
                                  size: 13),
                              const SizedBox(width: 5),
                              Text(s,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color:
                                      isActive ? Colors.white : sColor)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: _caption.copyWith(
                fontWeight: FontWeight.w800,
                color: kTextSub,
                letterSpacing: 0.5)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: kBorder)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: kPrimaryLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: _body.copyWith(color: kText))),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ANALYTICS TAB  ── with Firebase Backend
// ═════════════════════════════════════════════════════════════════════════════

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
      builder: (context, restSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('menu_items').snapshots(),
          builder: (context, menuSnap) {
            if (restSnap.connectionState == ConnectionState.waiting || menuSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final restaurantsList = restSnap.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
            final menuItemsList = menuSnap.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];

            final totalRestaurants = restaurantsList.length;
            final totalMenuItems = menuItemsList.length;
            
            double avgRating = 0;
            if (restaurantsList.isNotEmpty) {
              final sum = restaurantsList.fold<double>(0, (s, r) => s + ((r['rating'] ?? 0.0) as num).toDouble());
              avgRating = sum / restaurantsList.length;
            }

            final catMap = <String, int>{};
            for (final r in restaurantsList) {
              final cat = (r['category'] ?? 'Other') as String;
              catMap[cat] = (catMap[cat] ?? 0) + 1;
            }
            final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            final maxVal = sorted.isEmpty ? 1 : sorted.first.value;

            final colors = [
              kPrimary, kBlue, kAmber, kRed, kGreen, kPurple,
              const Color(0xFF06B6D4), const Color(0xFFF97316),
            ];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _PageHeader(title: 'Analytics', subtitle: 'Platform breakdown'),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        _MiniStatCard('$totalRestaurants', 'Restaurants', kPrimary),
                        const SizedBox(width: 10),
                        _MiniStatCard('$totalMenuItems', 'Menu Items', kBlue),
                        const SizedBox(width: 10),
                        _MiniStatCard(avgRating.toStringAsFixed(1), 'Avg Rating', kAmber),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                    child: Text('By Category', style: _h2),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = sorted[i];
                      final color = colors[i % colors.length];
                      final pct = entry.value / maxVal;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              color: color, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(entry.key, style: _h3),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${entry.value} restaurant${entry.value > 1 ? 's' : ''}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: color,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: kBg,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        );
      },
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStatCard(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: _caption),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED CARDS & COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> r;
  final VoidCallback? onDelete;
  const _RestaurantCard({required this.r, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final rating = ((r['rating'] ?? 0.0) as num).toDouble();
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                r['image'] ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: kBg,
                  child: const Icon(Icons.restaurant, color: kTextHint, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['name'], style: _h3),
                  const SizedBox(height: 2),
                  Text(r['category'], style: _body),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: kAmber, size: 13),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kAmber)),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded,
                          color: kTextHint, size: 13),
                      const SizedBox(width: 3),
                      Text(r['deliveryTime'] ?? '', style: _body),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(r['deliveryFee'] ?? '',
                      style: const TextStyle(
                          fontSize: 12,
                          color: kPrimary,
                          fontWeight: FontWeight.w700)),
                ),
                if (onDelete != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: kRed, size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _body,
          prefixIcon:
          const Icon(Icons.search_rounded, color: kPrimary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: kBg,
                shape: BoxShape.circle,
                border: Border.all(color: kBorder)),
            child: const Icon(Icons.inbox_rounded, color: kTextHint, size: 32),
          ),
          const SizedBox(height: 16),
          Text(message, style: _h3.copyWith(color: kTextSub)),
          const SizedBox(height: 6),
          Text('Nothing to show here', style: _body),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADD RESTAURANT SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _AddRestaurantSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const _AddRestaurantSheet({required this.onAdd});

  @override
  State<_AddRestaurantSheet> createState() => _AddRestaurantSheetState();
}

class _AddRestaurantSheetState extends State<_AddRestaurantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();
  final _categoryController = TextEditingController();
  final _ratingController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _freeAboveController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageController.dispose();
    _categoryController.dispose();
    _ratingController.dispose();
    _deliveryTimeController.dispose();
    _deliveryFeeController.dispose();
    _priceRangeController.dispose();
    _freeAboveController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onAdd({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'image': _imageController.text.trim(),
        'category': _categoryController.text.trim(),
        'rating': double.tryParse(_ratingController.text.trim()) ?? 4.0,
        'deliveryTime': _deliveryTimeController.text.trim(),
        'deliveryFee': _deliveryFeeController.text.trim(),
        'priceRange': _priceRangeController.text.trim(),
        'freeAbove': _freeAboveController.text.trim(),
        'color': 0xFFFF6B35,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Restaurant', style: _h2),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: kTextSub),
                    ),
                  ),
                ],
              ),
            ),
            Container(
                margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                height: 1,
                color: kBorder),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  children: [
                    _FormField(
                        controller: _nameController,
                        label: 'Restaurant Name',
                        hint: 'e.g. Pizza Palace',
                        icon: Icons.storefront_rounded,
                        validator: (v) =>
                        v!.isEmpty ? 'Name is required' : null),
                    _FormField(
                        controller: _descController,
                        label: 'Description',
                        hint: 'e.g. Best pizza in town',
                        icon: Icons.notes_rounded,
                        validator: (v) =>
                        v!.isEmpty ? 'Description is required' : null),
                    _FormField(
                        controller: _imageController,
                        label: 'Image URL',
                        hint: 'https://...',
                        icon: Icons.image_outlined,
                        validator: (v) =>
                        v!.isEmpty ? 'Image URL is required' : null),
                    _FormField(
                        controller: _categoryController,
                        label: 'Category',
                        hint: 'e.g. Pizza, Burger, Sushi',
                        icon: Icons.category_outlined,
                        validator: (v) =>
                        v!.isEmpty ? 'Category is required' : null),
                    _FormField(
                      controller: _ratingController,
                      label: 'Rating',
                      hint: 'e.g. 4.5',
                      icon: Icons.star_outline_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d < 1 || d > 5) {
                          return 'Enter a rating between 1.0 and 5.0';
                        }
                        return null;
                      },
                    ),
                    _FormField(
                        controller: _deliveryTimeController,
                        label: 'Delivery Time',
                        hint: 'e.g. 20-30 min',
                        icon: Icons.access_time_rounded,
                        validator: (v) =>
                        v!.isEmpty ? 'Delivery time is required' : null),
                    _FormField(
                        controller: _deliveryFeeController,
                        label: 'Delivery Fee',
                        hint: 'e.g. \$2.99 or Free',
                        icon: Icons.delivery_dining_rounded,
                        validator: (v) =>
                        v!.isEmpty ? 'Delivery fee is required' : null),
                    _FormField(
                        controller: _priceRangeController,
                        label: 'Price Range',
                        hint: 'e.g. \$\$ or \$10–\$30',
                        icon: Icons.payments_outlined),
                    _FormField(
                        controller: _freeAboveController,
                        label: 'Free Delivery Above (optional)',
                        hint: 'e.g. \$20',
                        icon: Icons.local_offer_outlined),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Add Restaurant',
                            style: _h3.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: _body.copyWith(
                  color: kText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: _body.copyWith(color: kText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _body,
              prefixIcon: Icon(icon, color: kPrimary, size: 18),
              filled: true,
              fillColor: kBg,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kRed, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kRed, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}