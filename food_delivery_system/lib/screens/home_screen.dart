import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'restaurant_detail_screen.dart';
import 'category_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'dart:async';
import '../data/cart_manager.dart';
import '../data/firestore_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// HOME SCREEN  (root scaffold + bottom nav)
// ═════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // In _HomeScreenState — add these:
  final CartManager _cart = CartManager.instance;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5F2),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService.instance.restaurantsStream(),
          builder: (context, snapshot) {
            final restaurants = snapshot.data ?? const [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return IndexedStack(
              index: _selectedIndex,
              children: [
                isLoading
                    ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFFFF6B35)))
                    : _HomeBody(
                    restaurants: restaurants,
                    onTabChange: (i) =>
                        setState(() => _selectedIndex = i)),
                CategoryScreen(restaurants: restaurants),
                const CartScreen(),
                const ProfileScreen(),
              ],
            );
          },
        ),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          cartCount: _cart.totalCount,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BOTTOM NAVIGATION
// ═════════════════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF6B35);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isActive: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Categories',
                isActive: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Cart',
                isActive: selectedIndex == 2,
                onTap: () => onTap(2),
                badgeCount: cartCount,
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isActive: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF6B35);
    final color = isActive ? activeColor : const Color(0xFFB0ADA8);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(icon, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SEARCH OVERLAY SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class _SearchScreen extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  const _SearchScreen({required this.restaurants});

  @override
  State<_SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<_SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  static const List<String> _trending = [
    '🍕 Pizza',
    '🍔 Burger',
    '🍣 Sushi',
    '🍗 BBQ',
    '🥗 Healthy',
    '🍜 Chinese',
  ];

  // ── Safe string helper ────────────────────────────────────────────────────
  String _str(Map<String, dynamic> r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  List<Map<String, dynamic>> get _results {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    return widget.restaurants.where((r) {
      final name = _str(r, ['name']).toLowerCase();
      final desc = _str(r, ['description', 'desc']).toLowerCase();
      final cat  = _str(r, ['category', 'tag']).toLowerCase();
      final menu = r['menu'] as List? ?? [];
      final menuMatch = menu.any((item) {
        if (item is! Map) return false;
        final itemName = (item['name'] ?? '').toString().toLowerCase();
        final itemDesc = (item['description'] ?? '').toString().toLowerCase();
        return itemName.contains(q) || itemDesc.contains(q);
      });
      return name.contains(q) || desc.contains(q) || cat.contains(q) || menuMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = _controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final showTrending = _query.trim().isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Column(
        children: [
          // ── Search header ──────────────────────────────────────────────────
          Container(
            color: const Color(0xFFFF6B35),
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 12, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search_rounded,
                            color: Color(0xFFFF6B35), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111111)),
                            decoration: const InputDecoration(
                              hintText: 'Search restaurants or dishes…',
                              hintStyle: TextStyle(
                                  color: Color(0xFFBBBBBB),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () => _controller.clear(),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCCCCCC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Results / Trending ─────────────────────────────────────────────
          Expanded(
            child: showTrending
                ? _buildTrending()
                : results.isEmpty
                ? _buildEmpty()
                : _buildResults(results),
          ),
        ],
      ),
    );
  }

  Widget _buildTrending() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('🔥 Trending Now',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111))),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _trending
              .map((t) => GestureDetector(
            onTap: () {
              final spaceIdx = t.indexOf(' ');
              final word = spaceIdx >= 0
                  ? t.substring(spaceIdx + 1)
                  : t;
              _controller.text = word;
              _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border:
                Border.all(color: const Color(0xFFE8E5E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(t,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333))),
            ),
          ))
              .toList(),
        ),
        const SizedBox(height: 28),
        const Text('All Restaurants',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111))),
        const SizedBox(height: 14),
        ...widget.restaurants
            .map((r) => _SearchResultTile(data: r))
            .toList(),
      ],
    );
  }

  Widget _buildResults(List<Map<String, dynamic>> results) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
            '${results.length} result${results.length == 1 ? '' : 's'} for "$_query"',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888))),
        const SizedBox(height: 14),
        ...results
            .map((r) => _SearchResultTile(data: r, query: _query))
            .toList(),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text('No results for "$_query"',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333))),
          const SizedBox(height: 6),
          const Text('Try a different keyword',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Single search result row ──────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String query;
  const _SearchResultTile({required this.data, this.query = ''});

  String _s(List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _s(['image', 'img']);
    final String name     = _s(['name']);
    final String desc     = _s(['description', 'desc']);
    final String cat      = _s(['category', 'tag']);
    final String time     = _s(['deliveryTime', 'time']);
    final double rating =
    ((data['rating'] ?? 0.0) as num).toDouble();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                RestaurantDetailScreen(restaurant: data)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 80,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFFF6B35)
                          .withOpacity(0.2)),
                )
                    : Container(
                    color:
                    const Color(0xFFFF6B35).withOpacity(0.2)),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedText(text: name, query: query),
                    const SizedBox(height: 3),
                    Text(desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                            height: 1.4)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (cat.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(cat,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF666666))),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF5C400), size: 13),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555))),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: Color(0xFFAAAAAA)),
                          const SizedBox(width: 2),
                          Text(time,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFAAAAAA),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCCCCCC), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Highlights the matching portion of [text] in orange
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111)));
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111)));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111)),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + q.length),
            style: const TextStyle(
                color: Color(0xFFFF6B35),
                backgroundColor: Color(0x1FFF6B35)),
          ),
          if (idx + q.length < text.length)
            TextSpan(text: text.substring(idx + q.length)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HOME BODY
// ═════════════════════════════════════════════════════════════════════════════

class _HomeBody extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final ValueChanged<int> onTabChange;
  const _HomeBody({required this.restaurants, required this.onTabChange});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late PageController _promoController;
  Timer? _promoTimer;
  int _currentPromoPage = 0;
  int _selectedCategoryIndex = 0;

  static const Map<String, String> _catImages = {
    'Pizza':
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=80&q=75',
    'Burger':
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=80&q=75',
    'Sushi':
    'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=80&q=75',
    'Salad':
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=80&q=75',
    'Drinks':
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=80&q=75',
    'Dessert':
    'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=80&q=75',
    'BBQ':
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=80&q=75',
    'Chinese':
    'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=80&q=75',
    'Biryani':
    'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=80&q=75',
    'Wraps':
    'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=80&q=75',
    'Italian':
    'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=80&q=75',
    'Breakfast':
    'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=80&q=75',
    'Healthy':
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=80&q=75',
    'Bakery':
    'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=80&q=75',
    'Café':
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=80&q=75',
    'Pakistani':
    'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=80&q=75',
    'Mexican':
    'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=80&q=75',
    'Japanese':
    'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=80&q=75',
    'American':
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=80&q=75',
    'Hawaiian':
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=80&q=75',
    'Steakhouse':
    'https://images.unsplash.com/photo-1558030006-450675393462?w=80&q=75',
    'All-day':
    'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=80&q=75',
  };

  static const _fallbackImg =
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=80&q=75';

  List<Map<String, String>> get _categoryPills {
    final seen = <String>{};
    final pills = <Map<String, String>>[
      {'label': 'All', 'img': _fallbackImg},
    ];
    for (final r in widget.restaurants) {
      final cat = (r['category'] ?? r['tag'] ?? '') as String;
      if (cat.isNotEmpty && seen.add(cat)) {
        pills.add({
          'label': cat,
          'img': _catImages[cat] ?? _fallbackImg,
        });
      }
    }
    return pills;
  }

  List<Map<String, dynamic>> get _filteredRestaurants {
    if (_selectedCategoryIndex == 0) {
      return List<Map<String, dynamic>>.from(widget.restaurants);
    }
    final label = _categoryPills[_selectedCategoryIndex]['label']!;
    return widget.restaurants
        .where((r) =>
    (r['category'] ?? r['tag'] ?? '').toString() == label)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _promoController = PageController();
    _promoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentPromoPage + 1) % 3;
      _promoController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPromoPage = next);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRestaurants;
    final pills = _categoryPills;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildPromo()),
            SliverToBoxAdapter(
                child: _buildSectionHeader('Categories',
                    onSeeAll: () => widget.onTabChange(1))),
            SliverToBoxAdapter(child: _buildCategories(pills)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                _selectedCategoryIndex == 0
                    ? 'Popular Nearby 🔥'
                    : '${pills[_selectedCategoryIndex]['label']} Restaurants',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) => _RestaurantCard(data: filtered[i]),
                childCount: filtered.length,
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      const Text('🍽️',
                          style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'No restaurants in this category yet',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 28),
      decoration: const BoxDecoration(color: Color(0xFFFF6B35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PulsingDot(),
                      const SizedBox(width: 6),
                      const Text('Karachi, Pakistan',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: FirestoreService.instance
                        .currentUserProfileStream(),
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final name = (profile?['name'] ??
                          profile?['displayName'] ??
                          'there') as String;
                      final firstName = name.trim().isNotEmpty
                          ? name.trim().split(' ').first
                          : 'there';
                      return Text('Hey $firstName! 👋',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4));
                    },
                  ),
                  const SizedBox(height: 2),
                  const Text('What are you craving today?',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              _NotifButton(),
            ],
          ),
          const SizedBox(height: 20),
          // ── Search bar ────────────────────────────────────────────────────
          _TappableSearchBar(restaurants: widget.restaurants),
        ],
      ),
    );
  }

  // ── Promo Banner ──────────────────────────────────────────────────────────

  Widget _buildPromo() {
    final promos = [
      {
        'image':
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80',
        'badge': '🔥 Today only',
        'title': '30% OFF',
        'subtitle': 'First Order',
        'cta': 'Order Now →',
      },
      {
        'image':
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80',
        'badge': '🚀 Fast delivery',
        'title': 'FREE',
        'subtitle': 'Delivery Today',
        'cta': 'Grab Deal →',
      },
      {
        'image':
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
        'badge': '⭐ Top Rated',
        'title': 'BEST',
        'subtitle': 'Restaurants',
        'cta': 'Explore →',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 150,
          child: Stack(
            children: [
              PageView.builder(
                controller: _promoController,
                itemCount: promos.length,
                onPageChanged: (i) =>
                    setState(() => _currentPromoPage = i),
                itemBuilder: (context, i) {
                  final p = promos[i];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(p['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFFFF6B35))),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xEEFF6B35),
                              Color(0x66FF6B35),
                              Color(0x00FF6B35),
                            ],
                            stops: [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        right: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                Colors.white.withOpacity(0.25),
                                borderRadius:
                                BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.4)),
                              ),
                              child: Text(p['badge']!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3)),
                            ),
                            const SizedBox(height: 7),
                            Text(p['title']!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: -0.5)),
                            Text(p['subtitle']!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(10)),
                              child: Text(p['cta']!,
                                  style: const TextStyle(
                                      color: Color(0xFFE8490D),
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                bottom: 10,
                right: 12,
                child: Row(
                  children: List.generate(
                      promos.length,
                          (i) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: _PromoDot(
                            active: _currentPromoPage == i),
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Color(0xFF111111))),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See all',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6B35))),
            ),
        ],
      ),
    );
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Widget _buildCategories(List<Map<String, String>> pills) {
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pills.length,
        itemBuilder: (context, i) {
          final cat = pills[i];
          final isActive = _selectedCategoryIndex == i;
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedCategoryIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: isActive
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFE8E5E0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(cat['img']!,
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 26, height: 26)),
                  ),
                  const SizedBox(width: 7),
                  Text(cat['label']!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF222222))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAPPABLE SEARCH BAR  ← FIXED (removed super.key from non-keyed private widget)
