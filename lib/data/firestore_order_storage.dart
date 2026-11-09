import 'package:cloud_firestore/cloud_firestore.dart'
    hide Order;

import '../models/order.dart';

class FirestoreOrderStorage {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>
      get _orders {
    return _firestore.collection('orders');
  }

  static Future<void> saveOrder(
    Order order, {
    String? guestUid,
    String? venueId,
  }) async {
    final data = <String, dynamic>{
      ...order.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final resolvedVenueId = venueId ?? order.venueId;

    if (resolvedVenueId != null && resolvedVenueId.isNotEmpty) {
      data['venueId'] = resolvedVenueId;
    }

    if (guestUid != null && guestUid.isNotEmpty) {
      data['guestUid'] = guestUid;
    }

    await _orders.doc(order.orderNumber).set(
      data,
      SetOptions(merge: true),
    );
  }

  static Future<void> updateOrderStatus({
    required String orderNumber,
    required String status,
    required String venueId,
  }) async {
    if (venueId.trim().isEmpty) {
      return;
    }

    final orderRef = _orders.doc(orderNumber);
    final orderSnapshot = await orderRef.get();

    if (!orderSnapshot.exists) {
      return;
    }

    final data = orderSnapshot.data();

    if (data == null) {
      return;
    }

    final orderVenueId = data['venueId']?.toString();

    if (orderVenueId != venueId) {
      return;
    }

    await orderRef.set(
      {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      ordersStream(String venueId) {
    return _orders
        .where('venueId', isEqualTo: venueId)
        .snapshots();
  }
}
