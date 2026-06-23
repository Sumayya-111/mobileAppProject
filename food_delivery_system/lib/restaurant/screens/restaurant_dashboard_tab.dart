import 'package:flutter/material.dart';
import '../../data/firestore_service.dart';
import 'restaurant_home_screen.dart';

class RestaurantDashboardTab extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final int restaurantId;

  const RestaurantDashboardTab({
    super.key,
    required this.restaurant,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.instance.menuItemsForRestaurantStream(restaurantId),
      builder: (context, menuSnap) {
        final menuCount = menuSnap.data?.length ?? 0;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService.instance.ordersForRestaurantStream(restaurantId),
          builder: (context, orderSnap) {
            final orders = orderSnap.data ?? const [];
            final orderCount = orders.length;

            final deliveredOrders = orders.where((o) => o['status'] == 'Delivered');
            final totalRevenue = deliveredOrders.fold<double>(
              0.0,
                  (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble(),
            );
            final revenueLabel = totalRevenue >= 1000
                ? 'Rs ${(totalRevenue / 1000).toStringAsFixed(1)}k'
                : 'Rs ${totalRevenue.toStringAsFixed(0)}';

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Performance Overview', style: h1),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatCard(label: 'Total Orders', value: '$orderCount', icon: Icons.receipt_long, color: kBlue),
                    const SizedBox(width: 15),
                    _StatCard(label: 'Rating', value: '${restaurant['rating'] ?? 0}', icon: Icons.star, color: kAmber),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _StatCard(label: 'Menu Items', value: '$menuCount', icon: Icons.menu_book, color: kGreen),
                    const SizedBox(width: 15),
                    _StatCard(label: 'Revenue', value: revenueLabel, icon: Icons.payments, color: kPurple),
                  ],
                ),
                const SizedBox(height: 30),
                Text('Restaurant Details', style: h2),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(Icons.category, 'Category', '${restaurant['category'] ?? ''}'),
                      const Divider(),
                      _InfoRow(Icons.timer, 'Delivery Time', '${restaurant['deliveryTime'] ?? ''}'),
                      const Divider(),
                      _InfoRow(Icons.local_shipping, 'Fee', '${restaurant['deliveryFee'] ?? ''}'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: displayXL.copyWith(color: color)),
            Text(label, style: caption),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kTextSub),
          const SizedBox(width: 10),
          Text(label, style: body),
          const Spacer(),
          Text(value, style: h3),
        ],
      ),
    );
  }
}