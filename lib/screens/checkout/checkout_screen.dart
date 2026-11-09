import 'package:flutter/material.dart';

import '../../data/cart_provider.dart';
import '../../data/order_storage.dart';
import '../../data/table_storage.dart';
import '../../models/order.dart';

class CheckoutScreen extends StatefulWidget {
  final CartProvider cart;

  const CheckoutScreen({
    super.key,
    required this.cart,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentController = TextEditingController();

  bool _isSubmitting = false;
  SelectedTable? _selectedTable;
  bool _isLoadingTable = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedTable();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedTable() async {
    final table = await TableStorage.getSelectedTable();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedTable = table;
      _isLoadingTable = false;
    });
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cart = widget.cart;

    if (cart.items.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Корзина пуста.'),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final total = cart.totalPrice;

      final orderNumber =
          'BN-${DateTime.now().millisecondsSinceEpoch % 100000}';

      final order = Order(
        orderNumber: orderNumber,
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        comment: _commentController.text.trim(),
        total: total,
        status: OrderStatus.newOrder,
        createdAt: DateTime.now(),
        items: cart.items
            .map(
              (item) => OrderItem(
                id: item.item.id,
                name: item.item.name,
                price: item.item.price,
                quantity: item.quantity,
              ),
            )
            .toList(),
        floor: _selectedTable?.floor,
        tableId: _selectedTable?.tableId,
        tableName: _selectedTable?.tableName,
      );

      await OrderStorage.saveOrder(order);

      if (!mounted) {
        return;
      }

      cart.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderNumber: orderNumber,
            total: total,
            table: _selectedTable,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось оформить заказ:\n$e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        title: const Text(
          'Оформление заказа',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Ваши данные',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            _buildTableCard(),

            const SizedBox(height: 20),

            _inputField(
              controller: _nameController,
              label: 'Ваше имя',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите имя';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            _inputField(
              controller: _phoneController,
              label: 'Номер телефона',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите номер телефона';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            _inputField(
              controller: _commentController,
              label: 'Комментарий к заказу',
              icon: Icons.chat_bubble_outline,
              maxLines: 3,
            ),

            const SizedBox(height: 28),

            const Text(
              'Ваш заказ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            ...cart.items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.item.name} × ${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatPrice(item.totalPrice)} сум',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Итого',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    '${_formatPrice(cart.totalPrice)} сум',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF5E501D),
                  disabledForegroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Подтвердить заказ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard() {
    if (_isLoadingTable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD4AF37),
              ),
            ),
            SizedBox(width: 14),
            Text(
              'Загрузка выбранного стола...',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedTable == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              color: Colors.white54,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Стол не выбран. Заказ можно оформить без привязки к столу.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.table_restaurant,
              color: Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ваш стол',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedTable!.tableName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_floorName(_selectedTable!.floor)} · ${_selectedTable!.tableId}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Color(0xFFD4AF37),
          ),
        ],
      ),
    );
  }

  String _floorName(int floor) {
    if (floor == -1) {
      return '-1 этаж';
    }

    if (floor == 1) {
      return '1 этаж';
    }

    if (floor == 2) {
      return '2 этаж';
    }

    if (floor == 3) {
      return '3 этаж';
    }

    return '$floor этаж';
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFD4AF37),
        ),
        filled: true,
        fillColor: const Color(0xFF121212),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD4AF37),
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    final text = price.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(' ');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}

class OrderSuccessScreen extends StatelessWidget {
  final String orderNumber;
  final int total;
  final SelectedTable? table;

  const OrderSuccessScreen({
    super.key,
    required this.orderNumber,
    required this.total,
    this.table,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withValues(
                    alpha: 0.15,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFFD4AF37),
                  size: 52,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Заказ подтверждён',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                orderNumber,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (table != null) ...[
                Text(
                  '${_floorName(table!.floor)} · ${table!.tableName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                'Статус: ${OrderStatus.newOrder}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Спасибо за заказ в Baku Nights',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Сумма: ${_formatPrice(total)} сум',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Вернуться в меню',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _floorName(int floor) {
    if (floor == -1) {
      return '-1 этаж';
    }

    if (floor == 1) {
      return '1 этаж';
    }

    if (floor == 2) {
      return '2 этаж';
    }

    if (floor == 3) {
      return '3 этаж';
    }

    return '$floor этаж';
  }

  static String _formatPrice(int price) {
    final text = price.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(' ');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}
