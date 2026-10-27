import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../models/pet_post.dart';
import '../services/post_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import 'comments_sheet.dart';
import 'post_composer_dialog.dart';

/// Shows the real-time feed for signed-in PetVerse users.
class FeedScreen extends StatefulWidget {
  const FeedScreen({required this.user, super.key});

  final User user;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final Stream<List<PetPost>> _feedStream;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _feedStream = PostService.instance.watchFeed();
  }

  Future<void> _openComposer() async {
    final draft = await showDialog<PostDraft>(
      context: context,
      builder: (_) => const PostComposerDialog(),
    );
    if (draft == null || !mounted) return;

    setState(() => _isPublishing = true);
    try {
      final profile = await UserProfileService.instance.getOrCreateProfile(
        widget.user,
      );
      await PostService.instance.createPost(
        authorId: widget.user.uid,
        authorName: profile.displayName,
        authorPhotoUrl: profile.photoUrl ?? widget.user.photoURL,
        caption: draft.caption,
        mediaUrl: draft.mediaUrl,
        mediaType: draft.mediaType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación compartida.')),
        );
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'permission-denied'
                ? 'Firestore rechazó la publicación. Publica las reglas nuevas.'
                : 'No pudimos publicar. Inténtalo otra vez.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos publicar. Inténtalo otra vez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.displayName?.trim();
    final greeting = name == null || name.isEmpty ? 'Hola' : 'Hola, $name';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final avatar = const CircleAvatar(
                    backgroundColor: Color(0xFFFFE0D2),
                    child: Icon(Icons.pets_rounded, color: AppTheme.orange),
                  );
                  final prompt = Text(
                    '$greeting. ¿Qué pasa con tu mascota?',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  );
                  final publishButton = FilledButton.icon(
                    onPressed: _isPublishing ? null : _openComposer,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: const Text('Publicar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: Colors.white,
                    ),
                  );

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0EEEB)),
                    ),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  avatar,
                                  const SizedBox(width: 12),
                                  Expanded(child: prompt),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: publishButton,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              avatar,
                              const SizedBox(width: 12),
                              Expanded(child: prompt),
                              publishButton,
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<List<PetPost>>(
                  stream: _feedStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('No pudimos cargar las publicaciones.'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final posts = snapshot.data ?? const <PetPost>[];
                    if (posts.isEmpty) {
                      return const _EmptyFeed();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _PostCard(
                        key: ValueKey(posts[index].id),
                        post: posts[index],
                        user: widget.user,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dynamic_feed_rounded,
              size: 48,
              color: AppTheme.orange,
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no hay publicaciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Sé la primera persona en compartir un momento de tu mascota.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, required this.user, super.key});

  final PetPost post;
  final User user;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late final Stream<bool> _likedStream;
  bool _isTogglingLike = false;
  bool _showHeartBurst = false;
  Timer? _heartTimer;

  @override
  void initState() {
    super.initState();
    _likedStream = PostService.instance.watchLikedBy(
      widget.post.id,
      widget.user.uid,
    );
  }

  @override
  void dispose() {
    _heartTimer?.cancel();
    super.dispose();
  }

  void _animateLike() {
    _heartTimer?.cancel();
    setState(() => _showHeartBurst = true);
    _heartTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  String get _actorName {
    final name = widget.user.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return widget.user.email?.split('@').first ?? 'Usuario';
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;
    setState(() => _isTogglingLike = true);
    try {
      await PostService.instance.toggleLike(
        postId: widget.post.id,
        userId: widget.user.uid,
        actorName: _actorName,
      );
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos actualizar el Me gusta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingLike = false);
    }
  }

  Future<void> _openComments() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CommentsSheet(post: widget.post, user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy · HH:mm')
        .format(widget.post.createdAt);

    return StreamBuilder<bool>(
      stream: _likedStream,
      builder: (context, likedSnapshot) {
        final liked = likedSnapshot.data ?? false;
        return Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFF0EEEB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    _AuthorAvatar(
                      name: widget.post.authorName,
                      photoUrl: widget.post.authorPhotoUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.post.mediaUrl != null)
                GestureDetector(
                  onDoubleTap: () {
                    _animateLike();
                    if (!liked) _toggleLike();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _PostMedia(
                        url: widget.post.mediaUrl!,
                        type: widget.post.mediaType,
                      ),
                      IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _showHeartBurst ? 1 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: AnimatedScale(
                            scale: _showHeartBurst ? 1 : 0.55,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 96,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black38, blurRadius: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(widget.post.caption),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    AnimatedScale(
                      scale: liked ? 1.06 : 1,
                      duration: const Duration(milliseconds: 160),
                      child: IconButton(
                        tooltip: liked ? 'Quitar Me gusta' : 'Me gusta',
                        onPressed: _isTogglingLike ? null : () => _toggleLike(),
                        icon: Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: liked ? AppTheme.orange : AppTheme.ink,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        widget.post.likeCount.toString() + ' Me gusta',
                        key: ValueKey(widget.post.likeCount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openComments,
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Comentarios'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final firstLetter = name.isEmpty ? 'P' : name[0].toUpperCase();
    final fallback = CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFFFE0D2),
      foregroundColor: AppTheme.orange,
      child: Text(
        firstLetter,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.url, required this.type});

  final String url;
  final String type;

  @override
  Widget build(BuildContext context) {
    if (type == 'video') return _VideoPost(url: url);
    return Image.network(
      url,
      width: double.infinity,
      height: 340,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _MediaError(),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      color: const Color(0xFFFFF0E9),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 44, color: AppTheme.orange),
            SizedBox(height: 8),
            Text('No se pudo mostrar el enlace de este archivo.'),
          ],
        ),
      ),
    );
  }
}

class _VideoPost extends StatefulWidget {
  const _VideoPost({required this.url});

  final String url;

  @override
  State<_VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends State<_VideoPost> {
  late final VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _MediaError();
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        if (!value.isInitialized) {
          return const SizedBox(
            height: 250,
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.orange),
            ),
          );
        }
        return ColoredBox(
          color: Colors.black,
          child: AspectRatio(
            aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.only(bottom: 2),
                  colors: const VideoProgressColors(
                    playedColor: AppTheme.orange,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 12,
                  child: IconButton.filledTonal(
                    tooltip: value.isPlaying ? 'Pausar' : 'Reproducir',
                    onPressed: () {
                      if (value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    },
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
