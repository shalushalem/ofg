import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kBg = Color(0xFF000000);
const Color kPanel = Color(0xFF101010);
const Color kPanel2 = Color(0xFF161616);
const Color kBorder = Color(0xFF242424);
const Color kMuted = Color(0xFF7C7C7C);
const Color kMuted2 = Color(0xFF4E4E4E);
const Color kAccent = Color(0xFFFF4438);
const Color kAccentSoft = Color(0xFFFF6B61);
const String kDefaultApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8787',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const OfgApp());
}

class OfgApp extends StatelessWidget {
  const OfgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OFG Connects',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          secondary: Colors.white,
          surface: kPanel,
          outline: kBorder,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          fontFamily: 'Roboto',
        ),
      ),
      home: const OfgExperience(),
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl});

  String baseUrl;
  String? token;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');
    final request = await _client.openUrl(method, uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      request.add(utf8.encode(jsonEncode(body)));
    }
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    final decoded = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] != null
          ? decoded['error'].toString()
          : 'Server error ${response.statusCode}';
      throw ApiException(message);
    }
    return decoded;
  }
}

class OfgUser {
  OfgUser({
    required this.id,
    required this.name,
    required this.email,
    required this.handle,
    this.bio = '',
    this.subscription = 'Free',
  });

  final String id;
  final String name;
  final String email;
  final String handle;
  final String bio;
  final String subscription;

  factory OfgUser.fromJson(Map<String, dynamic> json) {
    return OfgUser(
      id: json['id'].toString(),
      name: (json['name'] ?? 'OFG User').toString(),
      email: (json['email'] ?? '').toString(),
      handle: (json['handle'] ?? '@ofguser').toString(),
      bio: (json['bio'] ?? '').toString(),
      subscription: (json['subscription'] ?? 'Free').toString(),
    );
  }
}

class OfgVideo {
  OfgVideo({
    required this.id,
    required this.title,
    required this.creator,
    required this.creatorId,
    required this.category,
    required this.duration,
    required this.meta,
    required this.description,
    required this.label,
    required this.views,
    required this.likes,
    required this.comments,
    required this.isShort,
    required this.isLive,
    required this.progress,
    required this.liked,
    required this.saved,
    required this.following,
  });

  final String id;
  final String title;
  final String creator;
  final String creatorId;
  final String category;
  final String duration;
  final String meta;
  final String description;
  final String label;
  final int views;
  final int likes;
  final int comments;
  final bool isShort;
  final bool isLive;
  final double progress;
  final bool liked;
  final bool saved;
  final bool following;

  OfgVideo copyWith({
    int? views,
    int? likes,
    int? comments,
    bool? liked,
    bool? saved,
    bool? following,
    double? progress,
  }) {
    return OfgVideo(
      id: id,
      title: title,
      creator: creator,
      creatorId: creatorId,
      category: category,
      duration: duration,
      meta: meta,
      description: description,
      label: label,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isShort: isShort,
      isLive: isLive,
      progress: progress ?? this.progress,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      following: following ?? this.following,
    );
  }

