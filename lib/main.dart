import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/translator_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/translator_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const VoicelyApp());
}

class VoicelyApp extends StatelessWidget {
  const VoicelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = TranslatorProvider();
        provider.initializeApp();
        return provider;
      },
      child: Consumer<TranslatorProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Voicely',
            locale: Locale(provider.appLanguage),
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
              Locale('de', 'DE'),
              Locale('fr', 'FR'),
              Locale('es', 'ES'),
              Locale('it', 'IT'),
              Locale('pt', 'PT'),
              Locale('ru', 'RU'),
              Locale('ja', 'JP'),
              Locale('ko', 'KR'),
              Locale('zh', 'CN'),
              Locale('ar', 'SA'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            home: const MainScreen(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TranslatorScreen(),
    const CameraScreen(),
    const HistoryScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Consumer<TranslatorProvider>(
          builder: (context, provider, child) {
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue[600],
              unselectedItemColor: Colors.grey[600],
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.translate),
                  label: provider.getLocalizedText('translate'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.camera_alt),
                  label: provider.getLocalizedText('camera'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.history),
                  label: provider.getLocalizedText('history'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.favorite),
                  label: provider.getLocalizedText('favorites'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 