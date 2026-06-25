import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../widgets/local_video_player.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';
import '../../api/api_client.dart';

class ShortsPage extends ConsumerStatefulWidget {
  final Function(OfgVideo) onCommentTap;

  const ShortsPage({super.key, required this.onCommentTap});

  @override
  ConsumerState<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends ConsumerState<ShortsPage> {
  int _currentIndex = 0;

  Future<void> _toggleLike(OfgVideo video) async {
    final isLiked = ref.read(globalLikedProvider)[video.id] ?? video.liked;
    final currentLikes = ref.read(globalLikeCountProvider)[video.id] ?? video.likes;
    
    ref.read(globalLikedProvider.notifier).update((s) => {...s, video.id: !isLiked});
    ref.read(globalLikeCountProvider.notifier).update((s) => {...s, video.id: currentLikes + (isLiked ? -1 : 1)});

    try {
      final res = await ref.read(apiClientProvider).post('/videos/${video.id}/like', {});
      ref.read(globalLikedProvider.notifier).update((s) => {...s, video.id: res['liked'] as bool? ?? s[video.id]!});
      ref.read(globalLikeCountProvider.notifier).update((s) => {...s, video.id: res['likeCount'] as int? ?? s[video.id]!});
    } catch (e) {
      ref.read(globalLikedProvider.notifier).update((s) => {...s, video.id: isLiked});
      ref.read(globalLikeCountProvider.notifier).update((s) => {...s, video.id: currentLikes});
    }
  }

  Future<void> _toggleSave(OfgVideo video) async {
    final isSaved = ref.read(globalSavedProvider)[video.id] ?? video.saved;
    ref.read(globalSavedProvider.notifier).update((s) => {...s, video.id: !isSaved});

    try {
      final res = await ref.read(apiClientProvider).post('/videos/${video.id}/save', {});
      ref.read(globalSavedProvider.notifier).update((s) => {...s, video.id: res['saved'] as bool? ?? s[video.id]!});
    } catch (e) {
      ref.read(globalSavedProvider.notifier).update((s) => {...s, video.id: isSaved});
    }
  }

  Future<void> _toggleFollow(OfgVideo video) async {
    final isFollowing = ref.read(globalFollowingProvider)[video.creatorId] ?? video.following;
    ref.read(globalFollowingProvider.notifier).update((s) => {...s, video.creatorId: !isFollowing});

    try {
      final res = await ref.read(apiClientProvider).post('/follow/${video.creatorId}', {});
      ref.read(globalFollowingProvider.notifier).update((s) => {...s, video.creatorId: res['following'] as bool? ?? s[video.creatorId]!});
    } catch (e) {
      ref.read(globalFollowingProvider.notifier).update((s) => {...s, video.creatorId: isFollowing});
    }
  }

  void _share(OfgVideo video) {
    Share.share('Check out ${video.title} on OFG Connects!');
  }

  void _showComments(OfgVideo video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentSheet(video: video),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortsAsync = ref.watch(shortsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          shortsAsync.when(
            data: (shorts) {
              if (shorts.isEmpty) {
                return const Center(
                  child: Text('No shorts available. Check back soon!', style: TextStyle(color: Colors.white)),
                );
              }
              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: shorts.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  // Trigger watch event
                  ref.read(apiClientProvider).post('/videos/${shorts[index].id}/watch', {
                    'watchTime': 2,
                    'completionRate': 0,
                    'progress': 0,
                  }).catchError((_) {});
                },
                itemBuilder: (context, index) {
                  final video = shorts[index];
                  final likedMap = ref.watch(globalLikedProvider);
                  final savedMap = ref.watch(globalSavedProvider);
                  final likeCountMap = ref.watch(globalLikeCountProvider);
                  final followingMap = ref.watch(globalFollowingProvider);

                  final isLiked = likedMap[video.id] ?? video.liked;
                  final isSaved = savedMap[video.id] ?? video.saved;
                  final likeCount = likeCountMap[video.id] ?? video.likes;
                  final isFollowing = followingMap[video.creatorId] ?? video.following;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      LocalVideoPlayer(
                        url: video.mediaUrl,
                        isShort: true,
                        shouldPlay: index == _currentIndex,
                      ),
                      
                      // Bottom Info
                      Positioned(
                        bottom: 80,
                        left: 16,
                        right: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CreatorAvatar(
                                  name: video.creator,
                                  avatarUrl: video.creatorAvatar,
                                  verified: video.creatorVerified,
                                  radius: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  video.creator,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _toggleFollow(video),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isFollowing ? Colors.transparent : Colors.white,
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isFollowing ? 'Following' : 'Subscribe',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isFollowing ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      // Right Action Bar
                      Positioned(
                        bottom: 80,
                        right: 8,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                              icon: isLiked ? Icons.favorite : Icons.favorite_border,
                              label: likeCount.toString(),
                              color: isLiked ? kAccent : Colors.white,
                              onTap: () => _toggleLike(video),
                            ),
                            const SizedBox(height: 16),
                            _buildActionButton(
                              icon: Icons.chat_bubble_outline,
                              label: video.comments.toString(),
                              onTap: () => _showComments(video),
                            ),
                            const SizedBox(height: 16),
                            _buildActionButton(
                              icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                              label: 'Save',
                              onTap: () => _toggleSave(video),
                            ),
                            const SizedBox(height: 16),
                            _buildActionButton(
                              icon: Icons.share,
                              label: 'Share',
                              onTap: () => _share(video),
                            ),
                            const SizedBox(height: 16),
                            _buildActionButton(
                              icon: Icons.more_vert,
                              label: '',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Center(child: Text('Failed to load shorts', style: TextStyle(color: Colors.white))),
          ),
          
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Shorts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}

class _CommentSheet extends ConsumerStatefulWidget {
  final OfgVideo video;
  const _CommentSheet({required this.video});

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await ref.read(apiClientProvider).post('/videos/${widget.video.id}/comments', {
        'content': content,
      });
      _commentController.clear();
      FocusScope.of(context).unfocus();
      ref.invalidate(videoCommentsProvider(widget.video.id));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(videoCommentsProvider(widget.video.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kPanel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: kBorder),
              Expanded(
                child: commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) return const Center(child: Text('No comments yet.'));
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CreatorAvatar(name: c.user, radius: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(c.userHandle, style: const TextStyle(color: kMuted, fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Text(c.when, style: const TextStyle(color: kMuted, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(c.content, style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading comments')),
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 16, right: 16, top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                decoration: const BoxDecoration(
                  color: kBg,
                  border: Border(top: BorderSide(color: kBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _isPosting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, color: kAccent),
                      onPressed: _postComment,
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