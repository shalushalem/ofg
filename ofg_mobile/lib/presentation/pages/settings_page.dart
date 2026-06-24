import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
import 'contact_us_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  const SettingsPage({super.key, required this.onLogout});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notifFollowers = true;
  bool _notifComments = true;
  bool _notifLikes = true;
  bool _autoplay = true;
  String _videoQuality = 'Auto';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifFollowers = prefs.getBool('notif_followers') ?? true;
      _notifComments = prefs.getBool('notif_comments') ?? true;
      _notifLikes = prefs.getBool('notif_likes') ?? true;
      _autoplay = prefs.getBool('autoplay') ?? true;
      _videoQuality = prefs.getString('video_quality') ?? 'Auto';
    });
  }

  Future<void> _setPref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        children: [
          const SectionHeader(title: 'Account'),
          SettingsRow(icon: Icons.person_outline, label: 'Edit Profile', onTap: _showComingSoon),
          SettingsRow(icon: Icons.lock_outline, label: 'Change Password', onTap: _showComingSoon),
          SettingsRow(icon: Icons.star_border, label: 'Subscription', value: 'Free', onTap: _showComingSoon),

          const SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('New followers'),
            value: _notifFollowers,
            onChanged: (v) { setState(() => _notifFollowers = v); _setPref('notif_followers', v); },
          ),
          SwitchListTile(
            title: const Text('New comments'),
            value: _notifComments,
            onChanged: (v) { setState(() => _notifComments = v); _setPref('notif_comments', v); },
          ),
          SwitchListTile(
            title: const Text('New likes'),
            value: _notifLikes,
            onChanged: (v) { setState(() => _notifLikes = v); _setPref('notif_likes', v); },
          ),

          const SectionHeader(title: 'Content'),
          SwitchListTile(
            title: const Text('Autoplay videos'),
            value: _autoplay,
            onChanged: (v) { setState(() => _autoplay = v); _setPref('autoplay', v); },
          ),
          SettingsRow(
            icon: Icons.high_quality,
            label: 'Default video quality',
            value: _videoQuality,
            onTap: () async {
              final val = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Video Quality'),
                  children: ['Auto', '1080p', '720p', '480p'].map((q) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, q),
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(q)),
                  )).toList(),
                ),
              );
              if (val != null) {
                setState(() => _videoQuality = val);
                _setPref('video_quality', val);
              }
            },
          ),
          const SettingsRow(icon: Icons.language, label: 'Language', value: 'English'),

          const SectionHeader(title: 'About'),
          const SettingsRow(icon: Icons.info_outline, label: 'App version', value: '1.0.0'),
          SettingsRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
          ),
          SettingsRow(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage())),
          ),
          SettingsRow(
            icon: Icons.contact_support_outlined,
            label: 'Contact Us',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContactUsPage())),
          ),
          SettingsRow(icon: Icons.star_rate_outlined, label: 'Rate OFG Connects', onTap: _showComingSoon),

          const SectionHeader(title: 'Danger Zone'),
          SettingsRow(
            icon: Icons.logout,
            label: 'Log Out',
            labelColor: kAccent,
            iconColor: kAccent,
            onTap: widget.onLogout,
          ),
          SettingsRow(
            icon: Icons.delete_forever,
            label: 'Delete Account',
            labelColor: kMuted,
            iconColor: kMuted,
            onTap: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete Account?'),
                  content: const Text('This action is permanent and cannot be undone. All your videos and data will be lost.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
                    TextButton(onPressed: () { Navigator.pop(c); _showComingSoon(); }, child: const Text('Delete', style: TextStyle(color: kAccent))),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
