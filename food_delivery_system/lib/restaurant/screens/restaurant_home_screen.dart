import 'package:flutter/material.dart';
import '../../data/firestore_service.dart';
import '../../screens/login_screen.dart';
import 'restaurant_menu_tab.dart';
import 'restaurant_orders_tab.dart';
import 'restaurant_dashboard_tab.dart';

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

TextStyle get displayXL => const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kText, letterSpacing: -1.0);
TextStyle get h1 => const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText, letterSpacing: -0.5);
TextStyle get h2 => const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText);
TextStyle get h3 => const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText);
TextStyle get body => const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: kTextSub, height: 1.5);
TextStyle get caption => const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextHint);

class RestaurantHomeScreen extends StatefulWidget {
  final int restaurantId;
  const RestaurantHomeScreen({super.key, this.restaurantId = 1});

  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  int _selectedIndex = 0;

  final List<({IconData icon, String label})> _navItems = const [
    (icon: Icons.dashboard_rounded, label: 'Stats'),
    (icon: Icons.restaurant_menu_rounded, label: 'Menu'),
    (icon: Icons.receipt_long_rounded, label: 'Orders'),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.instance.restaurantsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kBg,
            body: Center(child: CircularProgressIndicator(color: kPrimary)),
          );
        }

        final allRestaurants = snapshot.data ?? const [];
        final restaurant = allRestaurants.firstWhere(
              (r) => r['id'] == widget.restaurantId,
          orElse: () => <String, dynamic>{
            'name': 'Restaurant',
            'image': '',
            'category': '',
            'deliveryTime': '',
            'deliveryFee': '',
            'rating': 0,
          },
        );

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kSurface,
            elevation: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (restaurant['image'] ?? '').toString().isNotEmpty
                      ? NetworkImage(restaurant['image'])
                      : null,
                  child: (restaurant['image'] ?? '').toString().isEmpty
                      ? const Icon(Icons.storefront, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant['name'] ?? '', style: h2),
                    Text('Restaurant Panel', style: caption.copyWith(color: kPrimary)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: kRed),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
            ],
          ),
          body: _buildBody(restaurant),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBody(Map<String, dynamic> restaurant) {
    switch (_selectedIndex) {
      case 0:
        return RestaurantDashboardTab(restaurant: restaurant, restaurantId: widget.restaurantId);
      case 1:
        return RestaurantMenuTab(restaurantId: widget.restaurantId);
      case 2:
        return RestaurantOrdersTab(restaurantId: widget.restaurantId);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: _navItems.asMap().entries.map((e) {
              final isActive = _selectedIndex == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = e.key),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.icon, color: isActive ? kPrimary : kTextHint),
                      Text(
                        e.value.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? kPrimary : kTextHint,
                        ),
                      ),
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
}