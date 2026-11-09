import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/table_service.dart';
import '../../data/table_storage.dart';
import '../menu/menu_screen.dart';

class TableSelectionScreen extends StatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  int? _selectedFloor;
  String? _selectingTableId;

  final List<int> _floors = [-1, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    _selectedFloor = 2;
  }

  List<TableInfo> _getTablesForFloor(int floor) {
    switch (floor) {
      case -1:
        return [
          TableInfo(
            id: 'karaoke_-1_1',
            name: 'Караоке 1',
            description: '5–10 человек',
            icon: Icons.mic,
          ),
          TableInfo(
            id: 'karaoke_-1_2',
            name: 'Караоке 2',
            description: '5–10 человек',
            icon: Icons.mic,
          ),
          TableInfo(
            id: 'karaoke_-1_3',
            name: 'Караоке 3',
            description: '5–10 человек',
            icon: Icons.mic,
          ),
        ];

      case 1:
        return [
          TableInfo(
            id: 'karaoke_1_1',
            name: 'Караоке 1',
            description: '5–10 человек',
            icon: Icons.mic,
          ),
          TableInfo(
            id: 'karaoke_1_2',
            name: 'Караоке 2',
            description: '5–10 человек',
            icon: Icons.mic,
          ),
        ];

      case 2:
        return [
          TableInfo(
            id: 'table_2_1',
            name: 'Стол 1',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_2_2',
            name: 'Стол 2',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_2_3',
            name: 'Стол 3',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_2_4',
            name: 'Стол 4',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_2_5',
            name: 'Стол 5',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'ps5_2_1',
            name: 'PlayStation 5 — 1',
            description: '2–4 человека',
            icon: Icons.sports_esports,
          ),
          TableInfo(
            id: 'ps5_2_2',
            name: 'PlayStation 5 — 2',
            description: '2–4 человека',
            icon: Icons.sports_esports,
          ),
        ];

      case 3:
        return [
          TableInfo(
            id: 'table_3_1',
            name: 'Стол 1',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_3_2',
            name: 'Стол 2',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_3_3',
            name: 'Стол 3',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_3_4',
            name: 'Стол 4',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_3_5',
            name: 'Стол 5',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_3_6',
            name: 'Стол 6',
            description: 'До 4 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'table_3_7',
            name: 'Стол 7',
            description: 'До 6 человек',
            icon: Icons.table_restaurant,
          ),
          TableInfo(
            id: 'cocoon_3_1',
            name: 'Кокон',
            description: 'До 2 человек',
            icon: Icons.chair,
          ),
        ];

      default:
        return [];
    }
  }

  Future<void> _selectTable(TableInfo table) async {
    if (_selectingTableId != null) return;

    final floor = _selectedFloor;
    if (floor == null) return;

    setState(() {
      _selectingTableId = table.id;
    });

    final result = await TableService.reserveTable(
      floor: floor,
      tableId: table.id,
      tableName: table.name,
    );

    if (!mounted) return;

    setState(() {
      _selectingTableId = null;
    });

    if (result.isAlreadyTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Этот столик уже занят или забронирован. Пожалуйста, выберите другой.',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Не удалось выбрать столик.',
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    await TableStorage.saveTable(
      floor: floor,
      tableId: table.id,
      tableName: table.name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${table.name} выбран'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {});
  }

  void _openMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MenuScreen(),
      ),
    );
  }

  String _floorTitle(int floor) {
    if (floor == -1) {
      return '-1 этаж';
    }

    return '$floor этаж';
  }

  @override
  Widget build(BuildContext context) {
    final tables = _selectedFloor == null
        ? <TableInfo>[]
        : _getTablesForFloor(_selectedFloor!);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Выбрать столик',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFD4AF37),
        ),
        actions: [
          IconButton(
            tooltip: 'Меню',
            onPressed: _openMenu,
            icon: const Icon(
              Icons.restaurant_menu,
              color: Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const _StatusLegend(
                  color: Color(0xFF2E7D32),
                  text: 'Свободен',
                ),
                const SizedBox(width: 18),
                const _StatusLegend(
                  color: Color(0xFFC62828),
                  text: 'Занят',
                ),
                const SizedBox(width: 18),
                const _StatusLegend(
                  color: Color(0xFFD4AF37),
                  text: 'Ваш',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _floors.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final floor = _floors[index];
                final selected = _selectedFloor == floor;

                return GestureDetector(
                  onTap: _selectingTableId != null
                      ? null
                      : () {
                          setState(() {
                            _selectedFloor = floor;
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF333333),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _floorTitle(floor),
                      style: TextStyle(
                        color: selected
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                30,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];

                return _TableStatusCard(
                  table: table,
                  isSelecting:
                      _selectingTableId == table.id,
                  onTap: () => _selectTable(table),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                12,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _openMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.restaurant_menu,
                  ),
                  label: const Text(
                    'Перейти в меню',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TableInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const TableInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class _TableStatusCard extends StatelessWidget {
  final TableInfo table;
  final VoidCallback onTap;
  final bool isSelecting;

  const _TableStatusCard({
    required this.table,
    required this.onTap,
    required this.isSelecting,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: TableService.tableStream(table.id),
      builder: (context, snapshot) {
        String status = 'free';
        String? guestUid;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();

          if (data != null) {
            status = data['status'] as String? ?? 'free';
            guestUid = data['guestUid'] as String?;
          }
        }

        final currentUserUid =
            FirebaseAuth.instance.currentUser?.uid;

        final isMine = guestUid != null &&
            currentUserUid != null &&
            guestUid == currentUserUid;

        final isTaken =
            (status == 'occupied' ||
                status == 'booked' ||
                status == 'reserved') &&
            !isMine;

        final isReservedByMe =
            status == 'reserved' && isMine;

        Color statusColor;
        String statusText;
        IconData statusIcon;

        if (isTaken) {
          statusColor = const Color(0xFFC62828);

          statusText = status == 'booked'
              ? 'Забронирован'
              : 'Занят';

          statusIcon = Icons.lock;
        } else if (isReservedByMe) {
          statusColor = const Color(0xFFD4AF37);
          statusText = 'Ваш';
          statusIcon = Icons.check_circle;
        } else {
          statusColor = const Color(0xFF2E7D32);
          statusText = 'Свободен';
          statusIcon = Icons.check_circle_outline;
        }

        final canTap = !isTaken && !isSelecting;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: canTap ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTaken
                    ? const Color(0xFF151515)
                    : const Color(0xFF191919),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTaken
                      ? const Color(0xFF3A2020)
                      : statusColor.withValues(
                          alpha: 0.65,
                        ),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withValues(
                        alpha: 0.12,
                      ),
                      border: Border.all(
                        color: statusColor.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    child: isSelecting
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFD4AF37),
                            ),
                          )
                        : Icon(
                            table.icon,
                            color: isTaken
                                ? Colors.grey
                                : const Color(
                                    0xFFD4AF37,
                                  ),
                            size: 27,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    table.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isTaken
                          ? Colors.grey
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    table.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isSelecting
                              ? 'Выбор...'
                              : statusText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusLegend extends StatelessWidget {
  final Color color;
  final String text;

  const _StatusLegend({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
