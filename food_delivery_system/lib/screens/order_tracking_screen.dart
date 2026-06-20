import 'package:flutter/material.dart';

class OrderTrackScreen extends StatefulWidget {
  const OrderTrackScreen({super.key});

  @override
  State<OrderTrackScreen> createState() => _OrderTrackScreenState();
}

class _OrderTrackScreenState extends State<OrderTrackScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _simulateMovement();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _simulateMovement();
    });
  }

  void _simulateMovement() async {
    // Smoothly moves the rider from restaurant to customer
    while (_progress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _progress += 0.01; // Increase for faster movement
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Define coordinates (Adjust these based on where your image icons are)
    const double startTop = 160.0;
    const double startLeft = 60.0;
    const double endTop = 420.0;
    const double endLeft = 250.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Stack(
        children: [
          // 1. THE MAP IMAGE BACKGROUND
          SizedBox(
            height: size.height * 0.75,
            width: double.infinity,
            child: Image.asset(
              'assets/map.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. GRADIENT OVERLAY (Fades the map into the bottom panel)
          Container(
            height: size.height * 0.75,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.white.withOpacity(0.8),
                  Colors.white,
                ],
              ),
            ),
          ),

          // 3. RESTAURANT MARKER
          const Positioned(
            top: startTop,
            left: startLeft,
            child: _LocationMarker(icon: Icons.restaurant, color: Colors.red),
          ),

          // 4. CUSTOMER HOME MARKER
          const Positioned(
            top: endTop,
            left: endLeft,
            child: _LocationMarker(icon: Icons.home, color: Colors.green),
          ),

          // 5. THE MOVING RIDER
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            top: startTop + (endTop - startTop) * _progress,
            left: startLeft + (endLeft - startLeft) * _progress,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Icon(
                Icons.delivery_dining,
                color: Color(0xFFFF6B35),
                size: 30,
              ),
            ),
          ),

          // 6. TOP NAVIGATION BAR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                const Spacer(),
                const SizedBox(width: 40), // Balance for the back button
              ],
            ),
          ),

          // 7. BOTTOM TRACKING PANEL
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 25),

          // Arrival Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Estimated Arrival", style: TextStyle(color: Colors.grey)),
                  Text("10 - 15 mins",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.timer_outlined, color: Color(0xFFFF6B35)),
              )
            ],
          ),

          const SizedBox(height: 25),
          const Divider(),
          const SizedBox(height: 15),

          // Rider Profile
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFFF6B35),
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Zaid Khan",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Your Delivery Hero", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              // Call Button
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: () {},
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Custom widget for consistent markers
class _LocationMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LocationMarker({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        Container(
          width: 2,
          height: 10,
          color: color.withOpacity(0.5),
        ),
      ],
    );
  }
}