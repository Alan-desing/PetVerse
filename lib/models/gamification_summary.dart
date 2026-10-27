/// Totals and achievements derived from a user's activity records.
class GamificationSummary {
  const GamificationSummary({
    required this.points,
    required this.posts,
    required this.likes,
    required this.comments,
  });

  final int points;
  final int posts;
  final int likes;
  final int comments;
}
