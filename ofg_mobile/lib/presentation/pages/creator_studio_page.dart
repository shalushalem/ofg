import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../widgets/striped_media.dart';
import '../../api/api_client.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';

class CreatorStudioPage extends ConsumerStatefulWidget {
  final VoidCallback onUploadTap;
  const CreatorStudioPage({super.key, required this.onUploadTap});

  @override
  ConsumerState<CreatorStudioPage> createState() => _CreatorStudioPageState();
}

class _CreatorStudioPageState extends ConsumerState<CreatorStudioPage> with SingleTickerProviderStateMixin {
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

  Future<void> _deleteVideo(OfgVideo video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Video?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: kAccent))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiClientProvider).delete('/creator/videos/${video.id}');
        ref.invalidate(creatorVideosProvider);
        ref.invalidate(creatorStatsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete video')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(creatorStatsProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onUploadTap,
        backgroundColor: Colors.white,
        child: const Icon(Icons.upload, color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: statsAsync.when(
              data: (stats) => Container(
                decoration: ofgPanelDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _StatBox('Total Views', stats['views'].toString())),
                        Container(width: 1, height: 40, color: kBorder),
                        Expanded(child: _StatBox('Total Videos', stats['videos'].toString())),
                      ],
                    ),
                    const Divider(color: kBorder, height: 32),
                    Row(
                      children: [
                        Expanded(child: _StatBox('Total Likes', stats['likes'].toString())),
                        Container(width: 1, height: 40, color: kBorder),
                        Expanded(child: _StatBox('Followers', stats['followers'].toString())),
                      ],
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading stats')),
            ),
          ),
          
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: kMuted,
            tabs: const [Tab(text: 'My Videos'), Tab(text: 'Analytics')],
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyVideos(),
                _buildAnalytics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyVideos() {
    final videosAsync = ref.watch(creatorVideosProvider);
    
    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const OfgEmptyState(
            icon: Icons.video_call,
            title: 'No videos yet',
            subtitle: 'Upload your first message!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final v = videos[index];
            return InkWell(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete, color: kAccent),
                        title: const Text('Delete', style: TextStyle(color: kAccent)),
                        onTap: () { Navigator.pop(context); _deleteVideo(v); },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 120,
                        height: 70,
                        child: StripedMedia(imageUrl: v.thumbnailUrl, label: v.duration),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              if (v.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Featured', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${v.views} views • ${v.likes} likes', style: const TextStyle(color: kMuted, fontSize: 12)),
                          Text('${v.comments} comments', style: const TextStyle(color: kMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading videos')),
    );
  }

  Widget _buildAnalytics() {
    final statsAsync = ref.watch(creatorStatsProvider);

    return statsAsync.when(
      data: (stats) {
        final totalWatchSecs = (stats['totalWatchTime'] as num?)?.toDouble() ?? 0.0;
        final watchHours = (totalWatchSecs / 3600).floor();
        final watchMins = ((totalWatchSecs % 3600) / 60).floor();
        final watchTimeStr = watchHours > 0 ? '${watchHours}h ${watchMins}m' : '${watchMins}m';
        final avgCompletion = ((stats['avgCompletionRate'] as num?)?.toDouble() ?? 0.0) * 100;
        final topCat = (stats['topCategory'] as String?)?.isNotEmpty == true
            ? stats['topCategory'] as String
            : '—';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ofgPanelDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Engagement Overview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _AnalyticsRow(label: 'Total Watch Time', value: watchTimeStr),
                    const SizedBox(height: 12),
                    _AnalyticsRow(
                      label: 'Avg Completion Rate',
                      value: '${avgCompletion.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 12),
                    _AnalyticsRow(label: 'Top Category', value: topCat),
                    const SizedBox(height: 12),
                    _AnalyticsRow(label: 'Total Views', value: _fmt(stats['views'])),
                    const SizedBox(height: 12),
                    _AnalyticsRow(label: 'Total Likes', value: _fmt(stats['likes'])),
                    const SizedBox(height: 12),
                    _AnalyticsRow(label: 'Followers', value: _fmt(stats['followers'])),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if ((stats['videos'] as num? ?? 0) == 0)
                const Text(
                  'Upload videos to see detailed analytics here.',
                  style: TextStyle(color: kMuted),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kMuted, size: 40),
            const SizedBox(height: 12),
            Text(e.toString(), style: const TextStyle(color: kMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
      ],
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;
  const _AnalyticsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