// ═════════════════════════════════════════════════════════════════════════════

class _TappableSearchBar extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  const _TappableSearchBar({required this.restaurants});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                _SearchScreen(restaurants: restaurants),
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration:
            const Duration(milliseconds: 220),
            transitionsBuilder:
                (_, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFFF6B35),
              size: 22,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Search restaurants or dishes...',
                style: TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.25),
                ),
              ),
              child: const Text(
                '🔥 Trending',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RESTAURANT CARD
// ═════════════════════════════════════════════════════════════════════════════

class _RestaurantCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _RestaurantCard({required this.data});

  @override
  State<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<_RestaurantCard> {
  bool _isFaved = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.data;

    final String imageUrl   = (r['image']        ?? r['img']      ?? '') as String;
    final String desc       = (r['description']  ?? r['desc']     ?? '') as String;
    final String time       = (r['deliveryTime'] ?? r['time']     ?? '') as String;
    final String fee        = (r['deliveryFee']  ?? '') as String;
    final String priceRange = (r['priceRange']   ?? '') as String;
    final String freeAbove  = (r['freeAbove']    ?? '') as String;
    final String tag        = (r['tag']          ?? r['category'] ?? '') as String;
    final double rating     = ((r['rating'] ?? 0.0) as num).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RestaurantDetailScreen(restaurant: r)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: Color(
                                (r['color'] ?? 0xFFFF6B35)
                                as int)),
                      )
                          : Container(
                          color: Color(
                              (r['color'] ?? 0xFFFF6B35) as int)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(tag,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2)),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _isFaved = !_isFaved),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _isFaved
                                  ? const Color(0xFFFF6B35)
                                  : Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isFaved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: _isFaved
                                  ? Colors.white
                                  : const Color(0xFF999999),
                            ),
                          ),
                        ),
                      ),
                      if (time.isNotEmpty)
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF4CD964),
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                                Text(time,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight:
                                        FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (r['name'] ?? '') as String,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111111),
                                letterSpacing: -0.2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBE6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFF5D400)
                                    .withOpacity(0.6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFF5C400), size: 14),
                              const SizedBox(width: 3),
                              Text(rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF7A6000))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 13,
                            height: 1.4)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (fee.isNotEmpty)
                          _MetaChip(
                              icon: Icons.delivery_dining_rounded,
                              label: fee),
                        if (fee.isNotEmpty && priceRange.isNotEmpty)
                          const SizedBox(width: 12),
                        if (priceRange.isNotEmpty)
                          _MetaChip(
                              icon: Icons.payments_outlined,
                              label: priceRange),
                        if (freeAbove.isNotEmpty) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Free > $freeAbove',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32))),
                          ),
                        ],
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF999999), size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SMALL HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _s = Tween<double>(begin: 0.8, end: 1.2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _s,
      child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle)),
    );
  }
}

class _NotifButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_outlined,
              color: Color(0xFFFF6B35), size: 22),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoDot extends StatelessWidget {
  final bool active;
  const _PromoDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
