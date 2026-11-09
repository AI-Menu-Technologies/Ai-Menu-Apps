import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GuestAuthService {
  GuestAuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  static Future<void>? _googleInitialization;

  /// Инициализирует Google Sign-In один раз.
  static Future<void> initializeGoogle() {
    return _googleInitialization ??=
        _googleSignIn.initialize();
  }

  /// Текущий авторизованный пользователь Firebase.
  static User? get currentUser {
    return _auth.currentUser;
  }

  /// Авторизация гостя через Google.
  ///
  /// venueId и venueName приходят от выбранного заведения.
  /// Один Firebase UID используется для всей платформы,
  /// а принадлежность к заведению сохраняется отдельно.
  static Future<UserCredential> signInWithGoogle({
    required String venueId,
    required String venueName,
  }) async {
    if (venueId.trim().isEmpty) {
      throw ArgumentError('venueId не может быть пустым.');
    }

    if (venueName.trim().isEmpty) {
      throw ArgumentError('venueName не может быть пустым.');
    }

    await initializeGoogle();

    final googleUser = await _googleSignIn.authenticate();

    final googleAuthentication =
        googleUser.authentication;

    final idToken = googleAuthentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message:
            'Google не вернул ID token. Проверьте OAuth-настройки Firebase.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    final user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message:
            'Firebase не вернул авторизованного пользователя.',
      );
    }

    await _saveGuestProfile(
      user: user,
      venueId: venueId,
      venueName: venueName,
    );

    return userCredential;
  }

  /// Сохраняет общий профиль пользователя и его связь
  /// с конкретным заведением.
  static Future<void> _saveGuestProfile({
    required User user,
    required String venueId,
    required String venueName,
  }) async {
    final now = FieldValue.serverTimestamp();

    final userRef =
        _firestore.collection('users').doc(user.uid);

    await userRef.set(
      {
        'uid': user.uid,
        'accountType': 'guest',
        'displayName': user.displayName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'photoUrl': user.photoURL,
        'lastVenueId': venueId,
        'lastVenueName': venueName,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    await userRef
        .collection('venues')
        .doc(venueId)
        .set(
      {
        'venueId': venueId,
        'venueName': venueName,
        'updatedAt': now,
        'lastLoginAt': now,
      },
      SetOptions(merge: true),
    );
  }

  /// Выход из аккаунта.
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
