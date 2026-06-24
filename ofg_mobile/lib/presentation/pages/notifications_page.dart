import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../../api/api_client.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  final Function(String videoId)? onVideoTapById;
  const NotificationsPage({super.key, this.onVideoTapById});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String _formatTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 1) return '${diff.inDays} days ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'like': return Icons.favorite;
      case 'comment': return Icons.chat_bubble;
      case 'follow': return Icons.person_add;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'like': return kAccent;
      case 'comment': return const Color(0xFF1DA1F2);
      case 'follow': return const Color(0xFF17BF63);
      default: return Colors.white;
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(apiClientProvider).post('/notifications/read-all', {});
      ref.invalidate(notificationsProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const OfgEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications yet',
              subtitle: 'When people like, comment, or follow you, you\'ll see it here.',
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final n = items[index];
              return InkWell(
                onTap: () {
                  if (n.videoId != null && widget.onVideoTapById != null) {
                    widget.onVideoTapById!(n.videoId!);
                  }
                },
                child: Container(
                  color: n.isRead ? Colors.transparent : kPanel2.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: _getColorForType(n.type).withValues(alpha: 0.15),
                        radius: 20,
                        child: Icon(_getIconForType(n.type), color: _getColorForType(n.type), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.message, style: const TextStyle(fontSize: 15, height: 1.3)),
                            const SizedBox(height: 6),
                            Text(_formatTime(n.createdAt), style: const TextStyle(color: kMuted, fontSize: 12)),
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
        error: (_, __) => const Center(child: Text('Error loading notifications')),
      ),
    );
  }
}
