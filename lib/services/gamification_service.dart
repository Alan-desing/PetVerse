import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gamification_summary.dart';

/// Calculates points and badges from immutable activity records.
class GamificationService {
  GamificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final GamificationService instance = GamificationService();

  final FirebaseFirestore _firestore;

  /// Streams the current totals for one account.
  Stream<GamificationSummary> watchSummary(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activityEvents')
        .snapshots()
        .map((snapshot) {
          var points = 0;
          var posts = 0;
          var likes = 0;
          var comments = 0;
          for (final event in snapshot.docs) {
            final data = event.data();
            points += (data['points'] as num?)?.toInt() ?? 0;
            switch (data['kind']) {
              case 'post':
                posts++;
                break;
              case 'like':
                likes++;
                break;
              case 'comment':
                comments++;
                break;
            }
          }
          return GamificationSummary(
            points: points,
            posts: posts,
            likes: likes,
            comments: comments,
          );
        });
  }
}
