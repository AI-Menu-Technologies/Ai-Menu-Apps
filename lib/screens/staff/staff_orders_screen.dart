import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/firestore_order_storage.dart';
import '../../data/order_storage.dart';
import '../../models/order.dart' as app_order;

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  bool _syncing = true;
  late Future<String?> _venueIdFuture;

  @override
  void initState() {
    super.initState();
    _venueIdFuture = _loadVenueId();
    _syncLocalOrders();
  }

  Future<String?> _loadVenueId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('staff_users')
        .doc(user.uid)
        .get();

    if (!snapshot.exists) return null;

    final venueId = snapshot.data()?['venueId'];

    if (venueId is! String || venueId.trim().isEmpty) {
      return null;
    }

    return venueId;
  }

  Future<void> _syncLocalOrders() async {
    try {
      final venueId = await _venueIdFuture;

      if (venueId == null || venueId.isEmpty) return;

      final localOrders = await OrderStorage.getOrders();

      for (final order in localOrders) {
        if (order.venueId != venueId) continue;

        await FirestoreOrderStorage.saveOrder(
          order,
          venueId: venueId,
        );
      }
    } catch (e) {
      debugPrint('Ошибка синхронизации заказов: $e');
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case app_order.OrderStatus.newOrder:
        return const Color(0xFFD4AF37);
      case app_order.OrderStatus.accepted:
        return Colors.blue;
      case app_order.OrderStatus.preparing:
        return Colors.orange;
      case app_order.OrderStatus.ready:
        return Colors.green;
      case app_order.OrderStatus.served:
        return Colors.purple;
      case app_order.OrderStatus.completed:
        return Colors.grey;
      default:
        return Colors.white54;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFFD4AF37),
        ),
        title: const Text(
          'Заказы персонала',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<String?>(
        future: _venueIdFuture,
        builder: (context, venueSnapshot) {
          if (venueSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            );
          }

          if (venueSnapshot.hasError) {
            return _message(
              'Ошибка загрузки заведения:\n${venueSnapshot.error}',
            );
          }

          final venueId = venueSnapshot.data;

          if (venueId == null || venueId.isEmpty) {
            return _message(
              'Ваш рабочий аккаунт не привязан к заведению.\n'
              'Обратитесь к владельцу.',
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('venueId', isEqualTo: venueId)
                .snapshots(),
            builder: (context, snapshot) {
              if (_syncing &&
                  snapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFD4AF37),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _message(
                  'Ошибка загрузки заказов:\n${snapshot.error}',
                );
              }

              final documents = snapshot.data?.docs ?? [];

              final orders = <app_order.Order>[];

              for (final document in documents) {
                try {
                  final order = app_order.Order.fromJson(
                    document.data(),
                  );

                  if (order.venueId == venueId) {
                    orders.add(order);
                  }
                } catch (e) {
                  debugPrint(
                    'Ошибка чтения заказа ${document.id}: $e',
                  );
                }
              }

              orders.sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              );

              if (orders.isEmpty) {
                return RefreshIndicator(
                  color: const Color(0xFFD4AF37),
                  backgroundColor: const Color(0xFF151515),
                  onRefresh: _syncLocalOrders,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFFD4AF37),
                        size: 60,
                      ),
                      SizedBox(height: 18),
                      Center(
                        child: Text(
                          'Заказов пока нет',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Новые заказы появятся здесь автоматически.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final newCount = orders
                  .where(
                    (order) =>
                        order.status ==
                        app_order.OrderStatus.newOrder,
                  )
                  .length;

              final activeCount = orders
                  .where(
                    (order) =>
                        order.status !=
                        app_order.OrderStatus.completed,
                  )
                  .length;

              return RefreshIndicator(
                color: const Color(0xFFD4AF37),
                backgroundColor: const Color(0xFF151515),
                onRefresh: _syncLocalOrders,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Активные заказы',
                            value: '$activeCount',
                            icon: Icons.pending_actions,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoCard(
                            title: 'Новые заказы',
                            value: '$newCount',
                            icon: Icons.notifications_active,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...orders.map(
                      (order) => StaffOrderCard(
                        order: order,
                        statusColor: _statusColor(order.status),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _message(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF252525),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFD4AF37),
            size: 25,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StaffOrderCard extends StatelessWidget {
  final app_order.Order order;
  final Color statusColor;

  const StaffOrderCard({
    super.key,
    required this.order,
    required this.statusColor,
  });

  Future<void> _nextStatus() async {
    final nextStatus =
        app_order.OrderStatus.next(order.status);

    if (nextStatus == order.status) return;

    final venueId = order.venueId;

    if (venueId == null || venueId.trim().isEmpty) {
      return;
    }

    await OrderStorage.updateOrderStatus(
      orderNumber: order.orderNumber,
      status: nextStatus,
      venueId: venueId,
    );
  }

  String get buttonText {
    switch (order.status) {
      case app_order.OrderStatus.newOrder:
        return 'Принять заказ';
      case app_order.OrderStatus.accepted:
        return 'Начать готовить';
      case app_order.OrderStatus.preparing:
        return 'Отметить готовым';
      case app_order.OrderStatus.ready:
        return 'Выдать заказ';
      case app_order.OrderStatus.served:
        return 'Завершить заказ';
      case app_order.OrderStatus.completed:
        return 'Заказ завершён';
      default:
        return 'Изменить статус';
    }
  }

  String get dateText {
    final date = order.createdAt;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.${date.year} $hour:$minute';
  }

  String _floorName(int floor) {
    return '$floor этаж';
  }

  Widget _buildTableInfo() {
    if (order.tableName == null ||
        order.tableName!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              color: Colors.white38,
              size: 20,
            ),
            SizedBox(width: 9),
            Text(
              'Стол не указан',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.table_restaurant,
              color: Color(0xFFD4AF37),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'МЕСТО ОБСЛУЖИВАНИЯ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.tableName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (order.floor != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _floorName(order.floor!),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: order.status ==
                  app_order.OrderStatus.newOrder
              ? const Color(0xFFD4AF37)
              : const Color(0xFF242424),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заказ ${order.orderNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _statusText(order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dateText,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),
          _buildTableInfo(),
          const SizedBox(height: 14),
          if (order.customerName.isNotEmpty ||
              order.phone.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.customerName.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Color(0xFFD4AF37),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (order.phone.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          color: Colors.white54,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.phone,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          if (order.customerName.isNotEmpty ||
              order.phone.isNotEmpty)
            const SizedBox(height: 14),
          const Text(
            'СОСТАВ ЗАКАЗА',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 9),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${item.price * item.quantity} сум',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (order.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.comment_outlined,
                    color: Color(0xFFD4AF37),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.comment,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ИТОГО',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${order.total} сум',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  order.status ==
                          app_order.OrderStatus.completed
                      ? null
                      : () async {
                          try {
                            await _nextStatus();
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Не удалось изменить статус: $e',
                                ),
                              ),
                            );
                          }
                        },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF242424),
                disabledForegroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case app_order.OrderStatus.newOrder:
        return 'Новый';
      case app_order.OrderStatus.accepted:
        return 'Принят';
      case app_order.OrderStatus.preparing:
        return 'Готовится';
      case app_order.OrderStatus.ready:
        return 'Готов';
      case app_order.OrderStatus.served:
        return 'Выдан';
      case app_order.OrderStatus.completed:
        return 'Завершён';
      default:
        return 'Неизвестно';
    }
  }
}
