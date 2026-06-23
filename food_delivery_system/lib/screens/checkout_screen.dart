import 'package:flutter/material.dart';
import '../data/firestore_service.dart';
import 'order_confirmation_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CHECKOUT SCREEN
// Collects delivery details, payment method, and delivery instructions before
// placing the order. Pre-fills from the user's saved profile so they don't
// have to retype everything each time.
// ═════════════════════════════════════════════════════════════════════════════

class CheckoutScreen extends StatefulWidget {
  final double total;
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({
    super.key,
    required this.total,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _kPrimary = Color(0xFFFF6B35);
  static const _kBg = Color(0xFFF8F5F2);
  static const _kBorder = Color(0xFFE8E5E0);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedPayment = 'Cash on Delivery';
  bool _isLoading = true;

  final List<Map<String, dynamic>> _paymentOptions = [
    {
      'label': 'Cash on Delivery',
      'icon': Icons.payments_outlined,
      'subtitle': 'Pay when your order arrives',
    },
    {
      'label': 'Credit / Debit Card',
      'icon': Icons.credit_card_rounded,
      'subtitle': 'Visa, Mastercard, UnionPay',
    },
    {
      'label': 'EasyPaisa',
      'icon': Icons.account_balance_wallet_outlined,
      'subtitle': 'Pay via EasyPaisa wallet',
    },
    {
      'label': 'JazzCash',
      'icon': Icons.phone_android_rounded,
      'subtitle': 'Pay via JazzCash wallet',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile =
    await FirestoreService.instance.fetchCurrentUserProfile();
    if (mounted) {
      setState(() {
        _nameController.text = profile?['name'] ??
            profile?['displayName'] ?? '';
        _phoneController.text =
            profile?['phoneNumber'] ?? profile?['phone'] ?? '';
        _addressController.text = profile?['address'] ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _proceedToConfirmation() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          total: widget.total,
          cartItems: widget.cartItems,
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          deliveryInstructions: _instructionsController.text.trim(),
          paymentMethod: _selectedPayment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Checkout',
            style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: _kPrimary))
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Order Summary ──────────────────────────────────────────
            _sectionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Order Summary',
              child: Column(
                children: [
                  ...widget.cartItems.map((item) => Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name']} × ${item['quantity']}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF555555)),
                          ),
                        ),
                        Text(
                          'Rs ${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111)),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111))),
                      Text(
                        'Rs ${widget.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _kPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Delivery Details ───────────────────────────────────────
            _sectionCard(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery Details',
              child: Column(
                children: [
                  _inputField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _inputField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Phone number is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _inputField(
                    controller: _addressController,
                    label: 'Delivery Address',
                    icon: Icons.location_on_outlined,
                    hint: 'House #, Street, Area, City',
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Delivery address is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _inputField(
                    controller: _instructionsController,
                    label: 'Delivery Instructions (optional)',
                    icon: Icons.sticky_note_2_outlined,
                    hint: 'e.g. Ring the doorbell, Leave at gate…',
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Payment Method ─────────────────────────────────────────
            _sectionCard(
              icon: Icons.payment_rounded,
              title: 'Payment Method',
              child: Column(
                children: _paymentOptions.map((option) {
                  final isSelected =
                      _selectedPayment == option['label'];
                  return GestureDetector(
                    onTap: () => setState(
                            () => _selectedPayment =
                        option['label'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPrimary.withOpacity(0.06)
                            : const Color(0xFFF8F6F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _kPrimary
                              : _kBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _kPrimary.withOpacity(0.12)
                                  : Colors.white,
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Icon(
                              option['icon'] as IconData,
                              color: isSelected
                                  ? _kPrimary
                                  : const Color(0xFF888888),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(option['label'] as String,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? _kPrimary
                                            : const Color(
                                            0xFF222222))),
                                Text(
                                    option['subtitle'] as String,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF999999),
                                        fontWeight:
                                        FontWeight.w400)),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 180),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected
                                      ? _kPrimary
                                      : _kBorder,
                                  width: isSelected ? 6 : 1.5),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Place Order button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _proceedToConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Place Order • Rs ${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Shared section card container ──────────────────────────────────────────
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kPrimary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111))),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0EEEB)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── Input field helper ─────────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 14, color: Color(0xFF111111)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
        prefixIcon: Icon(icon, color: _kPrimary, size: 18),
        filled: true,
        fillColor: const Color(0xFFF8F6F4),
        alignLabelWithHint: maxLines > 1,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8E5E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8E5E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFFFF6B35), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFFDC2626), width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
      ),
    );
  }
}