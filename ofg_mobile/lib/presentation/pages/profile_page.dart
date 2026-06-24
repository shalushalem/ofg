import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../../api/api_client.dart';
import '../../logic/providers.dart';
import 'donation_history_page.dart';
import 'creator_earnings_page.dart';

class ProfilePage extends ConsumerWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onCreatorTap;
  final VoidCallback onPremiumTap;
  final VoidCallback onNotificationTap;

  const ProfilePage({
    super.key,
    required this.onSettingsTap,
    required this.onCreatorTap,
    required this.onPremiumTap,
    required this.onNotificationTap,
  });

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiClientProvider).delete('/auth/logout');
      } catch (_) {}
      await OfgStorage.clear();
      ref.read(apiClientProvider).token = null;
      ref.read(authStateProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final statsAsync = ref.watch(creatorStatsProvider);

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit profile coming soon')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettingsTap,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: CreatorAvatar(
                name: user.name,
                avatarUrl: user.avatarUrl,
                verified: user.isVerified,
                radius: 48,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              user.handle,
              style: const TextStyle(color: kMuted, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user.subscription == 'Premium' ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : kPanel2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: user.subscription == 'Premium' ? const Color(0xFFD4AF37) : kBorder),
              ),
              child: Text(
                user.subscription,
                style: TextStyle(
                  color: user.subscription == 'Premium' ? const Color(0xFFD4AF37) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: statsAsync.when(
                data: (stats) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(label: 'Uploads', value: stats['videos'].toString()),
                    _StatColumn(label: 'Views', value: stats['views'].toString()),
                    _StatColumn(label: 'Followers', value: stats['followers'].toString()),
                    _StatColumn(label: 'Likes', value: stats['likes'].toString()),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading stats', style: TextStyle(color: kMuted)),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCreatorTap,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: ofgPanelDecoration(),
                        child: const Column(
                          children: [
                            Icon(Icons.dashboard_outlined, size: 32, color: Colors.white),
                            SizedBox(height: 8),
                            Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: onPremiumTap,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.workspace_premium, size: 32, color: Color(0xFFD4AF37)),
                            SizedBox(height: 8),
                            Text('OFG Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Menus
            SettingsRow(
              icon: Icons.dashboard_outlined,
              label: 'Creator Studio',
              onTap: onCreatorTap,
            ),
            SettingsRow(
              icon: Icons.trending_up_outlined,
              label: 'Earnings',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreatorEarningsPage())),
            ),
            SettingsRow(
              icon: Icons.favorite_outline,
              label: 'My Donations',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DonationHistoryPage())),
            ),
            SettingsRow(
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: onNotificationTap,
            ),
            SettingsRow(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: onSettingsTap,
            ),
            SettingsRow(
              icon: Icons.logout,
              label: 'Log Out',
              iconColor: kAccent,
              labelColor: kAccent,
              onTap: () => _logout(context, ref),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
      ],
    );
  }
}