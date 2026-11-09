import 'package:flutter/material.dart';

import '../auth/guest_auth_screen.dart';
import '../auth/staff_login_screen.dart';

enum VenueSelectionMode {
  guest,
  staff,
}

class Venue {
  final String id;
  final String name;
  final String city;
  final String? logoUrl;

  const Venue({
    required this.id,
    required this.name,
    required this.city,
    this.logoUrl,
  });
}

/// Временный список заведений для MVP.
///
/// В дальнейшем этот список будет загружаться из Firestore.
/// Поэтому добавление новых заведений не потребует
/// переписывания архитектуры приложения.
const List<Venue> availableVenues = [
  Venue(
    id: 'thhtrfhrfhrfthgf_1790612261407',
    name: 'Baku Nights Lounge Bar',
    city: 'Navoiy',
  ),
];

class VenueSelectionScreen extends StatelessWidget {
  final VenueSelectionMode mode;

  const VenueSelectionScreen({
    super.key,
    required this.mode,
  });

  void _openVenue(
    BuildContext context,
    Venue venue,
  ) {
    if (mode == VenueSelectionMode.guest) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuestAuthScreen(
            venueId: venue.id,
            venueName: venue.name,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffLoginScreen(
          venueId: venue.id,
          venueName: venue.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = mode == VenueSelectionMode.staff;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFD4AF37),
          ),
        ),
        title: Text(
          isStaff ? 'Выбор заведения' : 'Выбор заведения',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                12,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI MENU APPS',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isStaff
                          ? 'Выберите заведение\nдля входа персонала.'
                          : 'Добро пожаловать\nв мир вкуса.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        height: 1.12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isStaff
                          ? 'Выберите заведение, в котором вы работаете. '
                              'После этого будет выполнена проверка '
                              'вашего рабочего аккаунта.'
                          : 'Откройте для себя места, где кухня, '
                              'атмосфера и стиль создают особенное настроение.',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isStaff
                          ? 'Ваше заведение'
                          : 'Выберите заведение по своему вкусу.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isStaff
                          ? 'Если вы случайно выбрали не то заведение, '
                              'нажмите «Назад» и выберите другое.'
                          : 'От уютного вечера до яркой встречи — '
                              'найдите место, которое подходит именно вам.',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                30,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final venue = availableVenues[index];

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: _VenueCard(
                        venue: venue,
                        isStaff: isStaff,
                        onTap: () => _openVenue(
                          context,
                          venue,
                        ),
                      ),
                    );
                  },
                  childCount: availableVenues.length,
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                30,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Ваш вечер. Ваш выбор. Ваш стиль.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Venue venue;
  final bool isStaff;
  final VoidCallback onTap;

  const _VenueCard({
    required this.venue,
    required this.isStaff,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(
                alpha: 0.28,
              ),
            ),
          ),
          child: Row(
            children: [
              _VenueLogo(
                venue: venue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFD4AF37),
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          venue.city,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      isStaff
                          ? 'Персонал • Вход • Панель'
                          : 'Меню • Стол • Заказы • Сервис',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFD4AF37),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueLogo extends StatelessWidget {
  final Venue venue;

  const _VenueLogo({
    required this.venue,
  });

  @override
  Widget build(BuildContext context) {
    if (venue.logoUrl != null &&
        venue.logoUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          venue.logoUrl!,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _fallback();
          },
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF211C0D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFFD4AF37),
        size: 32,
      ),
    );
  }
}

