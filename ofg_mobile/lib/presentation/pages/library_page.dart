import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';

class LibraryPage extends ConsumerStatefulWidget {
  final Function(OfgVideo) onVideoTap;

  const LibraryPage({super.key, required this.onVideoTap});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(libraryHistoryProvider);
    final savedAsync = ref.watch(librarySavedProvider);

    int savedVideosCount = savedAsync.value?.length ?? 0;
    int savedShortsCount = savedAsync.value?.where((v) => v.isShort).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildLibraryTile(Icons.watch_later_outlined, 'Watch Later', '$savedVideosCount videos'),
                _buildLibraryTile(Icons.download_done_outlined, 'Downloads', '0 files'),
                _buildLibraryTile(Icons.play_circle_outline, 'Saved Shorts', '$savedShortsCount shorts'),
                _buildLibraryTile(Icons.playlist_play, 'Playlists', '0 playlists'),
              ],
            ),
          ),
          
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: kMuted,
            tabs: const [
              Tab(text: 'History'),
              Tab(text: 'Saved'),
            ],
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // History Tab
                historyAsync.when(
                  data: (videos) {
                    if (videos.isEmpty) {
                      return const OfgEmptyState(
                        icon: Icons.history,
                        title: 'No watch history',
                        subtitle: 'Videos you watch will appear here.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: videos.length,
                      itemBuilder: (context, index) => _buildCompactVideoRow(videos[index]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading history')),
                ),
                
                // Saved Tab
                savedAsync.when(
                  data: (videos) {
                    if (videos.isEmpty) {
                      return const OfgEmptyState(
                        icon: Icons.bookmark_border,
                        title: 'No saved videos',
                        subtitle: 'Videos you save will appear here.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: videos.length,
                      itemBuilder: (context, index) => _buildCompactVideoRow(videos[index]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading saved videos')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ofgPanelDecoration(),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVideoRow(OfgVideo video) {
    return InkWell(
      onTap: () => widget.onVideoTap(video),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 140,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(video.thumbnailUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: kPanel2)),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: Colors.black87,
                        child: Text(video.duration, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(video.creator, style: const TextStyle(color: kMuted, fontSize: 12)),
                  Text('${video.views} views', style: const TextStyle(color: kMuted, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: kMuted, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}