// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/theme/ofg_theme.dart';
import 'presentation/widgets/ofg_ui.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/shorts_page.dart';
import 'presentation/pages/video_page.dart';
import 'presentation/pages/library_page.dart';
import 'presentation/pages/profile_page.dart';
import 'presentation/pages/create_sheet.dart';
import 'presentation/pages/search_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/creator_studio_page.dart';
import 'presentation/pages/notifications_page.dart';
import 'presentation/pages/admin_page.dart';
import 'logic/providers.dart';
import 'models/ofg_models.dart';
import 'api/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar, dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: OfgApp()));
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
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.transparent,
          labelStyle: TextStyle(color: Colors.white70),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0D0D0D),
          modalBarrierColor: Colors.black87,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF121212),
          surfaceTintColor: Colors.transparent,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? kAccent : Colors.white54),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? kAccent.withValues(alpha: 0.4) : Colors.white12),
        ),
      ),
      home: const AppStartup(),
    );
  }
}

/// Handles loading saved auth state before showing the app
class AppStartup extends ConsumerStatefulWidget {
  const AppStartup({super.key});

  @override
  ConsumerState<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends ConsumerState<AppStartup> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final token = await OfgStorage.getToken();
      final user = await OfgStorage.getUser();
      if (token != null && user != null) {
        // Restore session
        ref.read(apiClientProvider).token = token;
        ref.read(authStateProvider.notifier).state = user;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OfgLogo(size: 38, connects: true),
              SizedBox(height: 40),
              CircularProgressIndicator(color: kAccent, strokeWidth: 2),
            ],
          ),
        ),
      );
    }
    return const AuthWrapper();
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    if (user == null) {
      return AuthPage(onAuthSuccess: () {});
    }
    return const MainLayout();
  }
}

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;
  OfgVideo? _activeVideo;

  void _openVideo(OfgVideo video) {
    setState(() => _activeVideo = video);
  }

  void _closeVideo() {
    setState(() => _activeVideo = null);
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: SearchPage(onVideoTap: _openVideo),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: NotificationsPage(
            onVideoTapById: (videoId) {
              Navigator.of(context).pop();
              // Could load video by ID here — for now close notifications
            },
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: SettingsPage(onLogout: _performLogout),
        ),
      ),
    );
  }

  void _openCreatorStudio() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: CreatorStudioPage(
            onUploadTap: () {
              Navigator.of(context).pop();
              _openCreateSheet();
            },
          ),
        ),
      ),
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const CreateSheet(),
      ),
    );
  }

  void _openAdminPanel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: const AdminPage(),
        ),
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/auth/logout');
    } catch (_) {}
    await OfgStorage.clear();
    ref.read(apiClientProvider).token = null;
    ref.read(authStateProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          _buildCurrentPage(),

          // Video overlay — full screen when active
          if (_activeVideo != null)
            Positioned.fill(
              child: Container(
                color: kBg,
                child: VideoPage(
                  video: _activeVideo!,
                  onBack: _closeVideo,
                  onRelatedTap: _openVideo,
                ),
              ),
            ),

          // Bottom nav — hidden when video is playing
          if (_activeVideo == null) _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomePage(
          onVideoTap: _openVideo,
          onSearchTap: _openSearch,
          onNotificationTap: _openNotifications,
        );
      case 1:
        return ShortsPage(onCommentTap: (video) {});
      case 3:
        return LibraryPage(onVideoTap: _openVideo);
      case 4:
        return ProfilePage(
          onSettingsTap: _openSettings,
          onCreatorTap: _openCreatorStudio,
          onPremiumTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OFG Premium coming soon!'),
                backgroundColor: kAccent,
              ),
            );
          },
          onNotificationTap: _openNotifications,
        );
      default:
        return HomePage(
          onVideoTap: _openVideo,
          onSearchTap: _openSearch,
          onNotificationTap: _openNotifications,
        );
    }
  }

  Widget _buildBottomNav() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 22,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xCC0A0A0A),
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
            _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _navItem(1, Icons.play_circle_outline, Icons.play_circle_filled, 'Shorts'),

            // Center Create Button
            GestureDetector(
              onTap: _openCreateSheet,
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
                      color: const Color(0xFF1A1A1A),
                      width: 4,
                    ),
                  ),
                  child: const Center(
                    child: OfgLogo(size: 16, connects: false, dark: true),
                  ),
                ),
              ),
            ),

            _navItem(3, Icons.video_library_outlined, Icons.video_library, 'Library'),
            _navItem(4, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? Colors.white : const Color(0xFF5A5A5A),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF5A5A5A),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}