import 'package:flutter/material.dart';
import '../theme/ofg_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _ToSContent(),
      ),
    );
  }
}

class _ToSContent extends StatelessWidget {
  const _ToSContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(
          title: 'OFG Connects — Terms of Service',
          subtitle: 'Effective Date: June 24, 2025\nLast Updated: June 24, 2025',
        ),
        const _Divider(),
        const _Body(
          'Please read these Terms of Service ("Terms") carefully before using the OFG Connects mobile application. By accessing or using OFG Connects, you agree to be bound by these Terms. If you do not agree, do not use our service.',
        ),

        const _SectionTitle('1. About OFG Connects'),
        const _Body(
          'OFG Connects is a Christian media streaming platform that allows users to watch, upload, and share ministry content — including sermons, worship music, Bible teachings, and devotionals. The platform also provides a donation system so users can financially support creators and ministries.',
        ),

        const _SectionTitle('2. Eligibility'),
        const _Body(
          '• You must be at least 13 years old to create an account.\n'
          '• You must provide accurate information during registration.\n'
          '• You are responsible for maintaining the security of your account credentials.\n'
          '• One person may not create multiple accounts to abuse platform features.',
        ),

        const _SectionTitle('3. User Accounts'),
        const _Body(
          '• You are responsible for all activity that occurs under your account.\n'
          '• You must notify us immediately if you suspect unauthorized access.\n'
          '• We reserve the right to suspend or terminate accounts that violate these Terms.\n'
          '• Account deletion requests will be processed within 30 days.',
        ),

        const _SectionTitle('4. Content Guidelines'),
        const _SubTitle('4.1 Permitted Content'),
        const _Body(
          'OFG Connects is a ministry-focused platform. Permitted content includes:\n'
          '• Sermons, Bible teachings, and devotionals.\n'
          '• Worship music and Christian songs.\n'
          '• Prayer sessions and spiritual guidance.\n'
          '• Church events, testimonies, and ministry updates.\n'
          '• Educational Christian content for all ages.',
        ),
        const _SubTitle('4.2 Prohibited Content'),
        const _Body(
          'You may NOT upload, share, or promote:\n'
          '• Content that contradicts core Biblical principles or promotes false doctrine in a deceptive way.\n'
          '• Sexually explicit, violent, or graphic material.\n'
          '• Hate speech, discrimination, or harassment based on race, religion, gender, or nationality.\n'
          '• Content that violates any applicable law.\n'
          '• Spam, scams, or misleading financial solicitations.\n'
          '• Third-party copyrighted material without authorization.\n'
          '• Any content designed to harm, exploit, or defraud users.',
        ),

        const _SectionTitle('5. Intellectual Property'),
        const _Body(
          '• Content you upload remains your property. By uploading, you grant OFG Connects a non-exclusive, royalty-free license to host, display, and distribute your content within the platform.\n'
          '• You represent that you own or have the rights to all content you upload.\n'
          '• The OFG Connects brand, logo, and app design are proprietary and may not be reproduced without permission.\n'
          '• Content that infringes third-party copyright will be removed upon valid DMCA notice.',
        ),

        const _SectionTitle('6. Donation System'),
        const _SubTitle('6.1 For Donors'),
        const _Body(
          '• Donations are voluntary and one-time in nature.\n'
          '• A platform fee of 10% is deducted from each donation. The remaining 90% is credited to the creator\'s wallet.\n'
          '• Donations are generally non-refundable unless there is proven fraud or unauthorized use.\n'
          '• Anonymous donations will not reveal your identity to the creator.\n'
          '• Payment processing is provided by Razorpay and is subject to their Terms of Service.',
        ),
        const _SubTitle('6.2 For Creators'),
        const _Body(
          '• Creators may receive donations from supporters.\n'
          '• Minimum payout threshold is ₹500.\n'
          '• Payout requests are reviewed and processed by OFG admin within 2–7 business days.\n'
          '• OFG reserves the right to withhold payouts pending fraud investigation.\n'
          '• Creators are solely responsible for declaring donation income to applicable tax authorities.',
        ),

        const _SectionTitle('7. User Conduct'),
        const _Body(
          'You agree not to:\n'
          '• Impersonate any person, ministry, or organization.\n'
          '• Harass, bully, or intimidate other users.\n'
          '• Use the platform for commercial purposes unrelated to ministry content without permission.\n'
          '• Attempt to reverse-engineer, hack, or disrupt the platform.\n'
          '• Use automated bots or scrapers to access platform data.\n'
          '• Create fake accounts or artificially inflate view/like counts.',
        ),

        const _SectionTitle('8. Content Moderation'),
        const _Body(
          '• OFG reserves the right to remove any content that violates these Terms.\n'
          '• Users may report content using the in-app report function.\n'
          '• Repeated violations may result in account suspension or permanent ban.\n'
          '• We are not obligated to monitor all content but will act on valid reports.',
        ),

        const _SectionTitle('9. Disclaimer of Warranties'),
        const _Body(
          'OFG Connects is provided "as is" without warranties of any kind. We do not guarantee:\n'
          '• Uninterrupted or error-free service.\n'
          '• That all content is accurate or theologically sound.\n'
          '• That the platform will meet every user\'s specific requirements.\n\n'
          'All creator content represents the views of individual creators, not OFG Connects.',
        ),

        const _SectionTitle('10. Limitation of Liability'),
        const _Body(
          'To the maximum extent permitted by law, OFG Connects and its team shall not be liable for:\n'
          '• Indirect, incidental, or consequential damages arising from your use of the platform.\n'
          '• Any financial loss resulting from donation transactions.\n'
          '• Content posted by other users.\n\n'
          'Our total liability shall not exceed the amount you paid to us in the 12 months prior to the claim.',
        ),

        const _SectionTitle('11. Termination'),
        const _Body(
          'We may suspend or terminate your account without prior notice if you:\n'
          '• Violate these Terms.\n'
          '• Engage in fraudulent activity.\n'
          '• Cause harm to other users or the platform.\n\n'
          'You may terminate your account at any time by going to Settings → Account → Delete Account.',
        ),

        const _SectionTitle('12. Governing Law'),
        const _Body(
          'These Terms are governed by the laws of India. Any disputes arising under these Terms shall be resolved through the courts of jurisdiction in India, or through binding arbitration as mutually agreed.',
        ),

        const _SectionTitle('13. Changes to Terms'),
        const _Body(
          'We may update these Terms from time to time. We will notify you via in-app notification when significant changes are made. Continued use of the app after the effective date constitutes acceptance of the updated Terms.',
        ),

        const _SectionTitle('14. Contact'),
        const _Body(
          'Questions about these Terms?\n\n'
          '📧 Email: ofgtechhub@gmail.com\n'
          '🌐 Website: www.ofgconnects.com\n\n'
          '"Let your yes be yes and your no be no." — Matthew 5:37',
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ---- Shared style widgets (mirrors privacy_policy_page.dart) ----
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
