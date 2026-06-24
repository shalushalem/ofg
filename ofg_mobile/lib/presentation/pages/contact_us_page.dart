import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ofg_theme.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedType = 'General Inquiry';
  bool _submitted = false;

  static const _types = [
    'General Inquiry',
    'Technical Support',
    'Report a Bug',
    'Creator Support',
    'Donation / Payment Issue',
    'Account Issue',
    'Content Report',
    'Partnership / Ministry',
    'Prayer Request',
    'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // In production: send to your support email API or Freshdesk/Zendesk
    setState(() => _submitted = true);
  }

  void _copyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _submitted ? _SuccessView() : _FormView(
          formKey: _formKey,
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
          subjectCtrl: _subjectCtrl,
          messageCtrl: _messageCtrl,
          selectedType: _selectedType,
          types: _types,
          onTypeChanged: (v) => setState(() => _selectedType = v ?? _selectedType),
          onSubmit: _submit,
          onCopyEmail: _copyEmail,
        ),
      ),
    );
  }
}

// ---- Success view ----
class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Message Sent!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for reaching out. Our team will respond within 1–2 business days.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '"Cast all your anxiety on Him because He cares for you." — 1 Peter 5:7',
              style: TextStyle(color: kMuted, fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back to Settings', style: TextStyle(color: kAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Form view ----
class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController subjectCtrl;
  final TextEditingController messageCtrl;
  final String selectedType;
  final List<String> types;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onSubmit;
  final void Function(String) onCopyEmail;

  const _FormView({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.subjectCtrl,
    required this.messageCtrl,
    required this.selectedType,
    required this.types,
    required this.onTypeChanged,
    required this.onSubmit,
    required this.onCopyEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kAccent.withValues(alpha: 0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.support_agent, color: kAccent, size: 28),
                SizedBox(width: 10),
                Text('We\'re Here to Help', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              SizedBox(height: 8),
              Text(
                'Have a question, need support, or want to partner with us? Fill in the form below — our team will get back to you within 1–2 business days.',
                style: TextStyle(color: kMuted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Quick contact cards
        const Text('Direct Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ContactCard(
              icon: Icons.email_outlined,
              title: 'Email',
              value: 'ofgtechhub@gmail.com',
              color: Colors.blueAccent,
              onTap: () => onCopyEmail('ofgtechhub@gmail.com'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _ContactCard(
              icon: Icons.shield_outlined,
              title: 'Legal',
              value: 'ofgtechhub@gmail.com',
              color: Colors.purpleAccent,
              onTap: () => onCopyEmail('ofgtechhub@gmail.com'),
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ContactCard(
              icon: Icons.lock_outlined,
              title: 'Privacy',
              value: 'ofgtechhub@gmail.com',
              color: Colors.greenAccent,
              onTap: () => onCopyEmail('ofgtechhub@gmail.com'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _ContactCard(
              icon: Icons.handshake_outlined,
              title: 'Partnerships',
              value: 'ofgtechhub@gmail.com',
              color: Colors.orangeAccent,
              onTap: () => onCopyEmail('ofgtechhub@gmail.com'),
            )),
          ],
        ),

        const SizedBox(height: 28),
        const Text('Send a Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 14),

        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              _Field(
                controller: nameCtrl,
                label: 'Your Name',
                hint: 'Pastor John / Sister Mary',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),

              // Email
              _Field(
                controller: emailCtrl,
                label: 'Email Address',
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Type dropdown
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Type of Request', Icons.category_outlined),
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: onTypeChanged,
              ),
              const SizedBox(height: 14),

              // Subject
              _Field(
                controller: subjectCtrl,
                label: 'Subject',
                hint: 'Briefly describe your request',
                icon: Icons.subject,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: 14),

              // Message
              TextFormField(
                controller: messageCtrl,
                maxLines: 5,
                maxLength: 1000,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Message', Icons.message_outlined).copyWith(
                  alignLabelWithHint: true,
                  counterStyle: const TextStyle(color: kMuted),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Message is required';
                  if (v.trim().length < 20) return 'Please provide more detail (at least 20 characters)';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  label: const Text(
                    'Send Message',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We respond to all messages. We typically reply within 1–2 business days (Mon–Sat).',
                style: TextStyle(color: kMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kMuted),
      prefixIcon: Icon(icon, color: kMuted, size: 20),
      filled: true,
      fillColor: kPanel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAccent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: kMuted),
        hintStyle: const TextStyle(color: kMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: kMuted, size: 20),
        filled: true,
        fillColor: kPanel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kAccent)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
      validator: validator,
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('Tap to copy', style: TextStyle(fontSize: 10, color: kMuted.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}
