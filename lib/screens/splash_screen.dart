import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:food_delivery_system/admin/screens/admin_home_screen.dart';
import 'package:food_delivery_system/restaurant/screens/restaurant_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } else {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
          return;
        }

        // Handle safe mapping from dynamic firestore payload
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'Customer';

        if (mounted) {
          if (role == 'Admin') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
          } else if (role == 'Restaurant') {
            // Safely fetch and clean string restaurantId parameter from profile
            String linkedId = data['restaurantId']?.toString().trim() ?? "";

            if (linkedId.isEmpty) {
              // If configuration field is missing, bypass auto-login to prevent screens from locking
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            } else {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => RestaurantHomeScreen(restaurantId: linkedId)));
            }
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HomeScreen()));
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.delivery_dining,
                size: 80,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FoodRush',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Delicious food at your door',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}