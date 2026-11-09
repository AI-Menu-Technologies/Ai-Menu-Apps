import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'table_storage.dart';

class TableService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _tables =>
      _firestore.collection('tables');

  /// Возвращает UID текущего пользователя.
  ///
  /// Если пользователь ещё не авторизован,
  /// создаём анонимную Firebase-сессию.
  static Future<String> _getGuestUid() async {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser != null) {
      return auth.currentUser!.uid;
    }

    final credential = await auth.signInAnonymously();

    return credential.user!.uid;
  }

  /// Выбирает столик.
  ///
  /// Важное правило:
  /// один гость может иметь только один текущий стол.
  ///
  /// Если у гостя уже есть временная бронь другого стола,
  /// старый стол освобождается, а новый становится его столом.
  ///
  /// Если старый стол уже переведён в occupied,
  /// переключение запрещается.
  static Future<TableReservationResult> reserveTable({
    required int floor,
    required String tableId,
    required String tableName,
  }) async {
    try {
      final guestUid = await _getGuestUid();

      final selectedTable = await TableStorage.getSelectedTable();

      final previousTableId = selectedTable?.tableId;

      final newTableRef = _tables.doc(tableId);

      DocumentReference<Map<String, dynamic>>? previousTableRef;

      if (previousTableId != null &&
          previousTableId.isNotEmpty &&
          previousTableId != tableId) {
        previousTableRef = _tables.doc(previousTableId);
      }

      final result =
          await _firestore.runTransaction<TableReservationResult>(
        (transaction) async {
          /*
           * СНАЧАЛА читаем все документы,
           * ПОТОМ выполняем изменения.
           *
           * Это важно для Firestore transaction.
           */

          final newTableSnapshot =
              await transaction.get(newTableRef);

          DocumentSnapshot<Map<String, dynamic>>? previousTableSnapshot;

          if (previousTableRef != null) {
            previousTableSnapshot =
                await transaction.get(previousTableRef);
          }

          final now = DateTime.now();

          /*
           * ---------------------------------------------------------
           * 1. Проверяем предыдущий стол текущего пользователя.
           * ---------------------------------------------------------
           */

          if (previousTableSnapshot != null &&
              previousTableSnapshot.exists) {
            final previousData =
                previousTableSnapshot.data() ?? {};

            final previousStatus =
                previousData['status'] as String? ?? 'free';

            final previousGuestUid =
                previousData['guestUid'] as String?;

            /*
             * Если предыдущий стол уже occupied,
             * значит гость фактически занял его.
             *
             * Просто переключать его на другой стол нельзя.
             */
            if (previousGuestUid == guestUid &&
                previousStatus == 'occupied') {
              return TableReservationResult.error(
                'Ваш текущий стол уже занят. '
                'Сначала завершите обслуживание этого стола.',
              );
            }

            /*
             * Если предыдущий стол был booked,
             * не пытаемся его менять.
             */
            if (previousGuestUid == guestUid &&
                previousStatus == 'booked') {
              return TableReservationResult.error(
                'Текущий стол забронирован. '
                'Сначала завершите текущую бронь.',
              );
            }
          }

          /*
           * ---------------------------------------------------------
           * 2. Проверяем новый стол.
           * ---------------------------------------------------------
           */

          if (!newTableSnapshot.exists) {
            /*
             * Стол ещё отсутствует в Firestore.
             *
             * Создаём его сразу с временной бронью на 15 минут.
             */
            transaction.set(
              newTableRef,
              {
                'floor': floor,
                'tableId': tableId,
                'tableName': tableName,
                'status': 'reserved',
                'guestUid': guestUid,
                'reservedAt': FieldValue.serverTimestamp(),
                'expiresAt': Timestamp.fromDate(
                  now.add(const Duration(minutes: 15)),
                ),
                'updatedAt': FieldValue.serverTimestamp(),
              },
            );
          } else {
            final newData =
                newTableSnapshot.data() ?? {};

            final newStatus =
                newData['status'] as String? ?? 'free';

            final currentGuestUid =
                newData['guestUid'] as String?;

            DateTime? expiresAt;

            final rawExpiresAt =
                newData['expiresAt'];

            if (rawExpiresAt is Timestamp) {
              expiresAt = rawExpiresAt.toDate();
            }

            /*
             * -------------------------------------------------------
             * 2.1. Это уже наш текущий стол.
             * -------------------------------------------------------
             */
            if (currentGuestUid == guestUid &&
                newStatus == 'reserved') {
              /*
               * Продлеваем временную бронь ещё на 15 минут.
               */
              transaction.set(
                newTableRef,
                {
                  'floor': floor,
                  'tableId': tableId,
                  'tableName': tableName,
                  'status': 'reserved',
                  'guestUid': guestUid,
                  'reservedAt': FieldValue.serverTimestamp(),
                  'expiresAt': Timestamp.fromDate(
                    now.add(const Duration(minutes: 15)),
                  ),
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true),
              );
            }

            /*
             * -------------------------------------------------------
             * 2.2. Это наш стол, но он уже occupied.
             * -------------------------------------------------------
             */
            else if (currentGuestUid == guestUid &&
                newStatus == 'occupied') {
              return TableReservationResult.success;
            }

            /*
             * -------------------------------------------------------
             * 2.3. Стол занят другим пользователем.
             * -------------------------------------------------------
             */
            else if (newStatus == 'occupied') {
              return TableReservationResult.alreadyTaken;
            }

            /*
             * -------------------------------------------------------
             * 2.4. Стол забронирован персоналом.
             * -------------------------------------------------------
             */
            else if (newStatus == 'booked') {
              return TableReservationResult.alreadyTaken;
            }

            /*
             * -------------------------------------------------------
             * 2.5. Временная бронь другого пользователя.
             * -------------------------------------------------------
             */
            else if (newStatus == 'reserved') {
              final reservationExpired =
                  expiresAt != null &&
                  expiresAt.isBefore(now);

              if (reservationExpired) {
                /*
                 * Важный момент:
                 * после изменения Firestore Rules этот участок
                 * позволит повторно занять истёкшую бронь.
                 */
                transaction.set(
                  newTableRef,
                  {
                    'floor': floor,
                    'tableId': tableId,
                    'tableName': tableName,
                    'status': 'reserved',
                    'guestUid': guestUid,
                    'reservedAt': FieldValue.serverTimestamp(),
                    'expiresAt': Timestamp.fromDate(
                      now.add(const Duration(minutes: 15)),
                    ),
                    'updatedAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );
              } else {
                return TableReservationResult.alreadyTaken;
              }
            }

            /*
             * -------------------------------------------------------
             * 2.6. Стол свободен.
             * -------------------------------------------------------
             */
            else {
              transaction.set(
                newTableRef,
                {
                  'floor': floor,
                  'tableId': tableId,
                  'tableName': tableName,
                  'status': 'reserved',
                  'guestUid': guestUid,
                  'reservedAt': FieldValue.serverTimestamp(),
                  'expiresAt': Timestamp.fromDate(
                    now.add(const Duration(minutes: 15)),
                  ),
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true),
              );
            }
          }

          /*
           * ---------------------------------------------------------
           * 3. Освобождаем предыдущий стол.
           * ---------------------------------------------------------
           *
           * Делаем это только если:
           *
           * - предыдущий стол существует;
           * - он принадлежит этому гостю;
           * - он был временно reserved.
           *
           * guestUid специально пока оставляем в документе.
           * Это соответствует текущим Firestore Rules.
           * Статус free делает стол доступным для нового гостя.
           */

          if (previousTableSnapshot != null &&
              previousTableSnapshot.exists &&
              previousTableRef != null) {
            final previousData =
                previousTableSnapshot.data() ?? {};

            final previousStatus =
                previousData['status'] as String? ?? 'free';

            final previousGuestUid =
                previousData['guestUid'] as String?;

            if (previousGuestUid == guestUid &&
                previousStatus == 'reserved') {
              transaction.set(
                previousTableRef,
                {
                  'status': 'free',
                  'reservedAt': FieldValue.delete(),
                  'expiresAt': FieldValue.delete(),
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true),
              );
            }
          }

          return TableReservationResult.success;
        },
      );

      return result;
    } on FirebaseException catch (e) {
      return TableReservationResult.error(
        e.message ?? 'Ошибка Firebase.',
      );
    } catch (e) {
      return TableReservationResult.error(
        'Не удалось выбрать столик.',
      );
    }
  }

  /// Освобождает стол текущего гостя.
  ///
  /// В текущей версии Rules guestUid не удаляем,
  /// а просто переводим стол в состояние free.
  static Future<bool> releaseTable(String tableId) async {
    try {
      final guestUid =
          FirebaseAuth.instance.currentUser?.uid;

      if (guestUid == null) {
        return false;
      }

      final tableRef = _tables.doc(tableId);

      final snapshot = await tableRef.get();

      if (!snapshot.exists) {
        return false;
      }

      final data = snapshot.data() ?? {};

      final currentGuestUid =
          data['guestUid'] as String?;

      if (currentGuestUid != guestUid) {
        return false;
      }

      final status =
          data['status'] as String? ?? 'free';

      /*
       * Не позволяем гостю самостоятельно освобождать
       * уже occupied или booked стол.
       */
      if (status == 'occupied' || status == 'booked') {
        return false;
      }

      await tableRef.set(
        {
          'status': 'free',
          'reservedAt': FieldValue.delete(),
          'expiresAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Переводит стол из временной брони в occupied.
  ///
  /// Используется, когда гость фактически занял стол.
  static Future<bool> occupyTable(String tableId) async {
    try {
      final guestUid =
          FirebaseAuth.instance.currentUser?.uid;

      if (guestUid == null) {
        return false;
      }

      final tableRef = _tables.doc(tableId);

      final result =
          await _firestore.runTransaction<bool>(
        (transaction) async {
          final snapshot =
              await transaction.get(tableRef);

          if (!snapshot.exists) {
            return false;
          }

          final data =
              snapshot.data() ?? {};

          final currentGuestUid =
              data['guestUid'] as String?;

          if (currentGuestUid != guestUid) {
            return false;
          }

          final status =
              data['status'] as String? ?? 'free';

          if (status != 'reserved') {
            return false;
          }

          transaction.set(
            tableRef,
            {
              'status': 'occupied',
              'occupiedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'expiresAt': FieldValue.delete(),
            },
            SetOptions(merge: true),
          );

          return true;
        },
      );

      return result;
    } catch (_) {
      return false;
    }
  }

  /// Возвращает поток статуса конкретного столика.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> tableStream(
    String tableId,
  ) {
    return _tables.doc(tableId).snapshots();
  }
}

enum TableReservationStatus {
  free,
  reserved,
  occupied,
  booked,
}

class TableReservationResult {
  final bool isSuccess;
  final bool isAlreadyTaken;
  final String? errorMessage;

  const TableReservationResult._({
    required this.isSuccess,
    required this.isAlreadyTaken,
    this.errorMessage,
  });

  static const success = TableReservationResult._(
    isSuccess: true,
    isAlreadyTaken: false,
  );

  static const alreadyTaken = TableReservationResult._(
    isSuccess: false,
    isAlreadyTaken: true,
  );

  factory TableReservationResult.error(String message) {
    return TableReservationResult._(
      isSuccess: false,
      isAlreadyTaken: false,
      errorMessage: message,
    );
  }
}