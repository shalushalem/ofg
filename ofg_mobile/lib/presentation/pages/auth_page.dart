// lib/presentation/pages/auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../models/ofg_models.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';

enum AuthStep { login, signup, otp }

class AuthPage extends ConsumerStatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthPage({super.key, required this.onAuthSuccess});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  AuthStep _step = AuthStep.login;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingOtpToken;

  final _emailCtrl = TextEditingController(text: 'demo@ofg.local');
  final _passwordCtrl = TextEditingController(text: 'password123');
  final _nameCtrl = TextEditingController(text: 'Aria Kade');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    await _runAuthAction(() async {
      final api = ref.read(apiClientProvider);
      final payload = await api.post('/auth/login', {
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });
      
      api.token = payload['token'].toString();
      final user = OfgUser.fromJson(Map<String, dynamic>.from(payload['user']));
      
      ref.read(authStateProvider.notifier).state = user;
      widget.onAuthSuccess();
    });
  }

  Future<void> _signup() async {
    await _runAuthAction(() async {
      final api = ref.read(apiClientProvider);
      final payload = await api.post('/auth/register', {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });
      
      _pendingOtpToken = payload['token'].toString();
      final user = OfgUser.fromJson(Map<String, dynamic>.from(payload['user']));
      
      ref.read(authStateProvider.notifier).state = user;
      setState(() => _step = AuthStep.otp);
    });
  }

  Future<void> _verifyOtp() async {
    final api = ref.read(apiClientProvider);
    api.token = _pendingOtpToken;
    widget.onAuthSuccess();
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold is now securely wrapped around the page!
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(34, 48, 34, 40),
              children: [
                if (_step != AuthStep.login) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OfgBackButton(onTap: () => setState(() => _step = AuthStep.login)),
                  ),
                  const SizedBox(height: 22),
                ] else ...[
                  const OfgLogo(size: 38, connects: true),
                  const SizedBox(height: 30),
                ],
                
                if (_step == AuthStep.login) _buildLogin(),
                if (_step == AuthStep.signup) _buildSignup(),
                if (_step == AuthStep.otp) _buildOtp(),
              ],
            ),
            
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: kAccent)),
              ),
              
            if (_errorMessage != null)
              Positioned(
                left: 18, right: 18, top: 12,
                child: _buildErrorToast(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorToast() {
    return GestureDetector(
      onTap: () => setState(() => _errorMessage = null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: ofgPanelDecoration(radius: 14),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: kAccentSoft),
            const SizedBox(width: 10),
            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, height: 1.3))),
            IconButton(
              onPressed: () => setState(() => _errorMessage = null),
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome back', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Sign in to continue streaming.', style: TextStyle(color: kMuted, fontSize: 15)),
        const SizedBox(height: 30),
        OfgInput(controller: _emailCtrl, label: 'EMAIL', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        OfgInput(controller: _passwordCtrl, label: 'PASSWORD', obscure: true),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _errorMessage = 'Password reset is local-only for now.'),
            child: const Text('Forgot password?', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 14),
        OfgPrimaryButton(label: 'Sign In', onTap: _login),
        const SizedBox(height: 28),
        _switchAuth('New here?', 'Create account', () => setState(() => _step = AuthStep.signup)),
      ],
    );
  }

  Widget _buildSignup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create account', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Join OFG Connects in seconds.', style: TextStyle(color: kMuted, fontSize: 15)),
        const SizedBox(height: 30),
        OfgInput(controller: _nameCtrl, label: 'FULL NAME'),
        const SizedBox(height: 14),
        OfgInput(controller: _emailCtrl, label: 'EMAIL', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        OfgInput(controller: _passwordCtrl, label: 'PASSWORD', obscure: true),
        const SizedBox(height: 22),
        OfgPrimaryButton(label: 'Create Account', onTap: _signup),
      ],
    );
  }

  Widget _buildOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Verify it's you", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Enter the 6-digit code sent to ${_emailCtrl.text}.', style: const TextStyle(color: kMuted, fontSize: 15, height: 1.5)),
        const SizedBox(height: 38),
        Row(
          children: List.generate(6, (i) {
            final values = ['4', '9', '2', '', '', ''];
            return Expanded(
              child: Container(
                height: 50, margin: EdgeInsets.only(right: i == 5 ? 0 : 10),
                decoration: BoxDecoration(
                  color: kPanel,
                  border: Border.all(color: i == 3 ? kAccent : kBorder, width: 1.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(values[i], style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
              ),
            );
          }),
        ),
        const SizedBox(height: 34),
        OfgPrimaryButton(label: 'Verify', onTap: _verifyOtp),
      ],
    );
  }

  Widget _switchAuth(String left, String action, VoidCallback onTap) {
    return Center(
      child: Wrap(
        children: [
          Text(left, style: const TextStyle(color: kMuted)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onTap,
            child: Text(action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}