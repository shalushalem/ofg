import 'package:flutter/material.dart';
import '../theme/ofg_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(
          title: 'OFG Connects — Privacy Policy',
          subtitle: 'Effective Date: June 24, 2025\nLast Updated: June 24, 2025',
        ),
        const _Divider(),

        const _SectionTitle('1. Introduction'),
        const _Body(
          'Welcome to OFG Connects ("OFG", "we", "us", or "our"). OFG Connects is a Christian media streaming platform that empowers pastors, worship leaders, Bible teachers, and ministry creators to share the Gospel digitally.\n\n'
          'This Privacy Policy explains how we collect, use, protect, and share your personal information when you use our mobile application and related services. By using OFG Connects, you agree to the practices described in this policy.',
        ),

        const _SectionTitle('2. Information We Collect'),
        const _SubTitle('2.1 Information You Provide'),
        const _Body(
          '• Account Registration: Name, email address, password (stored as a salted hash — never in plain text), and optional profile photo.\n'
          '• Profile Information: Display name, username handle, bio.\n'
          '• Content: Videos, thumbnails, descriptions you upload.\n'
          '• Messages: Comments you post and messages you send to creators.\n'
          '• Donations: Donation amount, optional message, and anonymity preference. Payment processing is handled by Razorpay — we do not store your card or UPI details.\n'
          '• Support Requests: Information you provide when contacting us.',
        ),

        const _SubTitle('2.2 Information Collected Automatically'),
        const _Body(
          '• Usage Data: Videos watched, watch duration, likes, saves, and shares.\n'
          '• Device Information: Device type, operating system, and app version.\n'
          '• Log Data: IP address, timestamps, and error logs (for debugging only).\n'
          '• Recommendation Signals: Watch completion rate, category preferences, and engagement patterns used to personalize your feed.',
        ),

        const _SectionTitle('3. How We Use Your Information'),
        const _Body(
          '• To create and manage your account.\n'
          '• To deliver personalized content recommendations.\n'
          '• To process donations between users and creators.\n'
          '• To send notifications about activity relevant to you (new donations, comments, follows).\n'
          '• To maintain platform safety and prevent fraud.\n'
          '• To improve our app and fix bugs.\n'
          '• To comply with applicable laws.',
        ),

        const _SectionTitle('4. How We Share Your Information'),
        const _Body(
          'We do not sell your personal data. We may share information only in these circumstances:\n\n'
          '• With Creators: If you donate publicly, your name is visible to the creator. If you choose Anonymous, only "Anonymous Supporter" is shown.\n'
          '• With Razorpay: For payment processing. Subject to Razorpay\'s Privacy Policy.\n'
          '• With Cloudflare: Video and media storage via Cloudflare R2.\n'
          '• For Legal Compliance: If required by law, court order, or to protect our rights.\n'
          '• Business Transfers: In the event of a merger or acquisition, with advance notice.',
        ),

        const _SectionTitle('5. Data Security'),
        const _Body(
          'We protect your data using:\n'
          '• Salted SHA-256 password hashing — your password is never stored in plain text.\n'
          '• Secure HTTPS connections for all data in transit.\n'
          '• Encrypted secure token storage on your device.\n'
          '• Regular security reviews.\n\n'
          'No system is 100% secure. In the event of a data breach, we will notify affected users within 72 hours.',
        ),

        const _SectionTitle('6. Data Retention'),
        const _Body(
          '• Account data is retained while your account is active.\n'
          '• You may delete your account at any time via Settings → Delete Account.\n'
          '• After deletion, most data is removed within 30 days, except records required for legal compliance (e.g., donation transaction records required for tax purposes, retained for 7 years).',
        ),

        const _SectionTitle('7. Your Rights'),
        const _Body(
          'You have the right to:\n'
          '• Access the personal data we hold about you.\n'
          '• Request correction of inaccurate data.\n'
          '• Request deletion of your account and associated data.\n'
          '• Opt out of non-essential notifications.\n'
          '• Request a copy of your data.\n\n'
          'To exercise these rights, contact us at: ofgtechhub@gmail.com',
        ),

        const _SectionTitle('8. Children\'s Privacy'),
        const _Body(
          'OFG Connects is not directed at children under 13. We do not knowingly collect personal information from children under 13. If we learn we have collected such data, we will delete it immediately. Parents who believe their child has registered should contact ofgtechhub@gmail.com.',
        ),

        const _SectionTitle('9. Third-Party Links'),
        const _Body(
          'Our app may contain links to external websites or services. We are not responsible for the privacy practices of third-party services. We encourage you to review the privacy policies of any external services you use.',
        ),

        const _SectionTitle('10. Cookies and Tracking'),
        const _Body(
          'Our mobile app does not use browser cookies. We use secure local storage on your device only to maintain your login session and preferences. We do not use cross-app tracking.',
        ),

        const _SectionTitle('11. Changes to This Policy'),
        const _Body(
          'We may update this Privacy Policy from time to time. We will notify you of significant changes via an in-app notification and update the "Last Updated" date at the top of this page. Continued use of the app after changes indicates acceptance.',
        ),

        const _SectionTitle('12. Contact Us'),
        const _Body(
          'For privacy-related questions or requests:\n\n'
          '📧 Email: ofgtechhub@gmail.com\n'
          '🌐 Website: www.ofgconnects.com\n'
          '📍 OFG Connects, India\n\n'
          '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you." — Jeremiah 29:11',
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ---- Shared style widgets ----
class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 13)),
      const SizedBox(height: 16),
    ],
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(color: kBorder),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
  );
}

class _SubTitle extends StatelessWidget {
  final String text;
  const _SubTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kAccent)),
  );
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: kMuted, fontSize: 14, height: 1.6),
  );
}
