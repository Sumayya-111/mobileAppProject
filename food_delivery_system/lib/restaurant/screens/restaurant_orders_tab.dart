import 'package:flutter/material.dart';
import '../../data/firestore_service.dart';
import 'restaurant_home_screen.dart';

class RestaurantOrdersTab extends StatefulWidget {
  final int restaurantId;

  const RestaurantOrdersTab({super.key, required this.restaurantId});

  @override
  State<RestaurantOrdersTab> createState() => _RestaurantOrdersTabState();
}

class _RestaurantOrdersTabState extends State<RestaurantOrdersTab> {
  String _selectedFilter = 'Active';

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> orders) {
    if (_selectedFilter == 'Active') {
      return orders
          .where((o) => o['status'] != 'Delivered' && o['status'] != 'Cancelled')
          .toList();
    } else {
      return orders
          .where((o) => o['status'] == 'Delivered' || o['status'] == 'Cancelled')
          .toList();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':         return kAmber;
      case 'Preparing':       return kBlue;
      case 'Out for Delivery': return kPurple;
      case 'Delivered':       return kGreen;
      case 'Cancelled':       return kRed;
      default:                return kTextSub;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Orders Management', style: h1),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _FilterBtn(
                      label: 'Active',
                      isActive: _selectedFilter == 'Active',
                      onTap: () => setState(() => _selectedFilter = 'Active'),
                    ),
                    _FilterBtn(
                      label: 'History',
                      isActive: _selectedFilter == 'History',
                      onTap: () => setState(() => _selectedFilter = 'History'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.instance.ordersForRestaurantStream(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimary));
              }
              final filteredOrders = _filter(snapshot.data ?? const []);

              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: kTextHint.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No $_selectedFilter Orders', style: h2.copyWith(color: kTextSub)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: filteredOrders.length,
                itemBuilder: (_, i) {
                  final order = filteredOrders[i];
                  final color = _getStatusColor(order['status']);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.shopping_bag_outlined, color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['id'] ?? '',
                                      style: caption.copyWith(fontWeight: FontWeight.bold, color: kTextSub),
                                    ),
                                    Text(order['customerName'] ?? '', style: h2),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  order['status'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: kBorder),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _OrderInfoRow(Icons.location_on_outlined, order['address'] ?? ''),
                              const SizedBox(height: 8),
                              _OrderInfoRow(Icons.phone_outlined, order['customerPhone'] ?? ''),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ITEMS', style: caption.copyWith(letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text(
                                      (order['items'] as List? ?? const []).join(', '),
                                      style: body.copyWith(color: kText, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Rs ${order['total']}', style: h1.copyWith(color: kPrimary)),
                              if (_selectedFilter == 'Active')
                                _StatusPicker(
                                  currentStatus: order['status'] ?? '',
                                  onChanged: (val) async {
                                    await FirestoreService.instance
                                        .updateOrderStatus(order['docId'] as String, val);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterBtn({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? kPrimary : kTextHint,
          ),
        ),
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OrderInfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kTextHint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: body, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final String currentStatus;
  final Function(String) onChanged;

  const _StatusPicker({required this.currentStatus, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            Text(
              'Update Status',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) => ['Pending', 'Preparing', 'Out for Delivery', 'Delivered', 'Cancelled']
          .map((s) => PopupMenuItem(value: s, child: Text(s)))
          .toList(),
    );
  }
}