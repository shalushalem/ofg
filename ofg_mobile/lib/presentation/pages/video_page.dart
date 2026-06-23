// lib/presentation/pages/video_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../models/ofg_models.dart';
import '../theme/ofg_theme.dart';
import '../widgets/local_video_player.dart';
import '../widgets/ofg_ui.dart';
import '../widgets/striped_media.dart';

class VideoPage extends ConsumerWidget {
  final OfgVideo video;
  final VoidCallback onBack;
  final Function(OfgVideo) onRelatedTap;

  const VideoPage({
    super.key,
    required this.video,
    required this.onBack,
    required this.onRelatedTap,
  });

  String _resolveVideoUrl(String path, WidgetRef ref) {
    if (path.isEmpty) return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4';
    if (path.startsWith('http')) return path;
    final baseUrl = ref.read(apiClientProvider).baseUrl;
    return '${baseUrl.replaceAll(RegExp(r'/$'), '')}$path';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch feed to get related videos
    final feedAsync = ref.watch(feedProvider);
    final related = feedAsync.valueOrNull?.where((v) => v.id != video.id && !v.isShort).take(4).toList() ?? [];

    return SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 232,
                child: LocalVideoPlayer(
                  url: _resolveVideoUrl(video.mediaUrl, ref),
                  isShort: false,
                  shouldPlay: true,
                ),
              ),
              Positioned(
                top: 54,
                left: 18,
                child: GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, height: 1.25),
                ),
                const SizedBox(height: 9),
                Text('${video.views} views', style: const TextStyle(color: kMuted, fontSize: 13)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: ofgPanelDecoration(radius: 16),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 22, backgroundColor: kPanel2, child: Icon(Icons.person, color: Colors.white70)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video.creator, style: const TextStyle(fontWeight: FontWeight.w900)),
                            const Text('Subscriber count', style: TextStyle(color: kMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: ofgPanelDecoration(radius: 14, color: const Color(0xFF0D0D0D)),
                  child: Text(video.description.isEmpty ? 'No description provided.' : video.description, style: const TextStyle(color: Color(0xFFAAAAAA), height: 1.55)),
                ),
                const SizedBox(height: 26),
                const Text('Up Next', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                ...related.map((v) => _compactVideoRow(v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactVideoRow(OfgVideo v) {
    return GestureDetector(
      onTap: () => onRelatedTap(v),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            SizedBox(
              width: 132, height: 76,
              child: StripedMedia(label: '', radius: 11),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(v.creator, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}