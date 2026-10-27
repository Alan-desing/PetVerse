import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

/// Reads and updates private activity notices for one user.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final NotificationService instance = NotificationService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notifications(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  /// Streams a user's newest notices.
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notifications(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromDocument)
              .toList(growable: false),
        );
  }

  /// Marks one notice as read.
  Future<void> markRead(String userId, String notificationId) {
    return _notifications(userId).doc(notificationId).update({'isRead': true});
  }

  /// Marks the user's unread notices as read.
  Future<void> markAllRead(String userId) async {
    final snapshot = await _notifications(userId)
        .where('isRead', isEqualTo: false)
        .limit(450)
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final notice in snapshot.docs) {
      batch.update(notice.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
