import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'restaurant_detail_screen.dart';
import '../data/cart_manager.dart';
import 'order_tracking_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final double total;
  const OrderConfirmationScreen({super.key, required this.total});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Fake order tracking steps
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

    // Clear cart after order
    CartManager.instance.clearCart();
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
            child: Column(
              children: [
                const Spacer(),

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
                          Text('#FR${DateTime.now().millisecondsSinceEpoch % 100000}',
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
                              '\$${widget.total.toStringAsFixed(2)}',
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

                const Spacer(),

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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderTrackScreen(),
                          ),
                        );
                      },
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: Color(0xFFFF6B35)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Track Order',
                        style: TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}