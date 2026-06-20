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

  Future<void> _signInWithGitHub() async {
    setState(() => _isLoading = true);

    try {
      GithubAuthProvider githubProvider = GithubAuthProvider();
      githubProvider.addScope('read:user');
      githubProvider.addScope('user:email');

      UserCredential userCredential;

      if (kIsWeb) {
        // Web — use popup
        userCredential = await FirebaseAuth.instance
            .signInWithPopup(githubProvider);
      } else {
        // Mobile — use provider
        userCredential = await FirebaseAuth.instance
            .signInWithProvider(githubProvider);
      }

      // Save to Firestore if new user
      bool isNewUser = userCredential.additionalUserInfo!.isNewUser;
      if (isNewUser) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name':      userCredential.user!.displayName ?? '',
          'email':     userCredential.user!.email ?? '',
          'role':      'Customer',
          'createdAt': Timestamp.now(),
        });
      }

      // Fetch role and navigate
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      String dbRole = userDoc.get('role');

      if (mounted) {
        if (dbRole == 'Admin') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
        } else if (dbRole == 'Restaurant') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const RestaurantHomeScreen()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
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

  // Step 1 — show loading spinner
  setState(() => _isLoading = true);

  try {

    // Step 2 — Open the Google account picker popup
    // This is the screen where user picks their Google account
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: kIsWeb 
            ? '542358620373-l7hfj3eqkdt5u1ogn78hoogfb1l47usv.apps.googleusercontent.com'
            : null,
        serverClientId: kIsWeb 
            ? null 
            : '542358620373-0122100sonj7e3ik0osrdjsbbukj62ki.apps.googleusercontent.com',
      ).signIn();

    // Step 3 — If user closed the popup without picking
    // googleUser will be null, so we stop here
    if (googleUser == null) {
      setState(() => _isLoading = false);
      return; // user cancelled, do nothing
    }

    // Step 4 — Get the security tokens from Google
    // Think of these like a temporary pass Google gives us
    // to prove the user really signed in with Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Step 5 — Convert Google tokens into Firebase credential
    // Firebase needs its own format of the proof
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    // Step 6 — Sign into Firebase using the credential
    // This is like showing the proof to Firebase
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // Step 7 — Check if this is a NEW user or existing user
    // isNewUser = true  means first time signing in with Google
    // isNewUser = false means they signed in with Google before
    bool isNewUser = userCredential.additionalUserInfo!.isNewUser;

    if (isNewUser) {
      // Step 8 — New user: save their info to Firestore
      // because we need their role in the database
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name':      userCredential.user!.displayName ?? '',
        // displayName comes from their Google account name
        'email':     userCredential.user!.email ?? '',
        'role':      'Customer', // default role for Google users
        'createdAt': Timestamp.now(),
      });
    }

    // Step 9 — Get their role from Firestore
    // same as your regular login does
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    String dbRole = userDoc.get('role');

    // Step 10 — Navigate based on role
    if (mounted) {
      if (dbRole == 'Admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
      } else if (dbRole == 'Restaurant') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const RestaurantHomeScreen()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    }

  } on FirebaseAuthException catch (e) {
    // Firebase specific error
    _showError(e.message ?? 'Google sign in failed');

  } catch (e) {
    // Any other error
    _showError('Google sign in failed: $e');

  } finally {
    // Always turn off spinner at the end
    // whether it worked or failed
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
      // 1. Sign in with Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Fetch User Role from Firestore (No need to select role on login page anymore)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        _showError('User record not found in database.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      String dbRole = userDoc.get('role');

      // 3. Navigate based on role found in Database
      if (mounted) {
        if (dbRole == 'Admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
        } else if (dbRole == 'Restaurant') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
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
                          BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
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
                    shadowColor: const Color(0xFFFF6B35).withValues(alpha: 0.4),
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
