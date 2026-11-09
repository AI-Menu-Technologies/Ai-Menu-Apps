import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_home_screen.dart';

class VenueRegistrationScreen extends StatefulWidget {
  const VenueRegistrationScreen({super.key});

  @override
  State<VenueRegistrationScreen> createState() =>
      _VenueRegistrationScreenState();
}

class _VenueRegistrationScreenState extends State<VenueRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _telegramController = TextEditingController();
  final _websiteController = TextEditingController();

  final _ownerFirstNameController = TextEditingController();
  final _ownerLastNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _ownerPasswordConfirmController = TextEditingController();

  final _descriptionController = TextEditingController();

  int _currentStep = 0;
  bool _isRegistering = false;

  String _venueType = 'Ресторан';

  Color _primaryColor = const Color(0xFFD4AF37);

  final List<String> _venueTypes = [
    'Ресторан',
    'Кафе',
    'Бар',
    'Lounge',
    'Клуб',
    'Караоке',
    'Другое',
  ];

  final List<Color> _availableColors = [
    const Color(0xFFD4AF37),
    const Color(0xFFC0C0C0),
    const Color(0xFF2196F3),
    const Color(0xFF8E44AD),
    const Color(0xFFE67E22),
    const Color(0xFF27AE60),
    const Color(0xFFE74C3C),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _telegramController.dispose();
    _websiteController.dispose();

    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    _ownerPasswordConfirmController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }

  String _createVenueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = _nameController.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9а-яё]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final safeName = name.isEmpty ? 'venue' : name;

    return '${safeName}_$timestamp';
  }

  Future<void> _registerVenue() async {
    if (_isRegistering) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _currentStep = 0;
      });
      return;
    }

    final email = _ownerEmailController.text.trim();
    final password = _ownerPasswordController.text;

    setState(() {
      _isRegistering = true;
    });

    User? createdUser;
    bool firestoreCreated = false;

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      /*
       * Владелец регистрируется непосредственно через Firebase
       * Authentication. После успешного создания Firebase автоматически
       * авторизует этого пользователя.
       */
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Firebase не вернул данные пользователя.',
        );
      }

      final ownerUid = createdUser.uid;
      final venueId = _createVenueId();
      final venueName = _nameController.text.trim();
      final ownerFirstName = _ownerFirstNameController.text.trim();
      final ownerLastName = _ownerLastNameController.text.trim();
      final ownerPhone = _ownerPhoneController.text.trim();
      final now = FieldValue.serverTimestamp();

      final venueRef = firestore.collection('venues').doc(venueId);
      final staffRef = firestore.collection('staff_users').doc(ownerUid);
      final userRef = firestore.collection('users').doc(ownerUid);

      final batch = firestore.batch();

      /*
       * 1. Создаём заведение.
       */
      batch.set(venueRef, {
        'venueId': venueId,
        'name': venueName,
        'type': _venueType,
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'telegram': _telegramController.text.trim(),
        'website': _websiteController.text.trim(),
        'logoUrl': null,
        'coverUrl': null,
        'description': _descriptionController.text.trim(),
        'primaryColor': _primaryColor.toARGB32(),
        'ownerUid': ownerUid,
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      });

      /*
       * 2. Создаём профиль владельца.
       *
       * Именно этот документ используется приложением для определения,
       * что пользователь является владельцем конкретного заведения.
       */
      batch.set(staffRef, {
        'uid': ownerUid,
        'email': email,
        'role': 'owner',
        'active': true,
        'venueId': venueId,
        'venueName': venueName,
        'firstName': ownerFirstName,
        'lastName': ownerLastName,
        'phone': ownerPhone,
        'createdAt': now,
        'updatedAt': now,
      });

      /*
       * 3. Создаём общий профиль пользователя.
       */
      batch.set(
        userRef,
        {
          'uid': ownerUid,
          'accountType': 'owner',
          'displayName': '$ownerFirstName $ownerLastName'.trim(),
          'email': email,
          'venueId': venueId,
          'venueName': venueName,
          'updatedAt': now,
          'createdAt': now,
        },
        SetOptions(merge: true),
      );

      /*
       * Все три записи создаются одной Firestore-транзакцией batch.
       */
      await batch.commit();
      firestoreCreated = true;

      /*
       * Обновляем displayName в Firebase Authentication.
       */
      await createdUser.updateDisplayName(
        '$ownerFirstName $ownerLastName'.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B5E20),
          content: Text(
            'Заведение «$venueName» успешно создано.',
          ),
        ),
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      /*
       * Пользователь уже авторизован Firebase Authentication,
       * поэтому дополнительно входить ему не нужно.
       */
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AdminHomeScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      /*
       * Если Authentication не создал пользователя,
       * просто показываем понятную ошибку.
       */
      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'Этот email уже зарегистрирован. Если это ваш аккаунт, используйте вход владельца.';
          break;
        case 'invalid-email':
          message = 'Некорректный email.';
          break;
        case 'weak-password':
          message =
              'Слишком слабый пароль. Используйте минимум 6 символов.';
          break;
        case 'operation-not-allowed':
          message =
              'Регистрация по email/паролю отключена в Firebase Authentication.';
          break;
        case 'network-request-failed':
          message =
              'Нет соединения с Firebase. Проверьте интернет и повторите попытку.';
          break;
        default:
          message =
              'Ошибка Firebase Authentication: ${e.message ?? e.code}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(message),
        ),
      );
    } on FirebaseException catch (e) {
      /*
       * Очень важный момент:
       *
       * Authentication уже мог создать владельца, но Firestore мог
       * отклонить запись. В этом случае удаляем только что созданный
       * Authentication-аккаунт, чтобы не оставался "полусозданный"
       * владелец.
       */
      if (!firestoreCreated && createdUser != null) {
        try {
          await createdUser.delete();
          await FirebaseAuth.instance.signOut();
        } catch (_) {
          /*
           * Если удаление не удалось, не скрываем основную ошибку.
           * Она будет показана пользователю ниже.
           */
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            'Не удалось создать данные заведения в Firebase: '
            '${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      /*
       * Аналогичная защита для непредвиденной ошибки.
       */
      if (!firestoreCreated && createdUser != null) {
        try {
          await createdUser.delete();
          await FirebaseAuth.instance.signOut();
        } catch (_) {
          // Основную ошибку всё равно показываем пользователю.
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            'Не удалось создать заведение: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }
  void _nextStep() {
    if (_currentStep <= 1) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep < 6) {
      setState(() {
        _currentStep++;
      });
      return;
    }

    _registerVenue();
  }

  void _previousStep() {
    if (_isRegistering) {
      return;
    }

    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите email';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Введите корректный email';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }

    if (value.length < 6) {
      return 'Минимум 6 символов';
    }

    return null;
  }

  String? _passwordConfirmValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Повторите пароль';
    }

    if (value != _ownerPasswordController.text) {
      return 'Пароли не совпадают';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == 6;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isRegistering ? null : _previousStep,
        ),
        title: const Text(
          'Регистрация заведения',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
            _buildBottomNavigation(isLastStep),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: List.generate(
          7,
          (index) {
            final isActive = index <= _currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index == 6 ? 0 : 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFD4AF37)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepOne();
      case 1:
        return _buildStepTwo();
      case 2:
        return _buildStepThree();
      case 3:
        return _buildPlaceholderStep(
          title: 'Структура заведения',
          subtitle: 'Настройте этажи, залы, зоны и столы.',
          icon: Icons.table_restaurant_outlined,
        );
      case 4:
        return _buildPlaceholderStep(
          title: 'Меню',
          subtitle: 'Добавьте категории, блюда, фотографии и цены.',
          icon: Icons.restaurant_menu_outlined,
        );
      case 5:
        return _buildPlaceholderStep(
          title: 'Персонал',
          subtitle: 'Добавьте сотрудников и назначьте им роли.',
          icon: Icons.groups_outlined,
        );
      case 6:
        return _buildCompletionStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Создайте своё заведение',
          subtitle:
              'Заполните основную информацию. Позже эти данные можно будет изменить.',
        ),
        const SizedBox(height: 28),
        _buildSectionTitle('Основная информация'),
        const SizedBox(height: 12),
        _textField(
          controller: _nameController,
          label: 'Название заведения',
          hint: 'Например: Baku Nights Lounge Bar',
          icon: Icons.storefront_outlined,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        _buildVenueTypeSelector(),
        const SizedBox(height: 28),
        _buildSectionTitle('Местоположение'),
        const SizedBox(height: 12),
        _textField(
          controller: _countryController,
          label: 'Страна',
          hint: 'Например: Узбекистан',
          icon: Icons.public,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _cityController,
          label: 'Город',
          hint: 'Например: Навои',
          icon: Icons.location_city_outlined,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _addressController,
          label: 'Адрес',
          hint: 'Улица, дом',
          icon: Icons.location_on_outlined,
          maxLines: 2,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 28),
        _buildSectionTitle('Контакты'),
        const SizedBox(height: 12),
        _textField(
          controller: _phoneController,
          label: 'Телефон',
          hint: '+998 XX XXX XX XX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _instagramController,
          label: 'Instagram',
          hint: '@your_venue',
          icon: Icons.camera_alt_outlined,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _telegramController,
          label: 'Telegram',
          hint: '@your_venue',
          icon: Icons.send_outlined,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _websiteController,
          label: 'Сайт',
          hint: 'https://...',
          icon: Icons.language_outlined,
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Данные владельца',
          subtitle:
              'Эти данные будут использоваться для входа в панель управления заведением.',
        ),
        const SizedBox(height: 28),
        _buildSectionTitle('Личные данные'),
        const SizedBox(height: 12),
        _textField(
          controller: _ownerFirstNameController,
          label: 'Имя',
          hint: 'Ваше имя',
          icon: Icons.person_outline,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _ownerLastNameController,
          label: 'Фамилия',
          hint: 'Ваша фамилия',
          icon: Icons.person_outline,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _ownerPhoneController,
          label: 'Телефон',
          hint: '+998 XX XXX XX XX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 28),
        _buildSectionTitle('Данные для входа'),
        const SizedBox(height: 12),
        _textField(
          controller: _ownerEmailController,
          label: 'Email',
          hint: 'example@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _ownerPasswordController,
          label: 'Пароль',
          hint: 'Минимум 6 символов',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: _passwordValidator,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _ownerPasswordConfirmController,
          label: 'Повторите пароль',
          hint: 'Введите пароль ещё раз',
          icon: Icons.lock_reset_outlined,
          obscureText: true,
          validator: _passwordConfirmValidator,
        ),
        const SizedBox(height: 24),
        _buildInfoBox(
          icon: Icons.security_outlined,
          text:
              'Аккаунт владельца будет создан автоматически через Firebase Authentication, а заведение будет связано с этим аккаунтом.',
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Оформление заведения',
          subtitle:
              'Добавьте визуальный стиль, чтобы ваше заведение красиво выглядело для гостей.',
        ),
        const SizedBox(height: 28),
        _buildSectionTitle('Логотип'),
        const SizedBox(height: 12),
        _buildUploadCard(
          icon: Icons.image_outlined,
          title: 'Добавить логотип',
          subtitle: 'PNG, JPG или WEBP',
          isLogo: true,
        ),
        const SizedBox(height: 28),
        _buildSectionTitle('Обложка'),
        const SizedBox(height: 12),
        _buildUploadCard(
          icon: Icons.photo_library_outlined,
          title: 'Добавить обложку',
          subtitle: 'Широкое изображение заведения',
          isLogo: false,
        ),
        const SizedBox(height: 28),
        _buildSectionTitle('Описание'),
        const SizedBox(height: 12),
        _textField(
          controller: _descriptionController,
          label: 'Описание заведения',
          hint:
              'Расскажите гостям о вашем заведении, атмосфере, кухне и особенностях...',
          icon: Icons.description_outlined,
          maxLines: 5,
        ),
        const SizedBox(height: 28),
        _buildSectionTitle('Основной цвет'),
        const SizedBox(height: 8),
        Text(
          'Этот цвет будет использоваться в оформлении вашего заведения.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        _buildColorSelector(),
        const SizedBox(height: 28),
        _buildPreviewCard(),
      ],
    );
  }

  Widget _buildCompletionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Заведение готово к созданию',
          subtitle:
              'Проверьте основные данные. После нажатия «Создать заведение» будет создан аккаунт владельца и само заведение в Firebase.',
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFD4AF37),
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _nameController.text.trim().isEmpty
                    ? 'Ваше заведение'
                    : _nameController.text.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_venueType} • ${_cityController.text.trim()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 22),
              _summaryRow(
                Icons.person_outline,
                'Владелец',
                '${_ownerFirstNameController.text.trim()} ${_ownerLastNameController.text.trim()}'
                    .trim(),
              ),
              _summaryRow(
                Icons.email_outlined,
                'Email',
                _ownerEmailController.text.trim(),
              ),
              _summaryRow(
                Icons.phone_outlined,
                'Телефон',
                _phoneController.text.trim(),
              ),
              _summaryRow(
                Icons.location_on_outlined,
                'Адрес',
                _addressController.text.trim(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoBox(
          icon: Icons.cloud_done_outlined,
          text:
              'Будут созданы: заведение в коллекции venues, профиль владельца и запись владельца в staff_users.',
        ),
      ],
    );
  }

  Widget _summaryRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFD4AF37),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLogo,
  }) {
    return Container(
      width: double.infinity,
      height: isLogo ? 150 : 180,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLogo
                    ? 'Загрузка логотипа будет подключена следующим этапом.'
                    : 'Загрузка обложки будет подключена следующим этапом.',
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isLogo ? 58 : 64,
              height: isLogo ? 58 : 64,
              decoration: BoxDecoration(
                shape: isLogo ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isLogo ? null : BorderRadius.circular(14),
                color: _primaryColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: _primaryColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                icon,
                color: _primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableColors.map((color) {
        final isSelected = _primaryColor.toARGB32() == color.toARGB32();

        return GestureDetector(
          onTap: () {
            setState(() {
              _primaryColor = color;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 22,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewCard() {
    final venueName = _nameController.text.trim().isEmpty
        ? 'Название заведения'
        : _nameController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primaryColor.withValues(alpha: 0.55),
                  ),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _venueType,
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_descriptionController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _descriptionController.text.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVenueTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Тип заведения',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white12,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _venueType,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFD4AF37),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              items: _venueTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _venueType = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderStep({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 36),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 58,
                color: const Color(0xFFD4AF37),
              ),
              const SizedBox(height: 18),
              const Text(
                'Раздел в разработке',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Мы подключим этот раздел следующим этапом.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFD4AF37),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFD4AF37),
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFD4AF37),
          size: 21,
        ),
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
        ),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.30),
        ),
        filled: true,
        fillColor: const Color(0xFF111111),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.white12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.white12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD4AF37),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isLastStep) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isRegistering ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.white24,
                  ),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Назад'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isRegistering ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                disabledBackgroundColor:
                    const Color(0xFFD4AF37).withValues(alpha: 0.45),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isRegistering
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black,
                        ),
                      ),
                    )
                  : Text(
                      isLastStep ? 'Создать заведение' : 'Далее',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

