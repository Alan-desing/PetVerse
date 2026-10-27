import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/gamification_summary.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';

/// Shows the signed-in user's points and unlocked badges.
class GamificationScreen extends StatelessWidget {
  const GamificationScreen({required this.user, super.key});

  final User user;

  static const _badges = <_BadgeDefinition>[
    _BadgeDefinition(
      title: 'Primera estrella',
      description: 'Comparte tu primera publicación.',
      icon: Icons.auto_awesome_rounded,
      requirement: (summary) => summary.posts >= 1,
      progress: (summary) => summary.posts.clamp(0, 1).toInt(),
      goal: 1,
    ),
    _BadgeDefinition(
      title: 'Creador',
      description: 'Llega a cinco publicaciones.',
      icon: Icons.photo_camera_rounded,
      requirement: (summary) => summary.posts >= 5,
      progress: (summary) => summary.posts.clamp(0, 5).toInt(),
      goal: 5,
    ),
    _BadgeDefinition(
      title: 'Patas amigas',
      description: 'Reparte diez Me gusta.',
      icon: Icons.favorite_rounded,
      requirement: (summary) => summary.likes >= 10,
      progress: (summary) => summary.likes.clamp(0, 10).toInt(),
      goal: 10,
    ),
    _BadgeDefinition(
      title: 'Buena conversación',
      description: 'Escribe diez comentarios.',
      icon: Icons.chat_rounded,
      requirement: (summary) => summary.comments >= 10,
      progress: (summary) => summary.comments.clamp(0, 10).toInt(),
      goal: 10,
    ),
    _BadgeDefinition(
      title: 'Estrella PetVerse',
      description: 'Acumula cien puntos.',
      icon: Icons.emoji_events_rounded,
      requirement: (summary) => summary.points >= 100,
      progress: (summary) => summary.points.clamp(0, 100).toInt(),
      goal: 100,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: StreamBuilder<GamificationSummary>(
            stream: GamificationService.instance.watchSummary(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('No pudimos cargar tus puntos e insignias.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final summary = snapshot.data!;
              final unlocked = _badges
                  .where((badge) => badge.requirement(summary))
                  .length;
              return ListView(
                children: [
                  const Text(
                    'Tus logros',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Cada aporte a la comunidad suma.'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 27,
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.orange,
                          child: Icon(Icons.stars_rounded, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${summary.points} puntos',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '$unlocked de ${_badges.length} insignias desbloqueadas',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Insignias',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ..._badges.map(
                    (badge) => _BadgeCard(badge: badge, summary: summary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Puntos: 10 por publicar, 2 por dar Me gusta a otra persona y 3 por comentar. Cada publicación y cada Me gusta cuentan una sola vez.',
                    style: TextStyle(color: Color(0xFF657279), fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BadgeDefinition {
  const _BadgeDefinition({
    required this.title,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.progress,
    required this.goal,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool Function(GamificationSummary) requirement;
  final int Function(GamificationSummary) progress;
  final int goal;
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.summary});

  final _BadgeDefinition badge;
  final GamificationSummary summary;

  @override
  Widget build(BuildContext context) {
    final earned = badge.requirement(summary);
    final progress = badge.progress(summary);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: earned ? Colors.white : const Color(0xFFF8F7F6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF0EEEB)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: earned ? const Color(0xFFFFE0D2) : Colors.white,
          foregroundColor: earned ? AppTheme.orange : const Color(0xFF879197),
          child: Icon(badge.icon),
        ),
        title: Text(
          badge.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              earned
                  ? 'Desbloqueada · ${badge.description}'
                  : badge.description,
            ),
            if (!earned) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress / badge.goal),
              const SizedBox(height: 3),
              Text('$progress de ${badge.goal}'),
            ],
          ],
        ),
        trailing: Icon(
          earned ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          color: earned ? AppTheme.orange : const Color(0xFF879197),
        ),
      ),
    );
  }
}
