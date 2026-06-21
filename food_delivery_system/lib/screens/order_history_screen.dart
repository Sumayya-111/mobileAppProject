import 'package:flutter/material.dart';
import '../data/firestore_service.dart';

// Matches the existing app palette used in restaurant_home_screen.dart /
// admin_home_screen.dart so status colors are consistent everywhere.
const _kPrimary = Color(0xFFFF6B35);
const _kAmber = Color(0xFFD97706);
const _kBlue = Color(0xFF2563EB);
const _kPurple = Color(0xFF7C3AED);
const _kGreen = Color(0xFF16A34A);
const _kRed = Color(0xFFDC2626);
const _kTextHint = Color(0xFFBBBBBB);

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return _kAmber;
      case 'Preparing':
        return _kBlue;
      case 'Out for Delivery':
        return _kPurple;
      case 'Delivered':
        return _kGreen;
      case 'Cancelled':
        return _kRed;
      default:
        return _kTextHint;
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
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order History',
            style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.instance.myOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _kPrimary));
          }

          final orders = List<Map<String, dynamic>>.from(
              snapshot.data ?? const []);

          // Most recent first. createdAt is a Firestore Timestamp written
          // via FieldValue.serverTimestamp() in FirestoreService.createOrder.
          orders.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: _kPrimary, size: 40),
                  ),
                  const SizedBox(height: 18),
                  const Text('No orders yet',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333))),
                  const SizedBox(height: 6),
                  Text('Your past orders will show up here',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              final color = _statusColor(order['status'] ?? '');
              final items = List<String>.from(order['items'] ?? const []);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (order['restaurantImage'] ?? '')
                                .toString()
                                .isNotEmpty
                                ? Image.network(
                              order['restaurantImage'],
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFFF5F5F5),
                                  child: const Icon(Icons.restaurant,
                                      color: _kTextHint, size: 20)),
                            )
                                : Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFF5F5F5),
                                child: const Icon(Icons.restaurant,
                                    color: _kTextHint, size: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['restaurantName'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111111))),
                                const SizedBox(height: 2),
                                Text(order['id'] ?? '',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(order['status'] ?? ''),
                                    size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(order['status'] ?? '',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(height: 1, color: const Color(0xFFF0EEEB)),
                        const SizedBox(height: 12),
                        Text(items.join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.4)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(order['time'] ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                              'Rs ${((order['total'] ?? 0) as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: _kPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}