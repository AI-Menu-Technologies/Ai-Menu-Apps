import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/guest_auth_service.dart';
import '../../data/venue_storage.dart';
import '../home/home_screen.dart';

class GuestAuthScreen extends StatefulWidget {
  final String venueId;
  final String venueName;

  const GuestAuthScreen({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  State<GuestAuthScreen> createState() => _GuestAuthScreenState();
}

class _GuestAuthScreenState extends State<GuestAuthScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      debugPrint('========== GOOGLE SIGN-IN START ==========');
      debugPrint('Venue ID: ${widget.venueId}');
      debugPrint('Venue Name: ${widget.venueName}');

      await GuestAuthService.signInWithGoogle(
        venueId: widget.venueId,
        venueName: widget.venueName,
      );

      debugPrint('GOOGLE AUTH SUCCESS');

      await VenueStorage.saveSelectedVenue(
        venueId: widget.venueId,
        venueName: widget.venueName,
      );

      debugPrint('VENUE STORAGE SUCCESS');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('FIREBASE AUTH ERROR: ${error.code}');
      debugPrint('FIREBASE MESSAGE: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showError(
          '${error.code}: ${error.message ?? "Ошибка Firebase"}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('GOOGLE SIGN-IN ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showError('Ошибка: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showUnavailable(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title будет подключён следующим этапом.'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24, 28, 24, 28 + bottomInset,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Назад',
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.black,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AI Menu Apps',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.venueName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Войдите в аккаунт',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Один аккаунт AI Menu Apps для всех заведений, '
                'которые вы посещаете.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              _AuthButton(
                icon: Icons.g_mobiledata_rounded,
                title: 'Продолжить с Google',
                onPressed: _loading ? null : _signInWithGoogle,
                filled: true,
              ),
              const SizedBox(height: 14),
              _AuthButton(
                icon: Icons.apple,
                title: 'Продолжить с Apple',
                onPressed: _loading
                    ? null
                    : () => _showUnavailable('Вход через Apple'),
              ),
              const SizedBox(height: 14),
              _AuthButton(
                icon: Icons.phone_outlined,
                title: 'Войти по номеру телефона',
                onPressed: _loading
                    ? null
                    : () => _showUnavailable('Вход по номеру телефона'),
              ),
              const SizedBox(height: 28),
              const Text(
                'Продолжая, вы соглашаетесь с условиями '
                'использования AI Menu Apps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (_loading) ...[
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onPressed;
  final bool filled;

  const _AuthButton({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 27),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: filled
              ? const Color(0xFFD4AF37)
              : const Color(0xFF161616),
          foregroundColor: filled ? Colors.black : Colors.white,
          disabledBackgroundColor: const Color(0xFF202020),
          disabledForegroundColor: Colors.white38,
          elevation: 0,
          side: BorderSide(
            color: filled
                ? Colors.transparent
                : const Color(0xFF303030),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}