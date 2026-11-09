import 'package:flutter/material.dart';

import '../admin/admin_home_screen.dart';
import 'staff_home_screen.dart';

class StaffRoleRouter extends StatelessWidget {
  final String role;

  const StaffRoleRouter({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    switch (role.toLowerCase().trim()) {
      case 'waiter':
        return const StaffHomeScreen();

      case 'admin':
      case 'owner':
        return const AdminHomeScreen();

      case 'configurator':
        return const _RoleComingSoonScreen(
          roleTitle: 'Конфигуратор',
          description:
              'Панель конфигуратора будет доступна на следующем этапе разработки.',
        );

      default:
        return const _RoleComingSoonScreen(
          roleTitle: 'Доступ не настроен',
          description:
              'Для этого аккаунта не настроена роль в системе.',
        );
    }
  }
}

class _RoleComingSoonScreen extends StatelessWidget {
  final String roleTitle;
  final String description;

  const _RoleComingSoonScreen({
    required this.roleTitle,
    required this.description,
  });

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
          'AI Menu Apps',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Color(0xFFD4AF37),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                roleTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