  factory OfgVideo.fromJson(Map<String, dynamic> json) {
    return OfgVideo(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      creator: (json['creator'] ?? '').toString(),
      creatorId: (json['creatorId'] ?? '').toString(),
      category: (json['category'] ?? 'sermons').toString(),
      duration: (json['duration'] ?? '12:04').toString(),
      meta: (json['meta'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      label: (json['label'] ?? 'video 16:9').toString(),
      views: _asInt(json['views']),
      likes: _asInt(json['likes']),
      comments: _asInt(json['comments']),
      isShort: json['isShort'] == true,
      isLive: json['isLive'] == true,
      progress: _asDouble(json['progress']),
      liked: json['liked'] == true,
      saved: json['saved'] == true,
      following: json['following'] == true,
    );
  }
}

class OfgComment {
  OfgComment({
    required this.id,
    required this.user,
    required this.content,
    required this.when,
  });

  final String id;
  final String user;
  final String content;
  final String when;

  factory OfgComment.fromJson(Map<String, dynamic> json) {
    return OfgComment(
      id: json['id'].toString(),
      user: (json['user'] ?? 'OFG User').toString(),
      content: (json['content'] ?? '').toString(),
      when: (json['when'] ?? 'now').toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

enum AppScreen {
  splash,
  onboarding,
  login,
  signup,
  otp,
  home,
  shorts,
  search,
  video,
  upload,
  library,
  profile,
  settings,
  premium,
  creator,
}

class OfgExperience extends StatefulWidget {
  const OfgExperience({super.key});

  @override
  State<OfgExperience> createState() => _OfgExperienceState();
}

class _OfgExperienceState extends State<OfgExperience> {
  late final ApiClient _api;
  late final TextEditingController _serverController;
  final TextEditingController _loginEmail = TextEditingController(
    text: 'demo@ofg.local',
  );
  final TextEditingController _loginPassword = TextEditingController(
    text: 'password123',
  );
  final TextEditingController _signupName = TextEditingController(
    text: 'Aria Kade',
  );
  final TextEditingController _signupEmail = TextEditingController(
    text: 'aria@ofg.local',
  );
  final TextEditingController _signupPassword = TextEditingController(
    text: 'password123',
  );
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _uploadTitle = TextEditingController();
  final TextEditingController _uploadDescription = TextEditingController();

  AppScreen _screen = AppScreen.splash;
  AppScreen _tab = AppScreen.home;
  OfgUser? _user;
  String? _pendingOtpToken;
  int _onboardingIndex = 0;
  int _shortIndex = 0;
  String _category = 'For You';
  String _selectedPlan = 'yearly';
  String _uploadCategory = 'sermons';
  bool _playerOpen = false;
  bool _createOpen = false;
  bool _busy = false;
  bool _serverOk = false;
  String? _message;
  Timer? _splashTimer;
  OfgVideo? _activeVideo;
  List<OfgVideo> _videos = [];
  List<OfgVideo> _shorts = [];
  List<OfgVideo> _history = [];
  List<OfgVideo> _saved = [];
  List<OfgVideo> _searchResults = [];
  List<OfgComment> _comments = [];
  Map<String, bool> _settings = {
    'autoplay': true,
    'wifi': true,
    'push': true,
    'dark': true,
    'private': false,
  };

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: kDefaultApiBase);
    _serverController = TextEditingController(text: kDefaultApiBase);
    _warmServer();
    _splashTimer = Timer(const Duration(milliseconds: 1550), () {
      if (mounted && _screen == AppScreen.splash) {
        setState(() => _screen = AppScreen.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _serverController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPassword.dispose();
    _searchController.dispose();
    _commentController.dispose();
    _uploadTitle.dispose();
    _uploadDescription.dispose();
    super.dispose();
  }

  Future<void> _warmServer() async {
    try {
      await _api.get('/health');
      final payload = await _api.get('/videos');
      final shorts = await _api.get('/shorts');
      setState(() {
        _serverOk = true;
        _videos = _readVideos(payload);
        _shorts = _readVideos(shorts);
      });
    } catch (e) {
      setState(() {
        _serverOk = false;
        _message =
            'Start backend/server.py, then set the server URL if needed.';
      });
    }
  }

  List<OfgVideo> _readVideos(dynamic payload) {
    final list = payload is Map ? payload['items'] : payload;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _login() async {
    await _run(() async {
      final payload = await _api.post('/auth/login', {
        'email': _loginEmail.text.trim(),
        'password': _loginPassword.text,
      });
      _api.token = payload['token'].toString();
      _user = OfgUser.fromJson(Map<String, dynamic>.from(payload['user']));
      await _reloadAll();
      _goTab(AppScreen.home);
    });
  }

  Future<void> _signup() async {
    await _run(() async {
      final payload = await _api.post('/auth/register', {
        'name': _signupName.text.trim(),
        'email': _signupEmail.text.trim(),
        'password': _signupPassword.text,
      });
      _pendingOtpToken = payload['token'].toString();
      _user = OfgUser.fromJson(Map<String, dynamic>.from(payload['user']));
      _screen = AppScreen.otp;
    });
  }

  Future<void> _verifyOtp() async {
    _api.token = _pendingOtpToken;
    await _reloadAll();
    _goTab(AppScreen.home);
  }

  Future<void> _reloadAll() async {
    final videos = await _api.get('/videos');
    final shorts = await _api.get('/shorts');
    final library = _api.token == null ? null : await _api.get('/library');
    final settings = _api.token == null ? null : await _api.get('/settings');
    setState(() {
      _serverOk = true;
      _videos = _readVideos(videos);
      _shorts = _readVideos(shorts);
      if (library is Map) {
        _history = _readVideos(library['history']);
        _saved = _readVideos(library['saved']);
      }
      if (settings is Map) {
        _settings = {
          ..._settings,
          ...settings.map((k, v) => MapEntry(k.toString(), v == true)),
        };
      }
    });
  }

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await body();
    } catch (e) {
      setState(() {
        _message = e is ApiException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(AppScreen screen) {
    setState(() {
      _createOpen = false;
      _playerOpen = false;
      _screen = screen;
    });
  }

  void _goTab(AppScreen tab) {
    setState(() {
      _tab = tab;
      _screen = tab;
      _createOpen = false;
      _playerOpen = false;
    });
    if (tab == AppScreen.library) {
      _reloadLibrary();
    }
  }

  Future<void> _reloadLibrary() async {
    if (_api.token == null) return;
    try {
      final library = await _api.get('/library');
      setState(() {
        _history = _readVideos(library['history']);
        _saved = _readVideos(library['saved']);
      });
    } catch (_) {}
  }

  Future<void> _openVideo(OfgVideo video) async {
    setState(() {
      _activeVideo = video;
      _screen = AppScreen.video;
      _playerOpen = false;
    });
    try {
      if (_api.token != null) {
        await _api.post('/videos/${video.id}/view', {'progress': 0.35});
      }
      final payload = await _api.get('/videos/${video.id}');
      final comments = await _api.get('/comments?videoId=${video.id}');
      setState(() {
        _activeVideo = OfgVideo.fromJson(
          Map<String, dynamic>.from(payload['item'] as Map),
        );
        _comments = (comments['items'] as List)
            .whereType<Map>()
            .map((e) => OfgComment.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _toggleVideoAction(String action, OfgVideo video) async {
    if (_api.token == null) {
      setState(() => _message = 'Please sign in first.');
      return;
    }
    await _run(() async {
      final payload = await _api.post('/videos/${video.id}/$action', {});
      final next = OfgVideo.fromJson(
        Map<String, dynamic>.from(payload['item'] as Map),
      );
      _replaceVideo(next);
      if (_activeVideo?.id == next.id) _activeVideo = next;
    });
  }

  Future<void> _postComment() async {
    if (_api.token == null || _activeVideo == null) return;
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    await _run(() async {
      await _api.post('/comments', {
        'videoId': _activeVideo!.id,
        'content': text,
      });
      _commentController.clear();
      await _openVideo(_activeVideo!);
    });
  }

  Future<void> _search(String query) async {
    final q = Uri.encodeQueryComponent(query.trim());
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final payload = await _api.get('/search?q=$q');
      setState(() => _searchResults = _readVideos(payload));
    } catch (e) {
      setState(() => _message = 'Search failed: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_api.token == null) return;
    try {
      await _api.post('/settings', _settings);
    } catch (_) {}
  }

  Future<void> _createUpload() async {
    if (_api.token == null) {
      setState(() => _message = 'Please sign in before uploading.');
      return;
    }
    final title = _uploadTitle.text.trim();
    if (title.isEmpty) {
      setState(() => _message = 'Add a title for the upload.');
      return;
    }
    await _run(() async {
      await _api.post('/upload', {
        'title': title,
        'description': _uploadDescription.text.trim(),
        'category': _uploadCategory,
      });
      _uploadTitle.clear();
      _uploadDescription.clear();
      await _reloadAll();
      _goTab(AppScreen.home);
      _message = 'Upload saved to the local backend.';
    });
  }

  void _replaceVideo(OfgVideo next) {
    List<OfgVideo> replace(List<OfgVideo> items) =>
        items.map((v) => v.id == next.id ? next : v).toList();
    _videos = replace(_videos);
    _shorts = replace(_shorts);
    _history = replace(_history);
    _saved = replace(_saved);
    _searchResults = replace(_searchResults);
  }

  void _applyServerUrl() {
    setState(() {
      _api.baseUrl = _serverController.text.trim();
      _api.token = null;
      _user = null;
      _message = 'Server changed. Sign in again.';
    });
    _warmServer();
  }

  @override
  Widget build(BuildContext context) {
    final current = _buildCurrentScreen();
    final showNav = {
      AppScreen.home,
      AppScreen.shorts,
      AppScreen.search,
      AppScreen.library,
      AppScreen.profile,
    }.contains(_screen);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kBg,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: KeyedSubtree(key: ValueKey(_screen), child: current),
          ),
          if (showNav) _bottomNav(),
          if (_createOpen) _createSheet(),
          if (_playerOpen && _activeVideo != null)
            _playerOverlay(_activeVideo!),
          if (_busy) _busyOverlay(),
          if (_message != null) _toast(),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_screen) {
      case AppScreen.splash:
        return _splash();
      case AppScreen.onboarding:
        return _onboarding();
      case AppScreen.login:
        return _loginScreen();
      case AppScreen.signup:
        return _signupScreen();
      case AppScreen.otp:
        return _otpScreen();
      case AppScreen.home:
        return _homeScreen();
      case AppScreen.shorts:
        return _shortsScreen();
      case AppScreen.search:
        return _searchScreen();
      case AppScreen.video:
        return _videoScreen();
      case AppScreen.upload:
        return _uploadScreen();
      case AppScreen.library:
        return _libraryScreen();
      case AppScreen.profile:
        return _profileScreen();
      case AppScreen.settings:
        return _settingsScreen();
      case AppScreen.premium:
        return _premiumScreen();
      case AppScreen.creator:
        return _creatorScreen();
    }
  }

  Widget _splash() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.25),
          radius: 1.0,
          colors: [Color(0xFF1B1B1D), Colors.black],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logo(size: 46, connects: false),
              const SizedBox(height: 10),
              const Text(
                'CONNECTS',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: 128,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    color: Colors.white,
                    backgroundColor: kPanel2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _serverOk ? 'LOCAL SERVER READY' : 'LOCAL SERVER WAITING',
                style: const TextStyle(
                  color: kMuted2,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _onboarding() {
    final slides = [
      (
        'Faith, anytime',
        'Sermons, worship, Bible studies and live services - all in one place.',
        'illustration - worship',
      ),
      (
        'A daily word',
        'Short, uplifting videos and verses to encourage you every day.',
        'illustration - shorts',
      ),
      (
        'Share your testimony',
        'Upload messages, go live, and grow your ministry with OFG Connects.',
        'illustration - create',
      ),
    ];
    final slide = slides[_onboardingIndex];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 34, 34, 38),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StripedMedia(
                      label: slide.$3,
                      radius: 26,
                      child: Icon(
                        _onboardingIndex == 0
                            ? Icons.play_circle_outline
                            : _onboardingIndex == 1
                            ? Icons.phone_iphone
                            : Icons.cloud_upload_outlined,
                        color: Colors.white30,
                        size: 58,
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  Text(
                    slide.$1,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.$2,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == _onboardingIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: active ? 22 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            _primaryButton(_onboardingIndex < 2 ? 'Next' : 'Get Started', () {
              if (_onboardingIndex < 2) {
                setState(() => _onboardingIndex++);
              } else {
                _go(AppScreen.login);
              }
            }),
            TextButton(
              onPressed: () => _go(AppScreen.login),
              child: const Text(
                'Skip',
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginScreen() {
    return _authScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue streaming.',
      children: [
        _input(_loginEmail, 'EMAIL', keyboard: TextInputType.emailAddress),
        _input(_loginPassword, 'PASSWORD', obscure: true),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              setState(
                () => _message = 'Password reset is local-only for now.',
              );
            },
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: kMuted, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _primaryButton('Sign In', _login),
        _dividerText('or continue with'),
        Row(
          children: [
            Expanded(child: _outlineButton('Google', () {})),
            const SizedBox(width: 12),
            Expanded(child: _outlineButton('Apple', () {})),
          ],
        ),
        const SizedBox(height: 28),
        _switchAuth('New here?', 'Create account', () => _go(AppScreen.signup)),
      ],
    );
  }

  Widget _signupScreen() {
    return _authScaffold(
      title: 'Create account',
      subtitle: 'Join OFG Connects in seconds.',
      back: () => _go(AppScreen.login),
      children: [
        _input(_signupName, 'FULL NAME'),
        _input(_signupEmail, 'EMAIL', keyboard: TextInputType.emailAddress),
        _input(_signupPassword, 'PASSWORD', obscure: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.check_box, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'I agree to the local Terms of Service and Privacy Policy.',
                style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _primaryButton('Create Account', _signup),
        const SizedBox(height: 18),
        _switchAuth('Have an account?', 'Sign in', () => _go(AppScreen.login)),
      ],
    );
  }

  Widget _otpScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 28, 34, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _backButton(() => _go(AppScreen.signup)),
            const SizedBox(height: 22),
            const Text(
              "Verify it's you",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${_user?.email ?? _signupEmail.text}.',
              style: const TextStyle(color: kMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 38),
            Row(
              children: List.generate(6, (i) {
                final values = ['4', '9', '2', '', '', ''];
                return Expanded(
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.only(right: i == 5 ? 0 : 10),
                    decoration: BoxDecoration(
                      color: kPanel,
                      border: Border.all(
                        color: i == 3 ? kAccent : kBorder,
                        width: 1.4,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      values[i],
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 34),
            _primaryButton('Verify', _verifyOtp),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                "Didn't get it? Resend in 0:24",
                style: TextStyle(color: kMuted, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeScreen() {
    final feed = _filteredVideos();
    final live = _videos.where((v) => v.isLive).toList();
    final music = _videos.where((v) => v.category == 'music').toList();
    final continueWatching = _videos.where((v) => v.progress > 0).toList();
    final hero = feed.isNotEmpty ? feed.first : _fallbackVideo();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: kAccent,
        backgroundColor: kPanel,
        onRefresh: _reloadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _homeHeader()),
            SliverToBoxAdapter(child: _categoryChips()),
            SliverToBoxAdapter(child: _heroCard(hero)),
            SliverToBoxAdapter(
              child: _horizontalSection(
                'Continue Watching',
                continueWatching.isEmpty
                    ? feed.take(4).toList()
                    : continueWatching,
                wide: true,
              ),
            ),
            SliverToBoxAdapter(
              child: _horizontalSection('Worship Music', music, square: true),
            ),
            SliverToBoxAdapter(child: _liveSection(live)),
            SliverToBoxAdapter(child: _creatorsSection()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Latest',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: feed.length,
              itemBuilder: (context, index) => _feedCard(feed[index]),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
    );
  }

  List<OfgVideo> _filteredVideos() {
    if (_category == 'For You') {
      return _videos.where((v) => !v.isShort).toList();
    }
    final key = _category.toLowerCase();
    return _videos
        .where(
          (v) =>
              !v.isShort &&
              (v.category == key || v.title.toLowerCase().contains(key)),
        )
        .toList();
  }

  Widget _homeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          _logo(size: 21, connects: false),
          const Spacer(),
          _serverPill(),
          IconButton(
            tooltip: 'Search',
            onPressed: () => _go(AppScreen.search),
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => _message = 'No new notifications.'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: const [
                Icon(Icons.notifications_none, color: Colors.white),
                Positioned(
                  right: 1,
                  top: 1,
                  child: CircleAvatar(radius: 4, backgroundColor: kAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serverPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: _serverOk ? const Color(0xFF102216) : const Color(0xFF241111),
        border: Border.all(
          color: _serverOk ? const Color(0xFF285E37) : const Color(0xFF4A2525),
        ),
      ),
      child: Text(
        _serverOk ? 'LOCAL' : 'OFFLINE',
        style: TextStyle(
          color: _serverOk ? const Color(0xFF7DDB92) : kAccentSoft,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _categoryChips() {
    final cats = ['For You', 'Worship', 'Sermons', 'Music', 'Kids', 'Live'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = cats[index];
          final active = label == _category;
          return ChoiceChip(
            label: Text(label),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => setState(() => _category = label),
            selectedColor: Colors.white,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: active ? Colors.white : kBorder),
            labelStyle: TextStyle(
              color: active ? Colors.black : kMuted,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          );
        },
      ),
    );
  }

  Widget _heroCard(OfgVideo video) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: GestureDetector(
        onTap: () => _openVideo(video),
        child: SizedBox(
          height: 206,
          child: StripedMedia(
            label: video.label,
            radius: 20,
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.16),
                      border: Border.all(color: kAccent.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      video.isLive ? 'LIVE NOW' : 'This Sunday',
                      style: const TextStyle(
                        color: kAccentSoft,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${video.creator} - ${_formatViews(video.views)} views',
                    style: const TextStyle(color: Color(0xFF9A9A9A)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _miniButton(
                          Icons.play_arrow,
                          'Watch',
                          Colors.white,
                          Colors.black,
                          () => _openVideo(video),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _squareIconButton(
                        video.saved ? Icons.bookmark : Icons.add,
                        () => _toggleVideoAction('save', video),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _horizontalSection(
    String title,
    List<OfgVideo> items, {
    bool wide = false,
    bool square = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          _sectionHeading(title),
          SizedBox(
            height: square ? 204 : 186,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 13),
              itemBuilder: (context, index) {
                final video = items[index];
                final width = wide ? 230.0 : 144.0;
                return GestureDetector(
                  onTap: () => _openVideo(video),
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: square ? 144 : 130,
                          child: StripedMedia(
                            label: square ? 'album art' : video.label,
                            radius: 14,
                            child: Stack(
                              children: [
                                Center(
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white30),
                                    ),
                                    child: const Icon(Icons.play_arrow),
                                  ),
                                ),
                                if (!square)
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: _duration(video.duration),
                                  ),
                                if (video.progress > 0)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: LinearProgressIndicator(
                                      value: video.progress,
                                      minHeight: 3,
                                      color: kAccent,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFEEEEEE),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          square
                              ? '${video.creator} - ${video.duration}'
                              : '${video.creator} - ${_formatViews(video.views)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveSection(List<OfgVideo> live) {
    if (live.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 13),
            child: Row(
              children: const [
                CircleAvatar(radius: 4, backgroundColor: kAccent),
                SizedBox(width: 8),
                Text(
                  'Live Services',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 198,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: live.length,
              separatorBuilder: (context, index) => const SizedBox(width: 13),
              itemBuilder: (context, index) {
                final video = live[index];
                return GestureDetector(
                  onTap: () => _openVideo(video),
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 142,
                          child: StripedMedia(
                            label: 'service live',
                            radius: 14,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 9,
                                  top: 9,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 9,
                                  bottom: 9,
                                  child: _duration(
                                    '${_formatViews(video.views)} watching',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          video.creator,
                          style: const TextStyle(color: kMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _creatorsSection() {
    final names = _videos.map((v) => v.creator).toSet().take(8).toList();
    if (names.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 13),
            child: Text(
              'Ministries You Follow',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            height: 104,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: names.length,
              separatorBuilder: (context, index) => const SizedBox(width: 18),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        backgroundColor: kPanel2,
                        child: Icon(
                          Icons.church_outlined,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        names[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedCard(OfgVideo video) {
    return GestureDetector(
      onTap: () => _openVideo(video),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 212,
              child: StripedMedia(
                label: video.label,
                radius: 0,
                child: Stack(
                  children: [
                    Positioned(
                      right: 14,
                      bottom: 10,
                      child: _duration(video.duration),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: kPanel2,
                    child: Icon(Icons.person, color: Colors.white54),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF0F0F0),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${video.creator} - ${_formatViews(video.views)} views',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleVideoAction('save', video),
                    icon: Icon(
                      video.saved ? Icons.bookmark : Icons.more_horiz,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shortsScreen() {
    final items = _shorts.isEmpty ? [_fallbackShort()] : _shorts;
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: PageController(initialPage: _shortIndex),
      onPageChanged: (index) => setState(() => _shortIndex = index),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final short = items[index];
        return Stack(
          children: [
            Positioned.fill(
              child: StripedMedia(
                label: 'short 9:16',
                radius: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x88000000),
                        Colors.transparent,
                        Color(0xEE000000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Following',
                        style: TextStyle(color: Colors.white54),
                      ),
                      SizedBox(width: 22),
                      Text(
                        'For You',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 22),
                      Text('Trending', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 120,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: kPanel2,
                      child: Icon(Icons.person, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _railAction(
                    short.liked ? Icons.favorite : Icons.favorite_border,
                    _formatViews(short.likes),
                    short.liked ? kAccent : Colors.white,
                    () => _toggleVideoAction('like', short),
                  ),
                  _railAction(
                    Icons.mode_comment_outlined,
                    _formatViews(short.comments),
                    Colors.white,
                    () => _openVideo(short),
                  ),
                  _railAction(
                    Icons.ios_share,
                    'Share',
                    Colors.white,
                    () =>
                        setState(() => _message = 'Share link copied locally.'),
                  ),
                  _railAction(
                    short.saved ? Icons.bookmark : Icons.bookmark_border,
                    'Save',
                    Colors.white,
                    () => _toggleVideoAction('save', short),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 88,
              bottom: 118,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        short.creator,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 9),
                      GestureDetector(
                        onTap: () => _toggleVideoAction('follow', short),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: short.following
                                ? Colors.white12
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Text(
                            short.following ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: short.following
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    short.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.music_note, color: Colors.white70, size: 15),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Worship - Still Waters',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _searchScreen() {
    final recent = [
      'sunday worship',
      'psalm 23',
      'prayer for peace',
      'romans bible study',
    ];
    final trending = [
      'worship songs',
      'daily devotion',
      'sunday service',
      'gospel music',
      'bible study',
      'prayer',
      'testimonies',
      'kids',
    ];
    final results = _searchResults;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _search,
                  onChanged: (value) {
                    if (value.trim().length > 1) _search(value);
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('Search videos, creators...')
                      .copyWith(
                        prefixIcon: const Icon(Icons.search, color: kMuted),
                        suffixIcon: IconButton(
                          onPressed: () => _search(_searchController.text),
                          icon: const Icon(
                            Icons.mic_none,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                ),
              ),
              TextButton(
                onPressed: () => _goTab(AppScreen.home),
                child: const Text('Cancel', style: TextStyle(color: kMuted)),
              ),
            ],
          ),
          if (results.isNotEmpty) ...[
            _smallHeader('RESULTS'),
            ...results.map(_compactVideoRow),
          ] else ...[
            _smallHeader('RECENT'),
            ...recent.map((term) => _searchTermRow(term)),
            _smallHeader('TRENDING SEARCHES'),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: trending
                  .map(
                    (term) => ActionChip(
                      label: Text(term),
                      onPressed: () {
                        _searchController.text = term;
                        _search(term);
                      },
                      backgroundColor: const Color(0xFF141414),
                      side: const BorderSide(color: kBorder),
                      labelStyle: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _videoScreen() {
    final video = _activeVideo ?? _fallbackVideo();
    final related = _videos
        .where((v) => v.id != video.id && !v.isShort)
        .take(4);
    return SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () => setState(() => _playerOpen = true),
            child: SizedBox(
              height: 232,
              child: StripedMedia(
                label: 'player 16:9',
                radius: 0,
                child: Stack(
                  children: [
                    Positioned(
                      top: 54,
                      left: 18,
                      child: _roundBack(() => _goTab(AppScreen.home)),
                    ),
                    Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Icon(Icons.play_arrow, size: 32),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: 0.34,
                        minHeight: 3,
                        color: kAccent,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(
                      '${_formatViews(video.views)} views - 3 days ago',
                      style: const TextStyle(color: kMuted, fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(Icons.star, color: kAccent, size: 15),
                    const SizedBox(width: 4),
                    const Text('4.8', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _actionChip(
                        video.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        _formatViews(video.likes),
                        video.liked,
                        () => _toggleVideoAction('like', video),
                      ),
                      _actionChip(
                        Icons.mode_comment_outlined,
                        _formatViews(video.comments),
                        false,
                        () {},
                      ),
                      _actionChip(
                        Icons.ios_share,
                        'Share',
                        false,
                        () => setState(
                          () => _message = 'Share link copied locally.',
                        ),
                      ),
                      _actionChip(
                        video.saved ? Icons.bookmark : Icons.bookmark_border,
                        video.saved ? 'Saved' : 'Save',
                        video.saved,
                        () => _toggleVideoAction('save', video),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _creatorPanel(video),
                const SizedBox(height: 16),
                _descriptionBox(video.description),
                const SizedBox(height: 22),
                _commentsBox(),
                const SizedBox(height: 26),
                const Text(
                  'Up Next',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                ...related.map(_compactVideoRow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _creatorPanel(OfgVideo video) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(radius: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: kPanel2,
            child: Icon(Icons.person, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.creator,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Text(
                  '1.2M subscribers',
                  style: TextStyle(color: kMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _toggleVideoAction('follow', video),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              decoration: BoxDecoration(
                color: video.following ? Colors.white12 : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                video.following ? 'Subscribed' : 'Subscribe',
                style: TextStyle(
                  color: video.following ? Colors.white : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionBox(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(radius: 14, color: const Color(0xFF0D0D0D)),
      child: Text(
        description.isEmpty
            ? 'A message on grace and walking in faith. Be encouraged.'
            : description,
        style: const TextStyle(color: Color(0xFFAAAAAA), height: 1.55),
      ),
    );
  }

  Widget _commentsBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(radius: 16, color: const Color(0xFF0D0D0D)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (_comments.isEmpty)
            const Text(
              'No comments yet. Start the conversation.',
              style: TextStyle(color: kMuted),
            )
          else
            ..._comments
                .take(3)
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: kPanel2,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${c.user} - ${c.when}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                c.content,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('Add a comment'),
                ),
              ),
              IconButton(
                onPressed: _postComment,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _uploadScreen() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        children: [
          Row(
            children: [
              _backButton(() => _goTab(_tab)),
              const SizedBox(width: 12),
              const Text(
                'Upload',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 210,
            child: StripedMedia(
              label: 'local upload placeholder',
              radius: 18,
              child: const Center(
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _input(_uploadTitle, 'TITLE'),
          _input(_uploadDescription, 'DESCRIPTION', maxLines: 4),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['sermons', 'music', 'kids', 'shorts'].map((cat) {
              final active = _uploadCategory == cat;
              return ChoiceChip(
                label: Text(cat.toUpperCase()),
                selected: active,
                showCheckmark: false,
                selectedColor: Colors.white,
                backgroundColor: kPanel,
                side: const BorderSide(color: kBorder),
                onSelected: (_) => setState(() => _uploadCategory = cat),
                labelStyle: TextStyle(
                  color: active ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          _primaryButton('Save To Local Backend', _createUpload),
          const SizedBox(height: 10),
          const Text(
            'This first local build creates a database record with local placeholder media. The backend also exposes a media folder for real files.',
            style: TextStyle(color: kMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _libraryScreen() {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          const Text(
            'Library',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.25,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            children: [
              _libraryTile(
                Icons.schedule,
                'Watch Later',
                '${_saved.length} videos',
              ),
              _libraryTile(Icons.download_outlined, 'Downloads', 'Local only'),
              _libraryTile(
                Icons.bookmark_border,
                'Saved Shorts',
                '${_saved.where((v) => v.isShort).length} shorts',
              ),
              _libraryTile(Icons.playlist_play, 'Playlists', '12 lists'),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Text(
                'History',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    setState(() => _message = 'History stays local.'),
                child: const Text('Clear', style: TextStyle(color: kMuted)),
              ),
            ],
          ),
          ...(_history.isEmpty ? _videos.take(4) : _history).map(
            _compactVideoRow,
          ),
        ],
      ),
    );
  }

  Widget _profileScreen() {
    final user = _user;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => _go(AppScreen.settings),
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
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (user?.subscription ?? 'FREE').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user?.handle ?? '@guest',
                  style: const TextStyle(color: kMuted),
                ),
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
            onTap: () => _go(AppScreen.premium),
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
                        Text(
                          'OFG Premium',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '4K - No ads - Downloads - renews Jul 8',
                          style: TextStyle(color: kMuted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  _pill('Manage', Colors.white, Colors.transparent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _profileRow(
            Icons.history,
            'Watch History',
            () => _goTab(AppScreen.library),
          ),
          _profileRow(
            Icons.download_outlined,
            'Downloads',
            () => _goTab(AppScreen.library),
          ),
          _profileRow(
            Icons.dashboard_outlined,
            'Creator Studio',
            () => _go(AppScreen.creator),
          ),
          _profileRow(
            Icons.star_border,
            'Subscription',
            () => _go(AppScreen.premium),
          ),
          _profileRow(
            Icons.settings_outlined,
            'Settings',
            () => _go(AppScreen.settings),
          ),
          _profileRow(
            Icons.info_outline,
            'Help & Support',
            () => setState(() => _message = 'Local support page coming next.'),
          ),
        ],
      ),
    );
  }

  Widget _settingsScreen() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        children: [
          Row(
            children: [
              _backButton(() => _go(AppScreen.profile)),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _settingsGroup('LOCAL SERVER', [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _serverController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Server URL'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _outlineButton('Test', _warmServer)),
                      const SizedBox(width: 10),
                      Expanded(child: _primaryButton('Apply', _applyServerUrl)),
                    ],
                  ),
                ],
              ),
            ),
          ]),
          _settingsGroup('ACCOUNT', [
            _settingChevron(
              Icons.person_outline,
              'Profile',
              _user?.name ?? 'Guest',
            ),
            _settingChevron(
              Icons.email_outlined,
              'Email & Phone',
              _user?.email ?? '',
            ),
            _settingChevron(Icons.flag_outlined, 'Language', 'English'),
          ]),
          _settingsGroup('PLAYBACK', [
            _settingToggle(
              Icons.play_circle_outline,
              'Autoplay next',
              'autoplay',
            ),
            _settingToggle(Icons.wifi, 'Download over Wi-Fi only', 'wifi'),
            _settingChevron(
              Icons.high_quality_outlined,
              'Default quality',
              '1080p',
            ),
          ]),
          _settingsGroup('NOTIFICATIONS & PRIVACY', [
            _settingToggle(
              Icons.notifications_none,
              'Push notifications',
              'push',
            ),
            _settingToggle(Icons.dark_mode_outlined, 'Dark theme', 'dark'),
            _settingToggle(Icons.lock_outline, 'Private account', 'private'),
            _settingChevron(Icons.devices_outlined, 'Device Management', '3'),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _api.token = null;
                _user = null;
                _screen = AppScreen.login;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF160D0D),
                border: Border.all(color: const Color(0xFF3A1F1F)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: kAccentSoft,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'OFG Connects - v3.2.0 local',
              style: TextStyle(color: kMuted2, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumScreen() {
    final plans = [
      ('monthly', 'Monthly', 'Billed every month', r'$9.99', '/mo'),
      ('yearly', 'Yearly', 'Save 33% - billed annually', r'$79', '/yr'),
      ('family', 'Family', 'Up to 5 profiles', r'$14.99', '/mo'),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.0),
          radius: 1.2,
          colors: [Color(0xFF161616), Colors.black],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
          children: [
            _backButton(() => _go(AppScreen.profile)),
            const SizedBox(height: 18),
            Center(child: _logo(size: 22, connects: true, premium: true)),
            const SizedBox(height: 10),
            const Text(
              'Grow in faith, ad-free',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Worship, sermons and music - anywhere.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted),
            ),
            const SizedBox(height: 26),
            ...plans.map((p) {
              final active = _selectedPlan == p.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedPlan = p.$1),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: active ? Colors.white10 : const Color(0xFF0C0C0C),
                    border: Border.all(
                      color: active ? Colors.white : kBorder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  p.$2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                if (p.$1 == 'yearly') ...[
                                  const SizedBox(width: 8),
                                  _pill('BEST VALUE', Colors.white, kAccent),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              p.$3,
                              style: const TextStyle(
                                color: kMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            p.$4,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            p.$5,
                            style: const TextStyle(color: kMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _panelDecoration(radius: 16),
              child: Column(
                children:
                    [
                          'Ad-free worship and sermons',
                          'Download messages and music',
                          'Live services early access',
                          'Family profiles up to 5',
                          'Support the ministry',
                        ]
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.black,
                                    size: 13,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Text(
                                  b,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 22),
            _primaryButton(
              'Start Free Trial',
              () => setState(() => _message = 'Premium plan saved locally.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creatorScreen() {
    final mine = _videos.where((v) => v.creatorId == _user?.id).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        children: [
          Row(
            children: [
              _backButton(() => _go(AppScreen.profile)),
              const SizedBox(width: 12),
              const Text(
                'Creator Studio',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.18,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            children: [
              _statCard('Subscribers', '1.24M', '+4.2K'),
              _statCard('Views (28d)', '8.6M', '+12%'),
              _statCard('Watch time', '214K hrs', '+9%'),
              _statCard('Revenue', r'$12.4K', '+18%'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _panelDecoration(radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Views - last 7 days',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Spacer(),
                    Text('+18%', style: TextStyle(color: kMuted)),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 96,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [40, 62, 48, 78, 58, 88, 70].map((h) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            height: h.toDouble(),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white, Color(0xFF666666)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Your Content',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...(mine.isEmpty ? _videos.take(3) : mine).map(_compactVideoRow),
        ],
      ),
    );
  }

  Widget _authScaffold({
    required String title,
    required String subtitle,
    required List<Widget> children,
    VoidCallback? back,
  }) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(34, 48, 34, 40),
        children: [
          if (back != null) ...[
            _backButton(back),
            const SizedBox(height: 22),
          ] else ...[
            _logo(size: 38, connects: true),
            const SizedBox(height: 30),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 15)),
          const SizedBox(height: 30),
          ...children.expand((w) => [w, const SizedBox(height: 14)]),
          if (!_serverOk)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _panelDecoration(radius: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOCAL SERVER',
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _serverController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Server URL'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _outlineButton('Retry', _warmServer)),
                      const SizedBox(width: 10),
                      Expanded(child: _primaryButton('Apply', _applyServerUrl)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Emulator: http://10.0.2.2:8787. Phone: use your PC LAN IP, like http://192.168.1.10:8787.',
                    style: TextStyle(color: kMuted, fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    Widget item(AppScreen tab, IconData icon, String label) {
      final active = _tab == tab;
      return GestureDetector(
        onTap: () => _goTab(tab),
        child: SizedBox(
          width: 54,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : const Color(0xFF6B6B6B),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF6B6B6B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 22,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xCC111113),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 36,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            item(AppScreen.home, Icons.home_outlined, 'Home'),
            item(AppScreen.shorts, Icons.smartphone, 'Shorts'),
            GestureDetector(
              onTap: () => setState(() => _createOpen = true),
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 26,
                        offset: Offset(0, 12),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF202020),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: _logo(size: 16, connects: false, dark: true),
                  ),
                ),
              ),
            ),
            item(AppScreen.library, Icons.format_list_bulleted, 'Library'),
            item(AppScreen.profile, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _createSheet() {
    return GestureDetector(
      onTap: () => setState(() => _createOpen = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D0D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Create',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'What would you like to make?',
                  style: TextStyle(color: kMuted, fontSize: 13),
                ),
                const SizedBox(height: 22),
                _createOption(
                  Icons.play_arrow,
                  'Upload a Message',
                  'Sermon, teaching or testimony',
                  () => _go(AppScreen.upload),
                ),
                _createOption(
                  Icons.phone_iphone,
                  'Create a Short',
                  'Vertical video, up to 60s',
                  () {
                    setState(() {
                      _uploadCategory = 'shorts';
                      _screen = AppScreen.upload;
                      _createOpen = false;
                    });
                  },
                ),
                _createOption(
                  Icons.circle_outlined,
                  'Go Live',
                  'Stream your service live',
                  () => setState(
                    () => _message = 'Live stream saved as a local draft.',
                  ),
                  accent: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playerOverlay(OfgVideo video) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: StripedMedia(label: 'fullscreen player', radius: 0),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000),
                    Colors.transparent,
                    Color(0xDD000000),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _playerOpen = false),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          video.creator,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.fit_screen, color: Colors.white),
                  const SizedBox(width: 16),
                  const Icon(Icons.more_vert, color: Colors.white),
                ],
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fast_rewind, size: 34),
                const SizedBox(width: 42),
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38),
                  ),
                  child: const Icon(Icons.pause, size: 34),
                ),
                const SizedBox(width: 42),
                const Icon(Icons.fast_forward, size: 34),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 118,
            child: _pill('Skip Intro >', Colors.white, Colors.white12),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 42,
            child: Column(
              children: [
                Row(
                  children: const [
                    Text('18:24', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 10),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.42,
                        color: kAccent,
                        backgroundColor: Colors.white24,
                        minHeight: 4,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      '43:10',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Text('1.0x'),
                    SizedBox(width: 18),
                    Text('CC'),
                    SizedBox(width: 18),
                    Text('HD'),
                    SizedBox(width: 18),
                    Text('Audio'),
                    Spacer(),
                    Icon(Icons.cast, size: 18),
                    SizedBox(width: 16),
                    Text(
                      'Next Ep >',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _busyOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _toast() {
    return Positioned(
      left: 18,
      right: 18,
      top: MediaQuery.of(context).padding.top + 12,
      child: GestureDetector(
        onTap: () => setState(() => _message = null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xEE151515),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              Icon(
                _serverOk ? Icons.info_outline : Icons.warning_amber_rounded,
                color: _serverOk ? Colors.white70 : kAccentSoft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _message!,
                  style: const TextStyle(color: Colors.white, height: 1.3),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _message = null),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: _fieldDecoration(label),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: kMuted2,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      filled: true,
      fillColor: kPanel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kAccent, width: 1.4),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFCCCCCC),
          side: const BorderSide(color: kBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _miniButton(
    IconData icon,
    String label,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _squareIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _actionChip(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 9),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? kAccent.withValues(alpha: 0.16) : kPanel2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? kAccent.withValues(alpha: 0.5) : kBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? kAccentSoft : Colors.white),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _railAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool accent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(
          radius: 16,
          color: const Color(0xFF141414),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent ? kAccent.withValues(alpha: 0.18) : kPanel2,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent ? kAccentSoft : Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted2),
          ],
        ),
      ),
    );
  }

  Widget _compactVideoRow(OfgVideo video) {
    return GestureDetector(
      onTap: () => _openVideo(video),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            SizedBox(
              width: 132,
              height: 76,
              child: StripedMedia(
                label: '',
                radius: 11,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _duration(video.duration),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${video.creator} - ${_formatViews(video.views)} views',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _libraryTile(IconData icon, String title, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kPanel2,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(count, style: const TextStyle(color: kMuted, fontSize: 12)),
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
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted2),
          ],
        ),
      ),
    );
  }

  Widget _settingsGroup(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: kMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Container(
            decoration: _panelDecoration(
              radius: 16,
              color: const Color(0xFF0E0E0E),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _settingChevron(IconData icon, String label, String value) {
    return _settingRow(
      icon,
      label,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: kMuted, fontSize: 13)),
          const Icon(Icons.chevron_right, color: kMuted2),
        ],
      ),
    );
  }

  Widget _settingToggle(IconData icon, String label, String key) {
    final value = _settings[key] ?? false;
    return _settingRow(
      icon,
      label,
      Switch(
        value: value,
        activeThumbColor: Colors.white,
        activeTrackColor: kAccent,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFF2A2A2A),
        onChanged: (next) {
          setState(() => _settings[key] = next);
          _saveSettings();
        },
      ),
    );
  }

  Widget _settingRow(IconData icon, String label, Widget trailing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF161616))),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE6E6E6),
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String delta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          Text(
            delta,
            style: const TextStyle(
              color: Color(0xFF5FD07A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 13),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          const Text(
            'See all',
            style: TextStyle(color: kMuted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _smallHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 13),
      child: Text(
        title,
        style: const TextStyle(
          color: kMuted,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _searchTermRow(String term) {
    return InkWell(
      onTap: () {
        _searchController.text = term;
        _search(term);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF141414))),
        ),
        child: Row(
          children: [
            const Icon(Icons.history, color: kMuted2, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(term)),
            const Icon(Icons.close, color: kMuted2, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _duration(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _dividerText(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: kBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: const TextStyle(color: kMuted2, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: kBorder)),
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
            child: Text(
              action,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
    );
  }

  Widget _roundBack(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chevron_left, color: Colors.white),
      ),
    );
  }

  Widget _logo({
    required double size,
    bool connects = true,
    bool premium = false,
    bool dark = false,
  }) {
    final color = dark ? Colors.black : Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'OFG',
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0,
          ),
        ),
        Container(
          width: size * 0.23,
          height: size * 0.23,
          margin: EdgeInsets.only(
            left: 2,
            right: connects ? 6 : 0,
            bottom: size * 0.16,
          ),
          decoration: const BoxDecoration(
            color: kAccent,
            shape: BoxShape.circle,
          ),
        ),
        if (connects)
          Text(
            premium ? 'Premium' : 'CONNECTS',
            style: TextStyle(
              color: premium ? Colors.white : kMuted,
              fontSize: premium ? size : size * 0.34,
              fontWeight: FontWeight.w900,
              letterSpacing: premium ? 0 : 3,
            ),
          ),
      ],
    );
  }

  Widget _pill(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: bg == Colors.transparent ? kBorder : bg),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }

  BoxDecoration _panelDecoration({double radius = 12, Color color = kPanel}) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: kBorder),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  OfgVideo _fallbackVideo() {
    return OfgVideo(
      id: 'fallback',
      title: 'The Power of Grace',
      creator: 'Pastor David Cole',
      creatorId: 'creator_demo',
      category: 'sermons',
      duration: '58:10',
      meta: '2.1M views',
      description: 'A message on the power of grace and walking in faith.',
      label: 'service still 16:9',
      views: 2100000,
      likes: 24000,
      comments: 842,
      isShort: false,
      isLive: false,
      progress: 0.34,
      liked: false,
      saved: false,
      following: false,
    );
  }

  OfgVideo _fallbackShort() {
    return OfgVideo(
      id: 'short_demo',
      title: 'Daily Verse',
      creator: '@dailyverse',
      creatorId: 'creator_daily',
      category: 'shorts',
      duration: '0:42',
      meta: '128K views',
      description: 'I can do all things through Christ - Philippians 4:13',
      label: 'short 9:16',
      views: 128000,
      likes: 128000,
      comments: 2400,
      isShort: true,
      isLive: false,
      progress: 0,
      liked: false,
      saved: false,
      following: false,
    );
  }

  String _formatViews(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return value.toString();
  }
}

class StripedMedia extends StatelessWidget {
  const StripedMedia({
    super.key,
    required this.label,
    this.radius = 14,
    this.child,
  });

  final String label;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(color: const Color(0xFF1D1D1D)),
        ),
        child: CustomPaint(
          painter: _StripePainter(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (label.isNotEmpty)
                Positioned(
                  left: 10,
                  top: 9,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF5A5A5A),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ?child,
            ],
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF151515);
    final light = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRect(Offset.zero & size, dark);
    const stripe = 24.0;
    for (double x = -size.height; x < size.width + size.height; x += stripe) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 12, 0)
        ..lineTo(x + size.height + 12, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, light);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.035), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
