import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/firestore_service.dart';
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
TextStyle get _displayXL => const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kText, letterSpacing: -1.0);
TextStyle get _h1 => const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText, letterSpacing: -0.5);
TextStyle get _h2 => const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText);
TextStyle get _h3 => const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText);
TextStyle get _body => const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: kTextSub, height: 1.5);
TextStyle get _caption => const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextHint);

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
            body: Center(
                child: CircularProgressIndicator(color: kPrimary)),
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
                  backgroundImage: (restaurant['image'] ?? '')
                      .toString()
                      .isNotEmpty
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
                    Text(restaurant['name'] ?? '', style: _h2),
                    Text('Restaurant Panel',
                        style: _caption.copyWith(color: kPrimary)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: kRed),
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
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
        return _DashboardTab(
            restaurant: restaurant, restaurantId: widget.restaurantId);
      case 1:
        return _MenuTab(restaurantId: widget.restaurantId);
      case 2:
        return _OrdersTab(restaurantId: widget.restaurantId);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: kSurface, border: Border(top: BorderSide(color: kBorder))),
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
                      Text(e.value.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? kPrimary : kTextHint)),
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

// ── Dashboard Tab ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final int restaurantId;

  const _DashboardTab({required this.restaurant, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.instance
          .menuItemsForRestaurantStream(restaurantId),
      builder: (context, menuSnap) {
        final menuCount = menuSnap.data?.length ?? 0;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService.instance
              .ordersForRestaurantStream(restaurantId),
          builder: (context, orderSnap) {
            final orders = orderSnap.data ?? const [];
            final orderCount = orders.length;

            // Sum of Delivered orders only — actual completed revenue,
            // excluding Pending/Preparing/Out for Delivery/Cancelled.
            final deliveredOrders =
            orders.where((o) => o['status'] == 'Delivered');
            final totalRevenue = deliveredOrders.fold<double>(
                0.0, (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble());
            final revenueLabel = totalRevenue >= 1000
                ? 'Rs ${(totalRevenue / 1000).toStringAsFixed(1)}k'
                : 'Rs ${totalRevenue.toStringAsFixed(0)}';

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Performance Overview', style: _h1),
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
                Text('Restaurant Details', style: _h2),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(15), border: Border.all(color: kBorder)),
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
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(15), border: Border.all(color: kBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: _displayXL.copyWith(color: color)),
            Text(label, style: _caption),
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
          Text(label, style: _body),
          const Spacer(),
          Text(value, style: _h3),
        ],
      ),
    );
  }
}

// ── Menu Tab (CRUD) ───────────────────────────────────────────────────────────
class _MenuTab extends StatelessWidget {
  final int restaurantId;

  const _MenuTab({required this.restaurantId});

  void _showAddEditItem(BuildContext context, [Map<String, dynamic>? item]) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final priceController = TextEditingController(text: item?['price']?.toString() ?? '');
    final descController = TextEditingController(text: item?['description'] ?? '');
    final imageController = TextEditingController(text: item?['image'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Edit Item' : 'Add New Item', style: _h1),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (Rs)'), keyboardType: TextInputType.number),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  if (isEditing) {
                    await FirestoreService.instance.updateMenuItem(
                      item['docId'] as String,
                      {
                        'name': nameController.text,
                        'price': price,
                        'description': descController.text,
                        'image': imageController.text,
                      },
                    );
                  } else {
                    await FirestoreService.instance.addMenuItem(
                      restaurantId: restaurantId,
                      name: nameController.text,
                      price: price,
                      description: descController.text,
                      image: imageController.text,
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(isEditing ? 'Update Item' : 'Add Item', style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Menu', style: _h1),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                onPressed: () => _showAddEditItem(context),
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.instance
                .menuItemsForRestaurantStream(restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: kPrimary));
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return Center(
                  child: Text('No menu items yet — tap "Add Item" to start',
                      style: _body, textAlign: TextAlign.center),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: (item['image'] ?? '').toString().isNotEmpty
                            ? Image.network(item['image'], width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 60, height: 60, color: kBg,
                                child: const Icon(Icons.fastfood, color: kTextHint)))
                            : Container(width: 60, height: 60, color: kBg,
                            child: const Icon(Icons.fastfood, color: kTextHint)),
                      ),
                      title: Text(item['name'] ?? '', style: _h2),
                      subtitle: Text('Rs ${item['price']}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: kBlue), onPressed: () => _showAddEditItem(context, item)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: kRed),
                            onPressed: () async {
                              await FirestoreService.instance
                                  .deleteMenuItem(item['docId'] as String);
                            },
                          ),
                        ],
                      ),
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

// ── Orders Tab ────────────────────────────────────────────────────────────────
class _OrdersTab extends StatefulWidget {
  final int restaurantId;

  const _OrdersTab({required this.restaurantId});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _selectedFilter = 'Active'; // Active vs History

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> orders) {
    if (_selectedFilter == 'Active') {
      return orders.where((o) => o['status'] != 'Delivered' && o['status'] != 'Cancelled').toList();
    } else {
      return orders.where((o) => o['status'] == 'Delivered' || o['status'] == 'Cancelled').toList();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return kAmber;
      case 'Preparing': return kBlue;
      case 'Out for Delivery': return kPurple;
      case 'Delivered': return kGreen;
      case 'Cancelled': return kRed;
      default: return kTextSub;
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
              Text('Orders Management', style: _h1),
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
            stream: FirestoreService.instance
                .ordersForRestaurantStream(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: kPrimary));
              }
              final filteredOrders = _filter(snapshot.data ?? const []);

              return filteredOrders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: kTextHint.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No $_selectedFilter Orders', style: _h2.copyWith(color: kTextSub)),
                  ],
                ),
              )
                  : ListView.builder(
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.shopping_bag_outlined, color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order['id'] ?? '', style: _caption.copyWith(fontWeight: FontWeight.bold, color: kTextSub)),
                                    Text(order['customerName'] ?? '', style: _h2),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                                child: Text(order['status'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ITEMS', style: _caption.copyWith(letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text((order['items'] as List? ?? const []).join(', '), style: _body.copyWith(color: kText, fontWeight: FontWeight.w500)),
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
                              Text('Rs ${order['total']}', style: _h1.copyWith(color: kPrimary)),
                              if (_selectedFilter == 'Active')
                                _StatusPicker(
                                  currentStatus: order['status'] ?? '',
                                  onChanged: (val) async {
                                    await FirestoreService.instance
                                        .updateOrderStatus(
                                        order['docId'] as String,
                                        val);
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
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? kPrimary : kTextHint)),
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
        Expanded(child: Text(text, style: _body, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
            Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) => [
        'Pending', 'Preparing', 'Out for Delivery', 'Delivered', 'Cancelled'
      ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
    );
  }
}