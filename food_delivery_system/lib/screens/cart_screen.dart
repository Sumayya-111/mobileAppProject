// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:food_delivery_system/data/cart_manager.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartManager _cart = CartManager.instance;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever cart changes
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

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _removeItem(int index) => _cart.removeAt(index);

  void _updateQuantity(int index, int delta) =>
      _cart.updateQuantity(index, delta);

  void _clearCart() => _cart.clear();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Cart (${items.length})',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
          icon:
          const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Clear Cart'),
                  content: const Text(
                      'Are you sure you want to remove all items?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () {
                          _clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: items.isEmpty ? _buildEmpty() : _buildCart(items),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          const Text('Your cart is empty',
              style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add some delicious food!',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ── Cart list + summary ───────────────────────────────────────────────────

  Widget _buildCart(List<Map<String, dynamic>> items) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildCartItem(items, index),
          ),
        ),
        _buildSummary(),
      ],
    );
  }

  Widget _buildCartItem(
      List<Map<String, dynamic>> items, int index) {
    final item = items[index];

    return Dismissible(
      key: Key('cart_${item['id']}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(item),
              ),
              const SizedBox(width: 12),
              // Name + price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['name'] ?? '') as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${((item['price'] as num).toDouble()).toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Quantity controls
              _buildQtyControls(index, item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> item) {
    final url = (item['image'] ?? item['img'] ?? '') as String;
    const size = 65.0;

    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(item, size),
      );
    }
    return _imageFallback(item, size);
  }

  Widget _imageFallback(Map<String, dynamic> item, double size) {
    final color = item['color'] != null
        ? Color(item['color'] as int).withOpacity(0.1)
        : const Color(0xFFFF6B35).withOpacity(0.1);
    return Container(
      width: size,
      height: size,
      color: color,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 28),
    );
  }

  Widget _buildQtyControls(int index, Map<String, dynamic> item) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _updateQuantity(index, -1),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove, size: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '${item['quantity']}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        GestureDetector(
          onTap: () => _updateQuantity(index, 1),
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  // ── Order summary ─────────────────────────────────────────────────────────

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        children: [
          // Promo code
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Promo code',
                    prefixIcon: const Icon(Icons.local_offer_outlined,
                        color: Color(0xFFFF6B35)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                ),
                child: const Text('Apply',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _priceRow('Subtotal',
              'Rs ${_cart.subtotal.toStringAsFixed(2)}'),
          _priceRow('Delivery Fee',
              'Rs ${_cart.deliveryFee.toStringAsFixed(2)}'),
          _priceRow('Tax (8%)', 'Rs ${_cart.tax.toStringAsFixed(2)}'),
          const Divider(),
          _priceRow('Total', 'Rs ${_cart.total.toStringAsFixed(2)}',
              isBold: true),
          const SizedBox(height: 16),
          // Checkout button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderConfirmationScreen(
                        total: _cart.total, cartItems: _cart.items),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Proceed to Checkout • Rs ${_cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isBold ? Colors.black : Colors.grey,
                  fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14,
                  color: isBold
                      ? const Color(0xFFFF6B35)
                      : Colors.black)),
        ],
      ),
    );
  }
}
