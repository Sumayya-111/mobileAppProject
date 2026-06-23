import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'order_tracking_screen.dart';
import '../data/cart_manager.dart';
import '../data/firestore_service.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final double total;
  final List<Map<String, dynamic>> cartItems;
  final String customerName;
  final String customerPhone;
  final String address;
  final String deliveryInstructions;
  final String paymentMethod;

  const OrderConfirmationScreen({
    super.key,
    required this.total,
    required this.cartItems,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.deliveryInstructions,
    required this.paymentMethod,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}


class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Real order id, filled in once Firestore write completes.
  String? _orderId;
  bool _isPlacingOrder = true;
  String? _orderError;

  // Fake order tracking steps (visual only — unchanged)
  final List<Map<String, dynamic>> _steps = [
    {'label': 'Order Placed', 'icon': Icons.check_circle, 'done': true},
    {'label': 'Preparing', 'icon': Icons.restaurant, 'done': true},
    {'label': 'On the Way', 'icon': Icons.delivery_dining, 'done': false},
    {'label': 'Delivered', 'icon': Icons.home, 'done': false},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();

    _placeOrder();

    // Clear cart after order
    CartManager.instance.clearCart();
  }

  Future<void> _placeOrder() async {
    try {
      if (widget.cartItems.isEmpty) {
        setState(() {
          _isPlacingOrder = false;
          _orderError = 'Cart is empty';
        });
        return;
      }

      final firstItem = widget.cartItems.first;
      final restaurantId = firstItem['restaurantId'];

      final restaurants =
      await FirestoreService.instance.fetchRestaurants();
      final restaurant = restaurants.firstWhere(
            (r) => r['id'] == restaurantId,
        orElse: () => <String, dynamic>{},
      );

      final itemStrings = widget.cartItems
          .map((i) => '${i['name']} x${i['quantity']}')
          .toList();

      final orderId = await FirestoreService.instance.createOrder(
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        restaurantId: restaurantId,
        restaurantName: (restaurant['name'] ?? '') as String,
        restaurantImage: (restaurant['image'] ?? '') as String,
        items: itemStrings,
        total: widget.total,
        address: widget.address,
        deliveryInstructions: widget.deliveryInstructions,
        paymentMethod: widget.paymentMethod,
      );

      if (mounted) {
        setState(() {
          _orderId = orderId;
          _isPlacingOrder = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
          _orderError = 'Could not place order. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Success animation
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 70),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Order Confirmed! 🎉',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                      'Your order has been placed successfully.\nEstimated delivery: 25-35 minutes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          height: 1.5)),
                  if (_orderError != null) ...[
                    const SizedBox(height: 10),
                    Text(_orderError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ],

                  const SizedBox(height: 30),

                  // Order ID + Total
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Order ID',
                                style: TextStyle(color: Colors.grey)),
                            _isPlacingOrder
                                ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF6B35)),
                            )
                                : Text(_orderId ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Paid',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                                'Rs ${widget.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6B35),
                                    fontSize: 18)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment',
                                style: TextStyle(color: Colors.grey)),
                            Row(children: [
                              const Icon(Icons.credit_card,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('**** 4242',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Order tracking steps
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Order Tracking',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_steps.length * 2 - 1, (i) {
                      if (i.isOdd) {
                        // Connector line between steps
                        final stepIndex = i ~/ 2;
                        final isDone = _steps[stepIndex]['done'] as bool;
                        return Expanded(
                          child: Container(
                            height: 3,
                            color: isDone
                                ? const Color(0xFFFF6B35)
                                : Colors.grey.shade200,
                          ),
                        );
                      }
                      final step = _steps[i ~/ 2];
                      final isDone = step['done'] as bool;
                      return Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFFFF6B35)
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(step['icon'] as IconData,
                                color: isDone
                                    ? Colors.white
                                    : Colors.grey,
                                size: 20),
                          ),
                          const SizedBox(height: 6),
                          Text(step['label'] as String,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDone
                                      ? const Color(0xFFFF6B35)
                                      : Colors.grey,
                                  fontWeight: isDone
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Back to Home button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                                (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Back to Home',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  // const SizedBox(height: 12),
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 56,
                  //   child: OutlinedButton(
                  //     onPressed: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (_) => const OrderTrackScreen(),
                  //         ),
                  //       );
                  //     },
                  //     style: OutlinedButton.styleFrom(
                  //       side:
                  //       const BorderSide(color: Color(0xFFFF6B35)),
                  //       shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(14)),
                  //     ),
                  //     child: const Text('Track Order',
                  //         style: TextStyle(
                  //             color: Color(0xFFFF6B35),
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.bold)),
                  //   ),
                  // ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}