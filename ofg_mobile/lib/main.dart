// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- YOUR BEAUTIFUL CLEAN IMPORTS ---
import 'presentation/theme/ofg_theme.dart';
import 'presentation/widgets/ofg_ui.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/shorts_page.dart';
import 'presentation/pages/video_page.dart';
import 'presentation/pages/library_page.dart';
import 'presentation/pages/profile_page.dart';
import 'logic/providers.dart';
import 'models/ofg_models.dart';

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
  
  // ProviderScope is the brain of Riverpod!
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
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          fontFamily: 'Roboto',
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Automatically routes users based on their login status!
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

// The core shell of your app
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          _buildCurrentPage(),
          
          // Fullscreen Video Player Overlay
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
            
          // Hide bottom nav if we are watching a full-screen video
          if (_activeVideo == null) 
            _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomePage(onVideoTap: _openVideo, onSearchTap: () {});
      case 1:
        return ShortsPage(onCommentTap: (video) {});
      case 3:
        return LibraryPage(onVideoTap: _openVideo);
      case 4:
        return ProfilePage(
          onSettingsTap: () {},
          onCreatorTap: () {},
          onPremiumTap: () {},
        );
      default:
        return HomePage(onVideoTap: _openVideo, onSearchTap: () {});
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
          color: const Color(0xCC111113),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 36, offset: Offset(0, 18)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_outlined, 'Home'),
            _navItem(1, Icons.smartphone, 'Shorts'),
            
            // Center Create Button
            GestureDetector(
              onTap: () {
                // TODO: Wire up upload sheet
              },
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black87, blurRadius: 26, offset: Offset(0, 12)),
                    ],
                    border: Border.all(color: const Color(0xFF202020), width: 4),
                  ),
                  child: const Center(
                    child: OfgLogo(size: 16, connects: false, dark: true),
                  ),
                ),
              ),
            ),
            
            _navItem(3, Icons.format_list_bulleted, 'Library'),
            _navItem(4, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.white : const Color(0xFF6B6B6B)),
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
}