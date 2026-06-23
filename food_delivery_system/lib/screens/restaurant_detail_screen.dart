import 'package:flutter/material.dart';
import 'package:food_delivery_system/data/cart_manager.dart';
import '../data/firestore_service.dart';
import 'food_detail_screen.dart';
import 'cart_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Popular', 'Pizza', 'Burger', 'Sushi'];

  final CartManager _cart = CartManager.instance;

  late final Stream<List<Map<String, dynamic>>> _menuItemsStream =
  FirestoreService.instance
      .menuItemsForRestaurantStream(widget.restaurant['id']);

  void _addToCart(Map<String, dynamic> item) {
    _cart.addItem({
      'id':                   item['id'],
      'name':                 item['name'],
      'price':                (item['price'] as num).toDouble(),
      'image':                item['image'] ?? item['img'] ?? '',
      'color':                item['color'] ?? 0xFFFF6B35,
      'restaurantId':         item['restaurantId'] ?? widget.restaurant['id'],
      'restaurantDeliveryFee': widget.restaurant['deliveryFee'] ?? '',
    });

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${item['name']} added to cart!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Listen to cart changes so badge stays in sync
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B35),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 18),
              ),
            ),
            actions: [
              // Cart icon with live badge
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: Colors.black),
                      if (_cart.totalCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              '${_cart.totalCount}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    r['image'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Color((r['color'] ?? 0xFFFF6B35) as int),
                      child: const Icon(Icons.restaurant,
                          size: 80, color: Colors.white),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Restaurant info card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (r['name'] ?? '') as String,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${r['rating'] ?? ''}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (r['description'] ?? r['desc'] ?? '') as String,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _infoChip(Icons.access_time,
                          (r['deliveryTime'] ?? r['time'] ?? '') as String,
                          Colors.blue),
                      const SizedBox(width: 10),
                      _infoChip(Icons.delivery_dining,
                          (r['deliveryFee'] ?? '') as String, Colors.green),
                      const SizedBox(width: 10),
                      _infoChip(Icons.restaurant,
                          (r['category'] ?? r['tag'] ?? '') as String,
                          Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFFFF6B35),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF6B35),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),

            // Menu items
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _menuItemsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(
                        color: Color(0xFFFF6B35)));
                  }
                  final menuItemsList = snapshot.data ?? const [];
                  return menuItemsList.isEmpty
                      ? const Center(child: Text('No items available'))
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: menuItemsList.length,
                    itemBuilder: (context, index) {
                      final item = menuItemsList[index];
                      final int qtyInCart =
                      _cart.quantityOf(item['id']);

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodDetailScreen(
                                item: item,
                                onAddToCart: _addToCart),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              //  Food image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: Image.network(
                                  (item['image'] ?? item['img'] ?? '')
                                  as String,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Color(
                                        (item['color'] ??
                                            0xFFFF6B35) as int)
                                        .withOpacity(0.1),
                                    child: const Icon(Icons.fastfood,
                                        color: Colors.grey, size: 36),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      if (item['isPopular'] == true)
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange
                                                .withOpacity(0.1),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: const Text('🔥 Popular',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.orange,
                                                  fontWeight:
                                                  FontWeight.bold)),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['name'] ?? '') as String,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['description'] ?? '') as String,
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Rs ${((item['price'] as num).toDouble()).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFFFF6B35)),
                                          ),
                                          qtyInCart == 0
                                              ? GestureDetector(
                                            onTap: () =>
                                                _addToCart(item),
                                            child: Container(
                                              padding:
                                              const EdgeInsets
                                                  .all(6),
                                              decoration:
                                              const BoxDecoration(
                                                color:
                                                Color(0xFFFF6B35),
                                                shape:
                                                BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 18),
                                            ),
                                          )
                                              : _InlineQtyControl(
                                            quantity: qtyInCart,
                                            onAdd: () =>
                                                _addToCart(item),
                                            onRemove: () {
                                              final idx = _cart.items
                                                  .indexWhere((c) =>
                                              c['id'] ==
                                                  item['id']);
                                              if (idx >= 0) {
                                                _cart.updateQuantity(
                                                    idx, -1);
                                                setState(() {});
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _InlineQtyControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _InlineQtyControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child:
              Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}