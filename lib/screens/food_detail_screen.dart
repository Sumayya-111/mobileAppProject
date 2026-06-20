import 'package:flutter/material.dart';

class FoodDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onAddToCart;
  const FoodDetailScreen(
      {super.key, required this.item, required this.onAddToCart});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _quantity = 1;
  // Selected extras (toppings)
  final Map<String, bool> _extras = {
    'Extra Cheese': false,
    'Extra Sauce': false,
    'Jalapenos': false,
    'Mushrooms': false,
  };
  String _selectedSize = 'Medium';
  final List<String> _sizes = ['Small', 'Medium', 'Large'];

  // Calculate total price based on quantity and extras
  double get _totalPrice {
    double base = widget.item['price'] * _quantity;
    double extrasPrice =
        _extras.values.where((v) => v).length * 1.5; // $1.5 per extra
    return base + extrasPrice;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food image area
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(item['color']).withOpacity(0.15),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        item['image'] ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 300,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.fastfood,
                              size: 100,
                              color: Color(item['color']).withOpacity(0.5)),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.1),
                                          blurRadius: 8)
                                    ],
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new,
                                      size: 18),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8)
                                  ],
                                ),
                                child: const Icon(Icons.favorite_border,
                                    size: 18, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Details
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + price row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(item['name'],
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Text(
                              '\$${item['price'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B35))),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Category tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Color(item['color']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(item['category'],
                            style: TextStyle(
                                color: Color(item['color']),
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(item['description'],
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              height: 1.6)),

                      const SizedBox(height: 20),

                      // Size selection
                      const Text('Choose Size',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: _sizes
                            .map((size) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedSize = size),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedSize == size
                                          ? const Color(0xFFFF6B35)
                                          : Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      size,
                                      style: TextStyle(
                                        color: _selectedSize == size
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 20),

                      // Extras / toppings
                      const Text('Add Extras (+\$1.50 each)',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._extras.entries.map((entry) => CheckboxListTile(
                            title: Text(entry.key),
                            value: entry.value,
                            activeColor: const Color(0xFFFF6B35),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(
                                () => _extras[entry.key] = val ?? false),
                          )),

                      const SizedBox(height: 20),

                      // Quantity selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove, size: 18),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('$_quantity',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _quantity++),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF6B35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 100), // space for bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fixed Add to Cart button at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              child: ElevatedButton(
                onPressed: () {
                  widget.onAddToCart(widget.item);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add $_quantity to Cart',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('\$${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}