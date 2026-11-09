import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  int get totalPrice {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(MenuItem menuItem) {
    final index = _items.indexWhere(
      (cartItem) => cartItem.item.id == menuItem.id,
    );

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(
        CartItem(item: menuItem),
      );
    }
  }

  void removeItem(MenuItem menuItem) {
    final index = _items.indexWhere(
      (cartItem) => cartItem.item.id == menuItem.id,
    );

    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
  }

  void clear() {
    _items.clear();
  }
}