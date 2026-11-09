import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../staff/staff_role_router.dart';

class StaffLoginScreen extends StatefulWidget {
  final String venueId;
  final String venueName;

  const StaffLoginScreen({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorText;

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Введите email и пароль.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception(
          'Firebase не вернул пользователя.',
        );
      }

      final uid = user.uid;

      debugPrint('========================================');
      debugPrint('STAFF LOGIN');
      debugPrint('AUTH UID: $uid');
      debugPrint('AUTH EMAIL: ${user.email}');
      debugPrint('SELECTED VENUE ID: ${widget.venueId}');
      debugPrint('SELECTED VENUE NAME: ${widget.venueName}');
      debugPrint('========================================');

      final staffDocument = await FirebaseFirestore.instance
          .collection('staff_users')
          .doc(uid)
          .get();

      if (!staffDocument.exists) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        setState(() {
          _errorText =
              'Профиль сотрудника не найден.\n\n'
              'UID:\n$uid';
          _loading = false;
        });

        return;
      }

      final data = staffDocument.data();

      if (data == null) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        setState(() {
          _errorText =
              'Не удалось получить данные сотрудника.';
          _loading = false;
        });

        return;
      }

      debugPrint('========================================');
      debugPrint('FIRESTORE STAFF DATA');
      debugPrint('STAFF UID: $uid');
      debugPrint('STAFF DATA: $data');
      debugPrint('STAFF KEYS: ${data.keys.toList()}');
      debugPrint('RAW ROLE VALUE: ${data['role']}');
      debugPrint(
        'RAW ROLE TYPE: ${data['role']?.runtimeType}',
      );
      debugPrint('RAW VENUE ID: ${data['venueId']}');
      debugPrint('RAW VENUE NAME: ${data['venueName']}');
      debugPrint('========================================');

      final active = data['active'] == true;

      final staffEmail =
          (data['email']?.toString() ?? '').trim().toLowerCase();

      final staffVenueId =
          (data['venueId']?.toString() ?? '').trim();

      final staffVenueName =
          (data['venueName']?.toString() ?? '').trim();

      String role = '';

      final directRole = data['role'];

      if (directRole != null) {
        role = directRole.toString().trim().toLowerCase();
      }

      if (role.isEmpty) {
        for (final entry in data.entries) {
          final normalizedKey =
              entry.key.toString().trim().toLowerCase();

          if (normalizedKey == 'role') {
            role = entry.value.toString().trim().toLowerCase();
            break;
          }
        }
      }

      debugPrint('========================================');
      debugPrint('STAFF UID: $uid');
      debugPrint('STAFF DATA: $data');
      debugPrint('STAFF EMAIL: $staffEmail');
      debugPrint('AUTH EMAIL: $email');
      debugPrint('STAFF ROLE: $role');
      debugPrint('STAFF ACTIVE: $active');
      debugPrint('STAFF VENUE ID: $staffVenueId');
      debugPrint('STAFF VENUE NAME: $staffVenueName');
      debugPrint('SELECTED VENUE ID: ${widget.venueId}');
      debugPrint('SELECTED VENUE NAME: ${widget.venueName}');
      debugPrint('========================================');

      if (!active) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        setState(() {
          _errorText =
              'Аккаунт сотрудника отключён.\n\n'
              'Активен: false';
          _loading = false;
        });

        return;
      }

      if (staffEmail.isNotEmpty && staffEmail != email) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        setState(() {
          _errorText =
              'Email аккаунта не совпадает '
              'с профилем сотрудника.';
          _loading = false;
        });

        return;
      }

      if (staffVenueId.isEmpty) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        setState(() {
          _errorText =
              'Ваш рабочий аккаунт пока не привязан '
              'к заведению.\n\n'
              'Обратитесь к администратору.';
          _loading = false;
        });

        return;
      }

      if (staffVenueId != widget.venueId) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        setState(() {
          _errorText =
              'Этот сотрудник не привязан к выбранному '
              'заведению.\n\n'
              'Выбрано:\n${widget.venueName}\n\n'
              'Аккаунт сотрудника привязан к:\n'
              '${staffVenueName.isNotEmpty ? staffVenueName : staffVenueId}';
          _loading = false;
        });

        return;
      }

      if (role.isEmpty) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        setState(() {
          _errorText =
              'Для вашего аккаунта не указана роль.\n\n'
              'Обратитесь к администратору.';
          _loading = false;
        });

        return;
      }

      debugPrint('========================================');
      debugPrint('ROLE ROUTER');
      debugPrint('Передаём роль: $role');
      debugPrint('VENUE ID: ${widget.venueId}');
      debugPrint('VENUE NAME: ${widget.venueName}');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => StaffRoleRouter(
            role: role,
          ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-credential':
          message = 'Неверный email или пароль.';
          break;

        case 'invalid-email':
          message = 'Некорректный email.';
          break;

        case 'user-disabled':
          message = 'Этот аккаунт отключён.';
          break;

        case 'too-many-requests':
          message =
              'Слишком много попыток. '
              'Попробуйте позже.';
          break;

        case 'operation-not-allowed':
          message =
              'В Firebase не включён '
              'вход по Email/Password.';
          break;

        default:
          message =
              'Ошибка входа:\n'
              '${e.message ?? e.code}';
      }

      if (mounted) {
        setState(() {
          _errorText = message;
          _loading = false;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _errorText =
              'Ошибка Firebase:\n'
              '${e.code}\n'
              '${e.message ?? ''}';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Ошибка:\n$e';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: _loading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFD4AF37),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFD4AF37),
        ),
        title: const Text(
          'Вход персонала',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Color(0xFFD4AF37),
                    size: 44,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Center(
                child: Text(
                  'Панель персонала',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  widget.venueName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              const Center(
                child: Text(
                  'AI Menu Apps • Рабочий аккаунт',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Email',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Email сотрудника',
                  hintStyle: const TextStyle(
                    color: Colors.white30,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF191919),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFD4AF37),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Пароль',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onSubmitted: (_) {
                  _login();
                },
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите пароль',
                  hintStyle: const TextStyle(
                    color: Colors.white30,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF191919),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFD4AF37),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white54,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        const Color(0xFF242424),
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Войти',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                    'Вернуться к выбору заведения',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4AF37),
                    side: BorderSide(
                      color: const Color(0xFFD4AF37)
                          .withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
}
