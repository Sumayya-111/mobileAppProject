// =============================================
// FIRESTORE SERVICE — Customer panel data access
// =============================================
//
// Centralizes all Firestore reads/writes for the customer panel so the
// collection names and field shapes live in exactly one place. This must
// stay in sync with the schema the admin panel already writes:
//
//   restaurants  { id (int, millisecondsSinceEpoch), name, description,
//                  image, category, rating, deliveryTime, deliveryFee,
//                  priceRange, freeAbove, color }
//
//   menu_items   { id (int), restaurantId (int), name, price, description,
//                  image, icon, color, isPopular, category }
//
//   orders       { id, customerName, customerPhone, restaurantId,
//                  restaurantName, restaurantImage, items (List<String>),
//                  total, status, time, address, userId, createdAt }
//
//   users        { uid, name, displayName, email, phoneNumber, role,
//                  createdAt, lastLoginAt }
//
// All reads return plain Map<String, dynamic> (with the Firestore doc id
// merged in as 'docId') so existing widgets that expect
// Map<String, dynamic>, exactly like the old dummy_data.dart, keep working
// unmodified.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _restaurants =>
      _db.collection('restaurants');
  CollectionReference<Map<String, dynamic>> get _menuItems =>
      _db.collection('menu_items');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Converts a query snapshot into a list of maps, merging in the
  /// Firestore document id as 'docId' (kept separate from the existing
  /// numeric 'id' field already used throughout the app).
  List<Map<String, dynamic>> _docsToMaps(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['docId'] = doc.id;
      return data;
    }).toList();
  }

  // ── Restaurants ────────────────────────────────────────────────────────

  /// Live stream of all restaurants.
  Stream<List<Map<String, dynamic>>> restaurantsStream() {
    return _restaurants.snapshots().map((snap) => _docsToMaps(snap.docs));
  }

  /// One-time fetch of all restaurants.
  Future<List<Map<String, dynamic>>> fetchRestaurants() async {
    final snap = await _restaurants.get();
    return _docsToMaps(snap.docs);
  }

  // ── Menu Items ─────────────────────────────────────────────────────────

  /// Live stream of all menu items (filtered client-side by restaurantId,
  /// same pattern the dummy data used).
  Stream<List<Map<String, dynamic>>> menuItemsStream() {
    return _menuItems.snapshots().map((snap) => _docsToMaps(snap.docs));
  }

  /// Live stream of menu items for a single restaurant.
  /// restaurantId matches the numeric 'id' field on the restaurant doc.
  Stream<List<Map<String, dynamic>>> menuItemsForRestaurantStream(
      dynamic restaurantId) {
    return _menuItems
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snap) => _docsToMaps(snap.docs));
  }

  /// Adds a new menu item document. Mirrors the field shape already used
  /// by the customer panel / dummy data: id, restaurantId, name, price,
  /// description, image, category (icon/color/isPopular optional).
  Future<void> addMenuItem({
    required dynamic restaurantId,
    required String name,
    required double price,
    required String description,
    required String image,
    String category = 'Custom',
  }) async {
    await _menuItems.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'restaurantId': restaurantId,
      'name': name,
      'price': price,
      'description': description,
      'image': image,
      'category': category,
    });
  }

  /// Updates an existing menu item document by its Firestore doc id
  /// (the 'docId' field merged in by _docsToMaps).
  Future<void> updateMenuItem(String docId, Map<String, dynamic> fields) async {
    await _menuItems.doc(docId).update(fields);
  }

  /// Deletes a menu item document by its Firestore doc id.
  Future<void> deleteMenuItem(String docId) async {
    await _menuItems.doc(docId).delete();
  }

  // ── Orders ─────────────────────────────────────────────────────────────

  /// Live stream of all orders belonging to a single restaurant.
  /// restaurantId matches the numeric 'id' field on the restaurant doc.
  Stream<List<Map<String, dynamic>>> ordersForRestaurantStream(
      dynamic restaurantId) {
    return _orders
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snap) => _docsToMaps(snap.docs));
  }

  /// Updates an order's status by its Firestore doc id.
  Future<void> updateOrderStatus(String docId, String status) async {
    await _orders.doc(docId).update({'status': status});
  }

  /// Creates a new order document. Mirrors the exact field shape the
  /// admin panel already reads (id, customerName, customerPhone,
  /// restaurantId, restaurantName, restaurantImage, items, total, status,
  /// time, address) plus userId/createdAt so a customer can later query
  /// their own order history.
  Future<String> createOrder({
    required String customerName,
    required String customerPhone,
    required dynamic restaurantId,
    required String restaurantName,
    required String restaurantImage,
    required List<String> items,
    required double total,
    required String address,
    String deliveryInstructions = '',
    String paymentMethod = 'Cash on Delivery',
  }) async {
    final docRef = _orders.doc();
    final orderId = 'ORD-${docRef.id.substring(0, 6).toUpperCase()}';

    await docRef.set({
      'id': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImage': restaurantImage,
      'items': items,
      'total': total,
      'status': 'Pending',
      'time': 'Just now',
      'address': address,
      'deliveryInstructions': deliveryInstructions,
      'paymentMethod': paymentMethod,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderId;
  }

  /// Live stream of orders placed by the currently signed-in customer.
  Stream<List<Map<String, dynamic>>> myOrdersStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _orders
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => _docsToMaps(snap.docs));
  }

  // ── Users ──────────────────────────────────────────────────────────────

  /// One-time fetch of the current user's profile document.
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['docId'] = doc.id;
    return data;
  }

  /// Live stream of the current user's profile document.
  Stream<Map<String, dynamic>?> currentUserProfileStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['docId'] = doc.id;
      return data;
    });
  }

  Future<void> updateUserProfile(Map<String, dynamic> fields) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _users.doc(uid).update(fields);
  }

  // ── Restaurant Onboarding ──────────────────────────────────────────────
  //
  // Admin creates a restaurant listing + login credentials (email + temp
  // password) without ever signing the admin's own session out. The
  // restaurant's Firebase Auth account is NOT created at this point — it
  // doesn't exist until the restaurant owner's first sign-in attempt with
  // these exact credentials, which login_screen.dart detects and uses to
  // activate the account.

  /// Creates a restaurant listing along with the email/temp password the
  /// restaurant owner will use to activate their account on first login.
  Future<void> createRestaurantWithCredentials({
    required Map<String, dynamic> restaurantFields,
    required String ownerEmail,
    required String tempPassword,
  }) async {
    await _restaurants.add({
      ...restaurantFields,
      'ownerEmail': ownerEmail.trim().toLowerCase(),
      'tempPassword': tempPassword,
      'claimed': false,
      'ownerUid': null,
    });
  }

  /// Looks up an unclaimed restaurant by owner email + temp password.
  /// Returns the restaurant's data (with 'docId') if a match is found,
  /// or null otherwise. Used by login_screen.dart to detect a first-time
  /// restaurant activation attempt before falling back to normal sign-in.
  Future<Map<String, dynamic>?> findUnclaimedRestaurant(
      String email, String password) async {
    final snap = await _restaurants
        .where('ownerEmail', isEqualTo: email.trim().toLowerCase())
        .where('claimed', isEqualTo: false)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final data = Map<String, dynamic>.from(doc.data());
    if (data['tempPassword'] != password) return null;
    data['docId'] = doc.id;
    return data;
  }

  /// Marks a restaurant as claimed and links it to the Auth account that
  /// just activated it. Also clears the temp password since it's no
  /// longer needed (the real Firebase Auth password is now in effect).
  Future<void> claimRestaurant(String restaurantDocId, String ownerUid) async {
    await _restaurants.doc(restaurantDocId).update({
      'claimed': true,
      'ownerUid': ownerUid,
      'tempPassword': FieldValue.delete(),
    });
  }
}
