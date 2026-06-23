// lib/presentation/pages/library_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../models/ofg_models.dart';
import '../theme/ofg_theme.dart';
import '../widgets/striped_media.dart';

class LibraryPage extends ConsumerWidget {
  final Function(OfgVideo) onVideoTap;

  const LibraryPage({super.key, required this.onVideoTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a full production app, you'd have a specific libraryProvider.
    // For now, we'll watch the main feed to populate history/saved.
    final feedAsync = ref.watch(feedProvider);
    final videos = feedAsync.valueOrNull ?? [];
    
    // Simulating history/saved from your backend
    final history = videos.take(4).toList();
    final savedCount = videos.where((v) => v.saved).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          const Text(
            'Library',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.25,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            children: [
              _libraryTile(Icons.schedule, 'Watch Later', '$savedCount videos'),
              _libraryTile(Icons.download_outlined, 'Downloads', 'Local only'),
              _libraryTile(Icons.bookmark_border, 'Saved Shorts', '0 shorts'),
              _libraryTile(Icons.playlist_play, 'Playlists', '12 lists'),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Text(
                'History',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Clear', style: TextStyle(color: kMuted)),
              ),
            ],
          ),
          ...history.map((v) => _compactVideoRow(v)),
        ],
      ),
    );
  }

  Widget _libraryTile(IconData icon, String title, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPanel,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kPanel2,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(count, style: const TextStyle(color: kMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _compactVideoRow(OfgVideo video) {
    return GestureDetector(
      onTap: () => onVideoTap(video),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            SizedBox(
              width: 132,
              height: 76,
              child: StripedMedia(
                label: '',
                radius: 11,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(video.duration, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${video.creator} - ${video.views} views',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}