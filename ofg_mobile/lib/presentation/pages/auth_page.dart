import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../../api/api_client.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';

enum AuthStep { login, signup }

class AuthPage extends ConsumerStatefulWidget {
  final VoidCallback onAuthSuccess;
  const AuthPage({super.key, required this.onAuthSuccess});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  AuthStep _step = AuthStep.login;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  DateTime? _dob;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: kAccent),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 13, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kAccent,
              onPrimary: Colors.white,
              surface: kPanel,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final age = now.difference(picked).inDays / 365.25;
      if (age < 13) {
        _showError('You must be at least 13 years old to use this app.');
        setState(() => _dob = null);
      } else {
        setState(() => _dob = picked);
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_step == AuthStep.signup) {
      if (name.isEmpty) {
        _showError('Please enter your name');
        return;
      }
      if (_dob == null) {
        _showError('Please select your Date of Birth');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiClientProvider);
      final response = _step == AuthStep.login
          ? await api.post('/auth/login', {'email': email, 'password': password})
          : await api.post('/auth/register', {
              'name': name,
              'email': email,
              'password': password,
              'dob': '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
            });

      final token = response['token'] as String;
      final userMap = response['user'] as Map<String, dynamic>;
      final user = OfgUser.fromJson(userMap);

      await OfgStorage.saveToken(token);
      await OfgStorage.saveUser(user);

      api.token = token;
      ref.read(authStateProvider.notifier).state = user;

      widget.onAuthSuccess();
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Authentication failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _step == AuthStep.login;

    return WillPopScope(
      onWillPop: () async {
        if (!isLogin) {
          setState(() {
            _step = AuthStep.login;
            _emailController.clear();
            _passwordController.clear();
            _nameController.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isLogin)
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _step = AuthStep.login;
                        _emailController.clear();
                        _passwordController.clear();
                        _nameController.clear();
                      });
                    },
                  ),
                )
              else
                const SizedBox(height: 48),
              const Center(child: OfgLogo(size: 42)),
              const SizedBox(height: 60),
              Text(
                isLogin ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Sign in to access your feed and library.'
                    : 'Join the community and start connecting.',
                style: const TextStyle(color: kMuted, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!isLogin) ...[
                OfgInput(
                  controller: _nameController,
                  label: 'Full Name',
                  keyboard: TextInputType.name,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDob,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: kPanel2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dob == null
                              ? 'Date of Birth'
                              : '${_dob!.month}/${_dob!.day}/${_dob!.year}',
                          style: TextStyle(
                            color: _dob == null ? kMuted : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: kMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              OfgInput(
                controller: _emailController,
                label: 'Email',
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              OfgInput(
                controller: _passwordController,
                label: 'Password',
                obscure: true,
              ),
              const SizedBox(height: 32),
              OfgPrimaryButton(
                label: isLogin ? 'Sign In' : 'Create Account',
                onTap: _submit,
                loading: _isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLogin ? 'New here? ' : 'Already have an account? ',
                    style: const TextStyle(color: kMuted),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _step = isLogin ? AuthStep.signup : AuthStep.login;
                        _emailController.clear();
                        _passwordController.clear();
                        _nameController.clear();
                      });
                    },
                    child: Text(
                      isLogin ? 'Create account' : 'Sign in',
                      style: const TextStyle(
                        color: kAccentSoft,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}