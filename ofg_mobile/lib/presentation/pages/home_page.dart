// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../models/ofg_models.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../widgets/striped_media.dart';

class HomePage extends ConsumerWidget {
  final Function(OfgVideo) onVideoTap;
  final VoidCallback onSearchTap;

  const HomePage({
    super.key,
    required this.onVideoTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the real data from the backend
    final feedAsync = ref.watch(feedProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: kAccent,
        backgroundColor: kPanel,
        onRefresh: () async {
          // Force a fresh pull from the server
          ref.invalidate(feedProvider);
          ref.invalidate(shortsProvider);
        },
        child: feedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
          error: (err, stack) => _buildErrorState(err.toString(), ref),
          data: (videos) => _buildFeed(videos),
        ),
      ),
    );
  }

  Widget _buildFeed(List<OfgVideo> videos) {
    if (videos.isEmpty) {
      return const Center(child: Text("No videos found on server."));
    }

    final live = videos.where((v) => v.isLive).toList();
    final hero = videos.first;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _homeHeader()),
        SliverToBoxAdapter(child: _categoryChips()),
        SliverToBoxAdapter(child: _heroCard(hero)),
        if (live.isNotEmpty) SliverToBoxAdapter(child: _liveSection(live)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text(
              'Latest',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: videos.length,
          itemBuilder: (context, index) => _feedCard(videos[index]),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white54, size: 60),
            const SizedBox(height: 16),
            Text(
              "Could not connect to server.\n$error",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            OfgOutlineButton(
              label: "Retry",
              onTap: () => ref.invalidate(feedProvider),
            )
          ],
        ),
      ),
    );
  }

  Widget _homeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const OfgLogo(size: 21, connects: false),
          const Spacer(),
          IconButton(
            tooltip: 'Search',
            onPressed: onSearchTap,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: const [
                Icon(Icons.notifications_none, color: Colors.white),
                Positioned(
                  right: 1,
                  top: 1,
                  child: CircleAvatar(radius: 4, backgroundColor: kAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    final cats = ['For You', 'Worship', 'Sermons', 'Music', 'Kids', 'Live'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = cats[index];
          final active = index == 0; // Simplified for now
          return ChoiceChip(
            label: Text(label),
            selected: active,
            showCheckmark: false,
            selectedColor: Colors.white,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: active ? Colors.white : kBorder),
            labelStyle: TextStyle(
              color: active ? Colors.black : kMuted,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          );
        },
      ),
    );
  }

  Widget _heroCard(OfgVideo video) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: GestureDetector(
        onTap: () => onVideoTap(video),
        child: SizedBox(
          height: 206,
          child: StripedMedia(
            label: video.label,
            radius: 20,
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.16),
                      border: Border.all(color: kAccent.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      video.isLive ? 'LIVE NOW' : 'This Sunday',
                      style: const TextStyle(
                        color: kAccentSoft,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, height: 1.05),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${video.creator} - ${_formatViews(video.views)} views',
                    style: const TextStyle(color: Color(0xFF9A9A9A)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _feedCard(OfgVideo video) {
    return GestureDetector(
      onTap: () => onVideoTap(video),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 212,
              child: StripedMedia(
                label: video.label,
                radius: 0,
                child: Stack(
                  children: [
                    Positioned(
                      right: 14,
                      bottom: 10,
                      child: _duration(video.duration),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: kPanel2,
                    child: Icon(Icons.person, color: Colors.white54),
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
                            color: Color(0xFFF0F0F0),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${video.creator} - ${_formatViews(video.views)} views',
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz, color: Color(0xFF888888)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveSection(List<OfgVideo> live) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 13),
            child: Row(
              children: const [
                CircleAvatar(radius: 4, backgroundColor: kAccent),
                SizedBox(width: 8),
                Text('Live Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          SizedBox(
            height: 198,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: live.length,
              separatorBuilder: (context, index) => const SizedBox(width: 13),
              itemBuilder: (context, index) {
                final video = live[index];
                return GestureDetector(
                  onTap: () => onVideoTap(video),
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 142,
                          child: StripedMedia(
                            label: 'service live',
                            radius: 14,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 9,
                                  top: 9,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(video.creator, style: const TextStyle(color: kMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _duration(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  String _formatViews(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}