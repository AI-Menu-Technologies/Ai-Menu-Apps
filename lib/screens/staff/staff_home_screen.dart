import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'staff_chats_screen.dart';
import 'staff_orders_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() =>
      _StaffHomeScreenState();
}

class _StaffHomeScreenState
    extends State<StaffHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    StaffOrdersScreen(),
    StaffChatsScreen(),
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  void _showStaffMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          const Color(0xFF151515),
      shape:
          const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Меню персонала',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
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
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
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
      body: _pages[_currentIndex],
      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor:
            const Color(0xFF0D0D0D),
        selectedItemColor:
            const Color(0xFFD4AF37),
        unselectedItemColor:
            Colors.grey,
        type:
            BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.receipt_long_outlined,
            ),
            activeIcon: Icon(
              Icons.receipt_long,
            ),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.chat_bubble_outline,
            ),
            activeIcon: Icon(
              Icons.chat_bubble,
            ),
            label: 'Чаты',
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        onPressed: _showStaffMenu,
        child: const Icon(
          Icons.more_horiz,
        ),
      ),
    );
  }
}
