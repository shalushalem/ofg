import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../widgets/local_video_player.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';
import '../../api/api_client.dart';
import 'donation_sheet.dart';

class VideoPage extends ConsumerStatefulWidget {
  final OfgVideo video;
  final VoidCallback onBack;
  final Function(OfgVideo) onRelatedTap;

  const VideoPage({
    super.key,
    required this.video,
    required this.onBack,
    required this.onRelatedTap,
  });

  @override
  ConsumerState<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  late bool _liked;
  late bool _saved;
  late bool _following;
  late int _likeCount;
  bool _descExpanded = false;
  final _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.video.liked;
    _saved = widget.video.saved;
    _following = widget.video.following;
    _likeCount = widget.video.likes;

    // Report watch after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        ref.read(apiClientProvider).post('/videos/${widget.video.id}/watch', {
          'watchTime': 5,
          'completionRate': 0.1,
          'progress': 0,
        }).catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final prevLiked = _liked;
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });

    try {
      final res = await ref.read(apiClientProvider).post('/videos/${widget.video.id}/like', {});
      setState(() {
        _liked = res['liked'] as bool? ?? _liked;
        _likeCount = res['likeCount'] as int? ?? _likeCount;
      });
    } catch (e) {
      setState(() {
        _liked = prevLiked;
        _likeCount += _liked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to like video')),
      );
    }
  }

  Future<void> _toggleSave() async {
    final prevSaved = _saved;
    setState(() => _saved = !_saved);
    try {
      final res = await ref.read(apiClientProvider).post('/videos/${widget.video.id}/save', {});
      setState(() => _saved = res['saved'] as bool? ?? _saved);
    } catch (e) {
      setState(() => _saved = prevSaved);
    }
  }

  Future<void> _toggleFollow() async {
    final prevFollowing = _following;
    setState(() => _following = !_following);
    try {
      final res = await ref.read(apiClientProvider).post('/follow/${widget.video.creatorId}', {});
      setState(() => _following = res['following'] as bool? ?? _following);
    } catch (e) {
      setState(() => _following = prevFollowing);
    }
  }

  void _share() {
    Share.share('Check out ${widget.video.title} on OFG Connects!');
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPostingComment = true);
    try {
      await ref.read(apiClientProvider).post('/videos/${widget.video.id}/comments', {
        'content': content,
      });
      _commentController.clear();
      FocusScope.of(context).unfocus();
      ref.invalidate(videoCommentsProvider(widget.video.id));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: ${e is ApiException ? e.message : e}')),
      );
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: LocalVideoPlayer(
                    url: widget.video.mediaUrl,
                    isShort: false,
                    shouldPlay: true,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                      onPressed: widget.onBack,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.video.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.video.views} views • ${widget.video.createdAt}',
                            style: const TextStyle(color: kMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _ActionChip(
                            icon: _liked ? Icons.favorite : Icons.favorite_border,
                            label: _likeCount.toString(),
                            isActive: _liked,
                            onTap: _toggleLike,
                            activeColor: kAccent,
                          ),
                          const SizedBox(width: 12),
                          _ActionChip(
                            icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                            label: 'Save',
                            isActive: _saved,
                            onTap: _toggleSave,
                            activeColor: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          _ActionChip(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            isActive: false,
                            onTap: _share,
                          ),
                          const SizedBox(width: 12),
                          _ActionChip(
                            icon: Icons.more_vert,
                            label: 'More',
                            isActive: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Divider(color: kBorder),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CreatorAvatar(
                            name: widget.video.creator,
                            avatarUrl: widget.video.creatorAvatar,
                            verified: widget.video.creatorVerified,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.video.creator,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: _toggleFollow,
                            style: FilledButton.styleFrom(
                              backgroundColor: _following ? kPanel2 : Colors.white,
                              foregroundColor: _following ? Colors.white : Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(_following ? 'Following' : 'Follow'),
                          ),
                          const SizedBox(width: 8),
                          // Donate button — shown for other creators' videos
                          Builder(builder: (ctx) {
                            final me = ref.read(authStateProvider);
                            if (me != null && me.id == widget.video.creatorId) {
                              return const SizedBox.shrink();
                            }
                            return OutlinedButton.icon(
                              onPressed: () => DonationSheet.show(
                                ctx,
                                creatorId: widget.video.creatorId,
                                creatorName: widget.video.creator,
                                creatorAvatar: widget.video.creatorAvatar,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFD4AF37)),
                                foregroundColor: const Color(0xFFD4AF37),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: const Icon(Icons.favorite, size: 16),
                              label: const Text('Donate'),
                            );
                          }),
                        ],
                      ),
                    ),

                    if (widget.video.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(
                          onTap: () => setState(() => _descExpanded = !_descExpanded),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: ofgPanelDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.video.description,
                                  maxLines: _descExpanded ? null : 3,
                                  overflow: _descExpanded ? null : TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (!_descExpanded)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Show more',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                    const SectionHeader(title: 'Comments'),
                    _buildCommentsSection(),

                    const SectionHeader(title: 'Up Next'),
                    _buildUpNextSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final commentsAsync = ref.watch(videoCommentsProvider(widget.video.id));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const CreatorAvatar(name: 'Me', radius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: const TextStyle(color: kMuted),
                    border: InputBorder.none,
                    suffixIcon: _isPostingComment
                        ? const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(
                            icon: const Icon(Icons.send, color: kAccentSoft),
                            onPressed: _postComment,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: kBorder),
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No comments yet. Be the first!', style: TextStyle(color: kMuted)),
                );
              }
              return Column(
                children: comments.take(5).map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                                Text(
                                  c.userHandle,
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.when,
                                  style: const TextStyle(color: kMuted2, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.content, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.thumb_up_alt_outlined, size: 14, color: kMuted),
                                const SizedBox(width: 4),
                                if (c.likeCount > 0)
                                  Text(c.likeCount.toString(), style: const TextStyle(color: kMuted, fontSize: 12)),
                                const SizedBox(width: 16),
                                const Icon(Icons.thumb_down_alt_outlined, size: 14, color: kMuted),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
            error: (e, st) => Text('Failed to load comments', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpNextSection() {
    final feedAsync = ref.watch(feedProvider);
    return feedAsync.when(
      data: (videos) {
        final related = videos.where((v) => v.id != widget.video.id).take(5).toList();
        if (related.isEmpty) return const SizedBox(height: 100);
        
        return Column(
          children: related.map((v) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => widget.onRelatedTap(v),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 160,
                      height: 90,
                      child: Image.network(
                        v.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: kPanel2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(v.creator, style: const TextStyle(color: kMuted, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('${v.views} views', style: const TextStyle(color: kMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? (activeColor?.withValues(alpha: 0.15) ?? kPanel2) : kPanel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor ?? Colors.white : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor ?? Colors.white : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}