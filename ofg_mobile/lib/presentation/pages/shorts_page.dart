// lib/presentation/pages/shorts_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../models/ofg_models.dart';
import '../theme/ofg_theme.dart';
import '../widgets/local_video_player.dart';

class ShortsPage extends ConsumerStatefulWidget {
  final Function(OfgVideo) onCommentTap;

  const ShortsPage({super.key, required this.onCommentTap});

  @override
  ConsumerState<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends ConsumerState<ShortsPage> {
  int _shortIndex = 0;

  String _resolveVideoUrl(String path) {
    if (path.isEmpty) return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4';
    if (path.startsWith('http')) return path;
    final baseUrl = ref.read(apiClientProvider).baseUrl;
    return '${baseUrl.replaceAll(RegExp(r'/$'), '')}$path';
  }

  @override
  Widget build(BuildContext context) {
    final shortsAsync = ref.watch(shortsProvider);

    return shortsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (err, stack) => const Center(child: Text("Error loading shorts.", style: TextStyle(color: Colors.white))),
      data: (shorts) {
        if (shorts.isEmpty) return const Center(child: Text("No shorts available."));

        return PageView.builder(
          scrollDirection: Axis.vertical,
          controller: PageController(initialPage: _shortIndex),
          onPageChanged: (index) => setState(() => _shortIndex = index),
          itemCount: shorts.length,
          itemBuilder: (context, index) {
            final short = shorts[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: LocalVideoPlayer(
                    url: _resolveVideoUrl(short.mediaUrl),
                    isShort: true,
                    shouldPlay: index == _shortIndex,
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Following', style: TextStyle(color: Colors.white54)),
                          SizedBox(width: 22),
                          Text('For You', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          SizedBox(width: 22),
                          Text('Trending', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 120,
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(radius: 21, backgroundColor: kPanel2, child: Icon(Icons.person, color: Colors.white70)),
                      ),
                      const SizedBox(height: 22),
                      _railAction(short.liked ? Icons.favorite : Icons.favorite_border, _formatViews(short.likes), short.liked ? kAccent : Colors.white),
                      _railAction(Icons.mode_comment_outlined, _formatViews(short.comments), Colors.white, onTap: () => widget.onCommentTap(short)),
                      _railAction(Icons.ios_share, 'Share', Colors.white),
                      _railAction(short.saved ? Icons.bookmark : Icons.bookmark_border, 'Save', Colors.white),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 88,
                  bottom: 118,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(short.creator, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Text(short.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _railAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  String _formatViews(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}