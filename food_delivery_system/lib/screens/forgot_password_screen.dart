import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  // Controller to read what user types in email field
  final TextEditingController _emailController = TextEditingController();

  // Controls the loading spinner on button
  bool _isLoading = false;

  // This is the main function — sends reset email
  Future<void> _sendResetLink() async {

    // Step 1 — Check if email field is empty
    if (_emailController.text.trim().isEmpty) {
      _showError('⚠️ Please enter your email!');
      return; // stop here, don't continue
    }

    // Step 2 — Show loading spinner
    setState(() => _isLoading = true);

    try {
      // Step 3 — Tell Firebase to send reset email
      // Firebase will:
      // - Check if this email exists
      // - Send a password reset link to that email
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      // Step 4 — If we reach here, email was sent ✅
      // Show success message
      if (mounted) {
        _showSuccess('✅ Reset link sent! Check your email.');

        // Wait 2 seconds then go back to login
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      // Step 5 — Handle specific errors
      if (e.code == 'user-not-found') {
        _showError('❌ No account found with this email!');
      } else if (e.code == 'invalid-email') {
        _showError('❌ Invalid email format!');
      } else {
        _showError(e.message ?? 'Something went wrong');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      // Always turn off spinner
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Shows red error message at bottom
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Shows green success message at bottom
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Back button at top
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
          // pop = go back to login screen
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Lock icon at top
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset,
                  size: 40,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Center(
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Center(
              child: Text(
                'Enter your email and we will send\na password reset link',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Email label
            const Text(
              'Email Address',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Email text field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              // opens email keyboard on phone
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFFFF6B35),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF6B35),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Send Reset Link button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetLink,
                // disabled when loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Back to login link
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    text: 'Remember your password? ',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}