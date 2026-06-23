// lib/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../theme/ofg_theme.dart';

class ProfilePage extends ConsumerWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onCreatorTap;
  final VoidCallback onPremiumTap;

  const ProfilePage({
    super.key,
    required this.onSettingsTap,
    required this.onCreatorTap,
    required this.onPremiumTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the real user from Riverpod state
    final user = ref.watch(authStateProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onSettingsTap,
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: kPanel2,
                  child: Icon(Icons.person, color: Colors.white70, size: 42),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.name ?? 'Guest Viewer',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        (user?.subscription ?? 'FREE').toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user?.handle ?? '@guest', style: const TextStyle(color: kMuted)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stat('128', 'Watching'),
                    _stat('42', 'Playlists'),
                    _stat('1.2M', 'Following'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onPremiumTap,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OFG Premium', style: TextStyle(fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text('4K - No ads - Downloads', style: TextStyle(color: kMuted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text('Manage', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _profileRow(Icons.dashboard_outlined, 'Creator Studio', onCreatorTap),
          _profileRow(Icons.star_border, 'Subscription', onPremiumTap),
          _profileRow(Icons.settings_outlined, 'Settings', onSettingsTap),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF141414))),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.chevron_right, color: kMuted2),
          ],
        ),
      ),
    );
  }
}