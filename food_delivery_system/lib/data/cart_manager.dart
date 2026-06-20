import 'package:flutter/material.dart';

class CartManager extends ChangeNotifier {
  CartManager._();
  static final CartManager instance = CartManager._();

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  int get totalCount =>
      _items.fold(0, (sum, item) => sum + (item['quantity'] as int));

  double get subtotal =>
      _items.fold(0.0, (sum, item) =>
      sum + (item['price'] as double) * (item['quantity'] as int));

  double get deliveryFee => _items.isEmpty ? 0.0 : 2.99;

  double get tax => subtotal * 0.08;

  double get total => subtotal + deliveryFee + tax;

  void addItem(Map<String, dynamic> menuItem) {
    final idx = _items.indexWhere((i) => i['id'] == menuItem['id']);
    if (idx >= 0) {
      _items[idx] = Map<String, dynamic>.from(_items[idx])
        ..['quantity'] = (_items[idx]['quantity'] as int) + 1;
    } else {
      _items.add({...menuItem, 'quantity': 1});
    }
    notifyListeners();
  }

  void updateQuantity(int index, int delta) {
    final newQty = (_items[index]['quantity'] as int) + delta;
    if (newQty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = Map<String, dynamic>.from(_items[index])
        ..['quantity'] = newQty;
    }
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  // Both `clear` and `clearCart` so all screens work
  void clear() {
    _items.clear();
    notifyListeners();
  }

  void clearCart() => clear();

  int quantityOf(dynamic itemId) {
    final idx = _items.indexWhere((i) => i['id'] == itemId);
    return idx >= 0 ? _items[idx]['quantity'] as int : 0;
  }
}