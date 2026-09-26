import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'providers/radio_provider.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/recordings_screen.dart';
import 'widgets/mini_player.dart';
import 'widgets/background_widget.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.worldradio.app.channel.audio',
      androidNotificationChannelName: 'Radio Playback',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint("JustAudioBackground init failed: $e");
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(WorldRadioApp(prefs: prefs));
}

class WorldRadioApp extends StatelessWidget {
  final SharedPreferences prefs;
  const WorldRadioApp({super.key, required this.prefs});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RadioProvider(prefs)),
      ],
      child: MaterialApp(
        title: 'World Radio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
          ),
          fontFamily: 'Roboto',
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    FavoritesScreen(),
    RecordingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return RadialGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.cardBorder, width: 0.8)),
                ),
                child: NavigationBar(
                  backgroundColor: AppColors.surface.withOpacity(0.95),
                  indicatorColor: AppColors.accent.withOpacity(0.2),
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.accent), label: 'الرئيسية'),
                    NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search, color: AppColors.accent), label: 'بحث'),
                    NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite, color: AppColors.accentPink), label: 'المفضلة'),
                    NavigationDestination(icon: Icon(Icons.mic_none_outlined), selectedIcon: Icon(Icons.mic, color: AppColors.accent), label: 'التسجيلات'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
