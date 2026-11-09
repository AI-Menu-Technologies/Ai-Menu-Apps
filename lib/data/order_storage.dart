import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import 'firestore_order_storage.dart';
import 'venue_storage.dart';

class OrderStorage {
  static const String _ordersKey = 'orders';

  static Future<void> saveOrder(Order order) async {
    final prefs =
        await SharedPreferences.getInstance();

    final selectedVenue =
        await VenueStorage.getSelectedVenue();

    final resolvedOrder =
        selectedVenue == null
            ? order
            : order.copyWith(
                venueId: selectedVenue.venueId,
              );

    final savedOrders =
        prefs.getStringList(_ordersKey) ?? [];

    final updatedOrders = <String>[];
    bool orderAlreadyExists = false;

    for (final savedOrder in savedOrders) {
      try {
        final existingOrder = Order.fromJson(
          jsonDecode(savedOrder)
              as Map<String, dynamic>,
        );

        if (existingOrder.orderNumber ==
            resolvedOrder.orderNumber) {
          if (!orderAlreadyExists) {
            updatedOrders.add(
              jsonEncode(
                resolvedOrder.toJson(),
              ),
            );

            orderAlreadyExists = true;
          }

          continue;
        }

        updatedOrders.add(savedOrder);
      } catch (_) {
        updatedOrders.add(savedOrder);
      }
    }

    if (!orderAlreadyExists) {
      updatedOrders.add(
        jsonEncode(
          resolvedOrder.toJson(),
        ),
      );
    }

    await prefs.setStringList(
      _ordersKey,
      updatedOrders,
    );

    try {
      final user =
          FirebaseAuth.instance.currentUser;

      final guestUid =
          user?.uid;

      await FirestoreOrderStorage.saveOrder(
        resolvedOrder,
        guestUid: guestUid,
        venueId: selectedVenue?.venueId,
      );
    } catch (_) {
      // Локальное сохранение остаётся рабочим,
      // даже если Firebase временно недоступен.
    }
  }

  static Future<List<Order>> getOrders() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedOrders =
        prefs.getStringList(_ordersKey) ?? [];

    final uniqueOrders =
        <String, Order>{};

    for (final savedOrder in savedOrders) {
      try {
        final order = Order.fromJson(
          jsonDecode(savedOrder)
              as Map<String, dynamic>,
        );

        uniqueOrders[order.orderNumber] = order;
      } catch (_) {
        // Пропускаем повреждённую запись.
      }
    }

    return uniqueOrders.values
        .toList()
        .reversed
        .toList();
  }

  static Future<void> updateOrderStatus({
    required String orderNumber,
    required String status,
    required String venueId,
  }) async {
    if (venueId.trim().isEmpty) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final savedOrders =
        prefs.getStringList(_ordersKey) ?? [];

    final updatedOrders = <String>[];

    final processedOrders =
        <String>{};

    for (final savedOrder in savedOrders) {
      try {
        final order = Order.fromJson(
          jsonDecode(savedOrder)
              as Map<String, dynamic>,
        );

        if (processedOrders.contains(
          order.orderNumber,
        )) {
          continue;
        }

        processedOrders.add(
          order.orderNumber,
        );

        if (order.orderNumber == orderNumber &&
            order.venueId == venueId) {
          updatedOrders.add(
            jsonEncode(
              order.copyWith(
                status: status,
              ).toJson(),
            ),
          );
        } else {
          updatedOrders.add(savedOrder);
        }
      } catch (_) {
        updatedOrders.add(savedOrder);
      }
    }

    await prefs.setStringList(
      _ordersKey,
      updatedOrders,
    );

    try {
      await FirestoreOrderStorage.updateOrderStatus(
        orderNumber: orderNumber,
        status: status,
        venueId: venueId,
      );
    } catch (_) {
      // Локальное изменение сохраняется,
      // даже если Firebase временно недоступен.
    }
  }

  static Future<void> clearOrders() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_ordersKey);
  }
}
