import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:food_delivery_system/restaurant/screens/restaurant_home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  
  String _selectedRole = 'User'; // Default role
  final List<String> _roles = ['User', 'Restaurant', 'Admin'];

  Future<void> _signUp() async {
  // Validation checks
  if (_nameController.text.isEmpty ||
      _emailController.text.isEmpty ||
      _passwordController.text.isEmpty) {
    _showError('⚠️ Please fill all fields!');
    return;
  }

  if (_passwordController.text != _confirmPasswordController.text) {
    _showError('❌ Passwords do not match!');
    return;
  }

  if (_passwordController.text.length < 8) {
    _showError('❌ Password must be at least 8 characters!');
    return;
  }

  if (!_agreeToTerms) {
    _showError('Please agree to terms first');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Step 1 — Create account in Firebase Auth
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email:    _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Step 2 — Update display name in Firebase Auth
    await userCredential.user!.updateDisplayName(
      _nameController.text.trim(),
    );

    // Step 3 — Save all details to Firestore users collection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'uid':          userCredential.user!.uid,
      'displayName':  _nameController.text.trim(),
      'name':         _nameController.text.trim(),
      'email':        _emailController.text.trim(),
      'phoneNumber':  _phoneController.text.trim(),
      'photoURL':     '',
      'authProvider': 'email',
      'role':         _selectedRole,
      'createdAt':    FieldValue.serverTimestamp(),
      'lastLoginAt':  FieldValue.serverTimestamp(),
    });

    // Step 4 — Send email verification
    await userCredential.user!.sendEmailVerification();

    // Step 5 — Go back to login
    if (mounted) {
      _showSuccess('✅ Account created! Please verify your email.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }

  } on FirebaseAuthException catch (e) {
    // Show specific error messages
    if (e.code == 'email-already-in-use') {
      _showError('❌ This email is already registered!');
    } else if (e.code == 'weak-password') {
      _showError('❌ Password is too weak!');
    } else if (e.code == 'invalid-email') {
      _showError('❌ Invalid email format!');
    } else {
      _showError(e.message ?? 'Signup failed');
    }
  } catch (e) {
    _showError('An error occurred: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: const Color(0xFFFF6B35)),
            suffixIcon: toggleObscure != null
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                    onPressed: toggleObscure,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2)),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Account 🎉', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Fill in the details to get started', style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 30),

            _buildTextField(controller: _nameController, label: 'Full Name', hint: 'John Doe', icon: Icons.person_outline),
            _buildTextField(controller: _emailController, label: 'Email Address', hint: 'you@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            _buildTextField(controller: _phoneController, label: 'Phone Number', hint: '+1 234 567 8900', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            
            // Role Selection
            const Text('Select Role', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF6B35)),
                  items: _roles.map((String role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                  onChanged: (String? newVal) => setState(() => _selectedRole = newVal!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(controller: _passwordController, label: 'Password', hint: '••••••••', icon: Icons.lock_outline, obscure: _obscurePassword, toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
            _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', hint: '••••••••', icon: Icons.lock_outline, obscure: _obscureConfirm, toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm)),

            Row(
              children: [
                Checkbox(value: _agreeToTerms, activeColor: const Color(0xFFFF6B35), onChanged: (val) => setState(() => _agreeToTerms = val ?? false)),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      children: [
                        TextSpan(text: 'Terms & Conditions', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
                        TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Account', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: TextStyle(color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Login', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
