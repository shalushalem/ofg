import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';
import '../../api/api_client.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> with SingleTickerProviderStateMixin {
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

  Future<void> _featureVideo(OfgVideo video) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/admin/videos/${video.id}/feature', {}, admin: true);
      ref.invalidate(adminVideosProvider);
      ref.invalidate(feedProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(video.isFeatured ? 'Video unfeatured' : 'Video featured!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update feature status')));
    }
  }

  Future<void> _removeVideo(OfgVideo video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove Video?'),
        content: const Text('This will soft-delete the video from all feeds.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove', style: TextStyle(color: kAccent))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiClientProvider).delete('/admin/videos/${video.id}', admin: true);
        ref.invalidate(adminVideosProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video removed')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove video')));
      }
    }
  }

  Future<void> _resolveReport(String reportId, String status) async {
    try {
      await ref.read(apiClientProvider).post(
        '/admin/reports/$reportId/resolve',
        {'status': status},
        admin: true,
      );
      ref.invalidate(adminReportsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to resolve report')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    if (user == null || !user.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Unauthorized: Admin access required', style: TextStyle(color: kAccent))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            OfgLogo(size: 16, connects: false),
            SizedBox(width: 8),
            Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kAccent,
          labelColor: Colors.white,
          unselectedLabelColor: kMuted,
          tabs: const [Tab(text: 'Videos'), Tab(text: 'Reports')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideosTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildVideosTab() {
    final videosAsync = ref.watch(adminVideosProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminVideosProvider);
        await ref.read(adminVideosProvider.future);
      },
      child: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) return const Center(child: Text('No videos found'));
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: ofgPanelDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('by ${v.creator} • ${v.views} views', style: const TextStyle(color: kMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (v.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Featured', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _featureVideo(v),
                          icon: Icon(v.isFeatured ? Icons.star : Icons.star_border, color: v.isFeatured ? const Color(0xFFD4AF37) : kMuted, size: 18),
                          label: Text(v.isFeatured ? 'Unfeature' : 'Feature', style: TextStyle(color: v.isFeatured ? const Color(0xFFD4AF37) : kMuted)),
                        ),
                        TextButton.icon(
                          onPressed: () => _removeVideo(v),
                          icon: const Icon(Icons.delete_outline, color: kAccent, size: 18),
                          label: const Text('Remove', style: TextStyle(color: kAccent)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReportsTab() {
    final reportsAsync = ref.watch(adminReportsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminReportsProvider);
        await ref.read(adminReportsProvider.future);
      },
      child: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) return const OfgEmptyState(icon: Icons.shield_outlined, title: 'No pending reports');
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              final id = r['id'] as String;
              final type = r['type'] as String;
              final reason = r['reason'] as String;
              final targetId = r['target_id'] as String;
              final reporterId = r['reporter_id'] as String;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: ofgPanelDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                          child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('Target: ${targetId.substring(0, 8)}...', style: const TextStyle(color: kMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Reason: $reason', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Reported by User #${reporterId.substring(0, 8)}', style: const TextStyle(color: kMuted, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _resolveReport(id, 'dismissed'),
                          child: const Text('Dismiss', style: TextStyle(color: kMuted)),
                        ),
                        TextButton(
                          onPressed: () => _resolveReport(id, 'resolved'),
                          child: const Text('Resolve', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
