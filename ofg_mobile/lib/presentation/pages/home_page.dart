import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../widgets/striped_media.dart';
import '../../api/api_client.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';

class HomePage extends ConsumerStatefulWidget {
  final Function(OfgVideo) onVideoTap;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  const HomePage({
    super.key,
    required this.onVideoTap,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.value?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const OfgLogo(size: 22, connects: true),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: widget.onSearchTap,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: widget.onNotificationTap,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: kAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: kCategories.length,
              itemBuilder: (context, index) {
                final category = kCategories[index];
                final isSelected = index == _selectedCategoryIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategoryIndex = index);
                        ref.read(feedCategoryProvider.notifier).state = kCategoryApiMap[category];
                        ref.invalidate(feedProvider);
                      }
                    },
                    backgroundColor: kPanel,
                    selectedColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.white : kBorder,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedProvider);
          ref.invalidate(shortsProvider);
          ref.invalidate(notificationsProvider);
          await ref.read(feedProvider.future);
        },
        color: kAccent,
        backgroundColor: kPanel,
        child: feedAsync.when(
          data: (videos) {
            if (videos.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const OfgEmptyState(
                    icon: Icons.video_library_outlined,
                    title: 'No videos found',
                    subtitle: 'Try a different category or check back later.',
                  ),
                ),
              );
            }

            final liveVideos = videos.where((v) => v.isLive).toList();
            final featuredVideos = videos.where((v) => v.isFeatured && !v.isLive).toList();
            final otherVideos = videos.where((v) => !v.isLive && !v.isFeatured).toList();

            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (videos.isNotEmpty && !videos.first.isLive && !videos.first.isFeatured)
                  _buildHeroCard(videos.first),
                if (liveVideos.isNotEmpty) ...[
                  const SectionHeader(title: 'Live Now'),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: liveVideos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 280,
                            child: _buildFeedCard(liveVideos[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (featuredVideos.isNotEmpty) ...[
                  const SectionHeader(title: 'Featured'),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: featuredVideos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 280,
                            child: _buildFeedCard(featuredVideos[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SectionHeader(title: 'Latest Videos'),
                ...otherVideos.skip(videos.first == otherVideos.first ? 1 : 0).map((v) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildFeedCard(v),
                    )),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: kAccent),
          ),
          error: (err, stack) => Center(
            child: OfgEmptyState(
              icon: Icons.wifi_off,
              title: 'Connection Error',
              subtitle: err.toString(),
              buttonLabel: 'Retry',
              onButton: () => ref.invalidate(feedProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(OfgVideo video) {
    return GestureDetector(
      onTap: () => widget.onVideoTap(video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Hero(
                  tag: 'feed_${video.id}',
                  child: StripedMedia(
                    imageUrl: video.thumbnailUrl,
                    label: video.duration,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.duration,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreatorAvatar(
                  name: video.creator,
                  avatarUrl: video.creatorAvatar,
                  verified: video.creatorVerified,
                  radius: 24,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${video.creator} • ${video.meta}',
                        style: const TextStyle(
                          color: kMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: kMuted),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(OfgVideo video) {
    return GestureDetector(
      onTap: () => widget.onVideoTap(video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: 'short_${video.id}',
                    child: StripedMedia(
                      imageUrl: video.thumbnailUrl,
                      label: 'Short',
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.duration,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CreatorAvatar(
                name: video.creator,
                avatarUrl: video.creatorAvatar,
                verified: video.creatorVerified,
                radius: 20,
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${video.creator} • ${video.meta}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: kMuted, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}