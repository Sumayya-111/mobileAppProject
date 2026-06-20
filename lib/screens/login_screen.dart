import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'package:food_delivery_system/admin/screens/admin_home_screen.dart';
import 'package:food_delivery_system/restaurant/screens/restaurant_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleRoleBasedNavigation(DocumentSnapshot userDoc) {
    if (!userDoc.exists) {
      _showError('User database configurations not found.');
      FirebaseAuth.instance.signOut();
      return;
    }

    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    String dbRole = data['role'] ?? 'Customer';

    if (dbRole == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else if (dbRole == 'Restaurant') {
      String linkedId = data['restaurantId']?.toString().trim() ?? "";

      if (linkedId.isEmpty) {
        _showError("⚠️ Setup Incomplete: This account doesn't have an assigned 'restaurantId' field yet!");
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RestaurantHomeScreen(restaurantId: linkedId)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _signInWithGitHub() async {
    setState(() => _isLoading = true);

    try {
      GithubAuthProvider githubProvider = GithubAuthProvider();
      githubProvider.addScope('read:user');
      githubProvider.addScope('user:email');

      UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await FirebaseAuth.instance.signInWithPopup(githubProvider);
      } else {
        userCredential = await FirebaseAuth.instance.signInWithProvider(githubProvider);
      }

      bool isNewUser = userCredential.additionalUserInfo!.isNewUser;
      if (isNewUser) {
        // Automatic dynamic reference setup configuration for third-party OAuth links
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid':       userCredential.user!.uid,
          'name':      userCredential.user!.displayName ?? '',
          'email':     userCredential.user!.email ?? '',
          'role':      'Customer',
          'restaurantId': '',
          'createdAt': Timestamp.now(),
        });
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (mounted) {
        _handleRoleBasedNavigation(userDoc);
      }

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'GitHub sign in failed');
    } catch (e) {
      _showError('GitHub sign in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: kIsWeb
            ? '542358620373-l7hfj3eqkdt5u1ogn78hoogfb1l47usv.apps.googleusercontent.com'
            : null,
        serverClientId: kIsWeb
            ? null
            : '542358620373-0122100sonj7e3ik0osrdjsbbukj62ki.apps.googleusercontent.com',
      ).signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      bool isNewUser = userCredential.additionalUserInfo!.isNewUser;

      if (isNewUser) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid':       userCredential.user!.uid,
          'name':      userCredential.user!.displayName ?? '',
          'email':     userCredential.user!.email ?? '',
          'role':      'Customer',
          'restaurantId': '',
          'createdAt': Timestamp.now(),
        });
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (mounted) {
        _handleRoleBasedNavigation(userDoc);
      }

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign in failed');
    } catch (e) {
      _showError('Google sign in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('⚠️ Please fill in all fields!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (mounted) {
        _handleRoleBasedNavigation(userDoc);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email to reset password');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      _showError('Failed to send reset link: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.delivery_dining, size: 55, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text('Welcome Back! 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Login to continue ordering', style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF6B35)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2)),
                ),
              ),

              const SizedBox(height: 20),

              const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF6B35)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2)),
                ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text('Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: const Color(0xFFFF6B35).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Text('G',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35))),
                  label: const Text('Continue with Google',
                      style: TextStyle(fontSize: 16, color: Colors.black87)),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGitHub,
                  icon: const Icon(
                    Icons.code,
                    color: Colors.black87,
                    size: 22,
                  ),
                  label: const Text(
                    'Continue with GitHub',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Sign Up', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}