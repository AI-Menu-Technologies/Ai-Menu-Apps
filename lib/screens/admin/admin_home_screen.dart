import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/order.dart' as app_order;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _AdminOrdersPage(),
    _AdminEmployeesPage(),
    _AdminTablesPage(),
    _AdminMenuPage(),
    _AdminSettingsPage(),
  ];

  final List<String> _titles = const [
    'Заказы',
    'Сотрудники',
    'Столы',
    'Меню',
    'Настройки',
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  void _showAdminMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Меню администратора',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Color(0xFFD4AF37),
                  ),
                  title: const Text(
                    'Выйти',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showAdminMenu,
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF151515),
        indicatorColor:
            const Color(0xFFD4AF37).withValues(alpha: 0.18),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Заказы',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Сотрудники',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_restaurant_outlined),
            selectedIcon: Icon(Icons.table_restaurant),
            label: 'Столы',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Меню',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}

class _AdminOrdersPage extends StatefulWidget {
  const _AdminOrdersPage();

  @override
  State<_AdminOrdersPage> createState() =>
      _AdminOrdersPageState();
}

class _AdminOrdersPageState
    extends State<_AdminOrdersPage> {
  late final Future<String?> _venueIdFuture;

  @override
  void initState() {
    super.initState();
    _venueIdFuture = _loadVenueId();
  }

  Future<String?> _loadVenueId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final staffSnapshot = await FirebaseFirestore.instance
        .collection('staff_users')
        .doc(user.uid)
        .get();

    if (!staffSnapshot.exists) {
      return null;
    }

    final data = staffSnapshot.data();

    final venueId = data?['venueId'];

    if (venueId is! String || venueId.trim().isEmpty) {
      return null;
    }

    return venueId;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ошибка определения заведения:\n'
                '${venueSnapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
          );
        }

        final venueId = venueSnapshot.data;

        if (venueId == null || venueId.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Не удалось определить заведение '
                'для этого аккаунта.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where(
                'venueId',
                isEqualTo: venueId,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Ошибка загрузки заказов:\n'
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4AF37),
                ),
              );
            }

            final documents =
                snapshot.data?.docs ?? [];

            final orders = <app_order.Order>[];

            for (final document in documents) {
              try {
                final data = document.data();
                final order =
                    app_order.Order.fromJson(data);
                orders.add(order);
              } catch (_) {
                // Пропускаем документы,
                // которые не являются полноценными заказами.
              }
            }

            orders.sort(
              (a, b) =>
                  b.createdAt.compareTo(a.createdAt),
            );

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
                          app_order.OrderStatus.completed &&
                      order.status !=
                          app_order.OrderStatus.newOrder,
                )
                .length;

            final completedCount = orders
                .where(
                  (order) =>
                      order.status ==
                      app_order.OrderStatus.completed,
                )
                .length;

            final totalAmount = orders.fold<int>(
              0,
              (total, order) =>
                  total + order.total,
            );

            return RefreshIndicator(
              color: const Color(0xFFD4AF37),
              backgroundColor:
                  const Color(0xFF1A1A1A),
              onRefresh: () async {
                setState(() {
                  _venueIdFuture = _loadVenueId();
                });

                await _venueIdFuture;
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _AdminStatCard(
                          title: 'Всего',
                          value: '${orders.length}',
                          icon: Icons.receipt_long,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AdminStatCard(
                          title: 'Новые',
                          value: '$newCount',
                          icon: Icons.fiber_new,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AdminStatCard(
                          title: 'В работе',
                          value: '$activeCount',
                          icon: Icons.pending_actions,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AdminStatCard(
                          title: 'Завершено',
                          value: '$completedCount',
                          icon:
                              Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AdminStatCard(
                    title: 'Сумма заказов',
                    value:
                        '${totalAmount.toString()} сум',
                    icon: Icons.payments_outlined,
                    wide: true,
                  ),
                  const SizedBox(height: 24),
                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: Colors.white24,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Заказов пока нет',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...orders.map(
                      (order) => _AdminOrderCard(
                        order: order,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool wide;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFD4AF37).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
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

class _AdminOrderCard extends StatelessWidget {
  final app_order.Order order;

  const _AdminOrderCard({
    required this.order,
  });

  Color _statusColor() {
    switch (order.status) {
      case app_order.OrderStatus.newOrder:
        return Colors.orange;
      case app_order.OrderStatus.accepted:
        return Colors.blue;
      case app_order.OrderStatus.preparing:
        return Colors.amber;
      case app_order.OrderStatus.ready:
        return Colors.green;
      case app_order.OrderStatus.served:
        return Colors.teal;
      case app_order.OrderStatus.completed:
        return Colors.white54;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (order.floor != null || order.tableName != null)
            Row(
              children: [
                const Icon(
                  Icons.table_restaurant,
                  color: Color(0xFFD4AF37),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  [
                    if (order.floor != null)
                      'Этаж ${order.floor}',
                    if (order.tableName != null &&
                        order.tableName!.isNotEmpty)
                      order.tableName!,
                  ].join(' • '),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          if (order.floor != null || order.tableName != null)
            const SizedBox(height: 10),
          Text(
            order.customerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (order.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              order.phone,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} × ${item.quantity}',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Text(
                    '${item.price * item.quantity} сум',
                    style: const TextStyle(
                      color: Colors.white70,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Комментарий: ${order.comment}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Итого',
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),
              Text(
                '${order.total} сум',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminEmployeesPage extends StatelessWidget {
  const _AdminEmployeesPage();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonPage(
      icon: Icons.people_outline,
      title: 'Сотрудники',
      description:
          'Здесь будет управление официантами, администраторами и другими сотрудниками.',
    );
  }
}

class _AdminTablesPage extends StatelessWidget {
  const _AdminTablesPage();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonPage(
      icon: Icons.table_restaurant_outlined,
      title: 'Столы',
      description:
          'Здесь будет управление этажами, столами, кабинками и их состоянием.',
    );
  }
}

class _AdminMenuPage extends StatelessWidget {
  const _AdminMenuPage();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonPage(
      icon: Icons.restaurant_menu_outlined,
      title: 'Меню',
      description:
          'Здесь будет управление категориями, блюдами, ценами и доступностью.',
    );
  }
}

class _AdminSettingsPage extends StatelessWidget {
  const _AdminSettingsPage();

  void _showDeleteVenueDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Удалить заведение?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Это опасное действие. После подключения Firebase оно '
            'будет использоваться для удаления заведения и связанных '
            'с ним данных.\n\n'
            'Сейчас удаление ещё не выполняется, потому что система '
            'регистрации заведений находится в разработке.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF242424),
                    content: Text(
                      'Удаление будет подключено после '
                      'завершения Firebase-регистрации.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
              child: const Text(
                'Удалить',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      children: [
        const Text(
          'Настройки заведения',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Управление основными параметрами заведения.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: Color(0xFFD4AF37),
                size: 28,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Основные настройки',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Этот раздел будет расширен при подключении '
                      'полной панели управления заведением.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF160D0D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.35),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showDeleteVenueDialog(context),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.redAccent,
                    size: 30,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Удалить заведение',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Удаление заведения и связанных данных',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ComingSoonPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFD4AF37).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFD4AF37),
                size: 46,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
