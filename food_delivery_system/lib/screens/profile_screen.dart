import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Toggle variables for settings section
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  bool _locationOn = true;

  // Firebase Auth current user
  // gives us email, photoURL, uid etc
  final User? _user = FirebaseAuth.instance.currentUser;

  // Will hold all data from Firestore
  // like name, phone, role, authProvider
  Map<String, dynamic>? _userData;

  // Controls loading spinner while fetching data
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Runs automatically when screen opens
    // immediately fetches user data from Firestore
    _fetchUserData();
  }

  // Fetches user details from Firestore
  Future<void> _fetchUserData() async {
    try {
      // Go to users collection → find this user's document
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid) // uid is the unique ID of logged in user
          .get();

      if (doc.exists) {
        setState(() {
          // Store all fields in _userData
          _userData = doc.data() as Map<String, dynamic>;
          _isLoading = false; // hide spinner
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Shows logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _LogoutDialog(
        onConfirm: () async {
          // Sign out from Firebase first
          await FirebaseAuth.instance.signOut();
          // Then navigate to login
          // pushAndRemoveUntil removes ALL screens from history
          // so back button won't work after logout
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  // Formats Firestore timestamp to readable date
  // Example: DateTime(2026, 5, 23) → "23 May 2026"
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // Show spinner while loading data from Firestore
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [

                  // ── Header with gradient ───────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 60, bottom: 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [

                        // Profile picture
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              // Show Google profile photo if available
                              backgroundImage: _user?.photoURL != null
                                  ? NetworkImage(_user!.photoURL!)
                                  : null,
                              // If no Google photo, show first letter of name
                              child: _user?.photoURL == null
                                  ? Text(
                                      (_userData?['name'] ??
                                              _user?.displayName ??
                                              _user?.email ??
                                              'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF6B35)),
                                    )
                                  : null,
                            ),
                            // Camera icon for future photo update
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 16, color: Color(0xFFFF6B35)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Real name from Firestore
                        Text(
                          _userData?['name'] ??
                              _user?.displayName ??
                              'User',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),

                        // Real email from Firebase Auth
                        Text(
                          _userData?['email'] ?? _user?.email ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),

                        // Role badge from Firestore
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _userData?['role'] ?? 'User',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statCard('Orders', '24'),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.white38),
                            _statCard('Reviews', '12'),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.white38),
                            _statCard('Points', '580'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Account Info Section ───────────────────
                  _sectionHeader('Account Info'),

                  // Phone number from Firestore
                  _infoTile(
                    Icons.phone_outlined,
                    'Phone Number',
                    _userData?['phoneNumber'] ?? 'Not provided',
                  ),

                  // Auth provider (email/google/phone)
                  _infoTile(
                    Icons.login_outlined,
                    'Signed in with',
                    _userData?['authProvider'] ?? 'email',
                  ),

                  // Member since date
                  _infoTile(
                    Icons.calendar_today_outlined,
                    'Member Since',
                    _userData?['createdAt'] != null
                        ? _formatDate(_userData!['createdAt'].toDate())
                        : 'Unknown',
                  ),

                  const SizedBox(height: 16),

                  // ── Account Actions Section ────────────────
                  _sectionHeader('Account'),
                  _menuTile(Icons.person_outline, 'Edit Profile', onTap: () {
                    _showEditProfileDialog(context);
                  }),
                  _menuTile(Icons.location_on_outlined, 'Saved Addresses'),
                  _menuTile(Icons.payment_outlined, 'Payment Methods'),
                  _menuTile(Icons.history, 'Order History'),

                  const SizedBox(height: 16),

                  // ── Settings Section ───────────────────────
                  _sectionHeader('Settings'),
                  _switchTile(
                      Icons.notifications_outlined,
                      'Push Notifications',
                      _notificationsOn, (val) {
                    setState(() => _notificationsOn = val);
                  }),
                  _switchTile(Icons.dark_mode_outlined, 'Dark Mode',
                      _darkModeOn, (val) {
                    setState(() => _darkModeOn = val);
                  }),
                  _switchTile(Icons.location_on_outlined, 'Location Services',
                      _locationOn, (val) {
                    setState(() => _locationOn = val);
                  }),

                  const SizedBox(height: 16),

                  // ── Support Section ────────────────────────
                  _sectionHeader('Support'),
                  _menuTile(Icons.help_outline, 'Help & FAQ'),
                  _menuTile(Icons.privacy_tip_outlined, 'Privacy Policy'),
                  _menuTile(Icons.info_outline, 'About FoodRush'),

                  const SizedBox(height: 16),

                  // ── Logout Button ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Logout',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── Info tile — shows label + value (no tap) ───────────────
  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B35), size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ),
    );
  }

  // ── Stat card in header ────────────────────────────────────
  Widget _statCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 1)),
      ),
    );
  }

  // ── Menu tile with arrow ───────────────────────────────────
  Widget _menuTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B35), size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: Colors.grey),
        onTap: onTap ?? () {},
      ),
    );
  }

  // ── Switch tile ────────────────────────────────────────────
  Widget _switchTile(IconData icon, String title, bool value,
      Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B35), size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFF6B35),
        ),
      ),
    );
  }

  // ── Edit profile dialog ────────────────────────────────────
  void _showEditProfileDialog(BuildContext context) {
    // Pre-fill with current data from Firestore
    final nameController = TextEditingController(
        text: _userData?['name'] ?? '');
    final phoneController = TextEditingController(
        text: _userData?['phoneNumber'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration:
                  const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update Firestore with new values
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid)
                    .update({
                  'name':        nameController.text.trim(),
                  'phoneNumber': phoneController.text.trim(),
                });

                // Update Firebase Auth display name too
                await _user!.updateDisplayName(
                    nameController.text.trim());

                // Refresh the screen data
                await _fetchUserData();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Profile updated!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35)),
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LOGOUT DIALOG
// ═══════════════════════════════════════════════════════════════

class _LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _LogoutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red power icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                color: Color(0xFFDC2626),
                size: 30,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'You will be logged out of your account.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Cancel + Sign Out buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFEDEBE8), width: 1.5),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}