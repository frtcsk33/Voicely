import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/ai_homepage.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/books_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/real_time_conversation_screen.dart';
import 'providers/translator_provider.dart';
import 'services/supabase_client.dart';
import 'services/auth_service.dart';
import 'services/books_service.dart';
import 'services/user_service.dart';
import 'providers/conversation_provider.dart';
import 'providers/real_time_conversation_provider.dart';
import 'widgets/auth_state_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'services/http_overrides.dart';

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseConfig.initialize();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final provider = TranslatorProvider();
            provider.initializeApp();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (context) => UserService()),
        ChangeNotifierProxyProvider<UserService, AuthService>(
          create: (context) => AuthService(),
          update: (context, userService, authService) {
            authService?.setUserService(userService);
            return authService ?? AuthService(userService: userService);
          },
        ),
        ChangeNotifierProvider(create: (context) => BooksService()),
        ChangeNotifierProxyProvider<UserService, ConversationProvider>(
          create: (context) => ConversationProvider(),
          update: (context, userService, conversationProvider) {
            conversationProvider?.setUserService(userService);
            return conversationProvider ?? ConversationProvider();
          },
        ),
        ChangeNotifierProvider(create: (context) => RealTimeConversationProvider()),
      ],
      child: const VoicelyApp(),
    ),
  );
}

class VoicelyApp extends StatelessWidget {
  const VoicelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslatorProvider>(
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
            Locale('zh', 'TW'),
            Locale('ar', 'SA'),
            Locale('hi', 'IN'),
            Locale('bn', 'BD'),
            Locale('ur', 'PK'),
            Locale('fa', 'IR'),
            Locale('nl', 'NL'),
            Locale('sv', 'SE'),
            Locale('no', 'NO'),
            Locale('da', 'DK'),
            Locale('fi', 'FI'),
            Locale('pl', 'PL'),
            Locale('cs', 'CZ'),
            Locale('sk', 'SK'),
            Locale('hu', 'HU'),
            Locale('ro', 'RO'),
            Locale('bg', 'BG'),
            Locale('hr', 'HR'),
            Locale('sr', 'RS'),
            Locale('sl', 'SI'),
            Locale('lt', 'LT'),
            Locale('lv', 'LV'),
            Locale('et', 'EE'),
            Locale('el', 'GR'),
            Locale('he', 'IL'),
            Locale('th', 'TH'),
            Locale('vi', 'VN'),
            Locale('id', 'ID'),
            Locale('ms', 'MY'),
            Locale('tl', 'PH'),
            Locale('uk', 'UA'),
            Locale('be', 'BY'),
            Locale('ka', 'GE'),
            Locale('hy', 'AM'),
            Locale('az', 'AZ'),
            Locale('kk', 'KZ'),
            Locale('uz', 'UZ'),
            Locale('ky', 'KG'),
            Locale('tg', 'TJ'),
            Locale('tk', 'TM'),
            Locale('mn', 'MN'),
            Locale('am', 'ET'),
            Locale('sw', 'KE'),
            Locale('ha', 'NG'),
            Locale('yo', 'NG'),
            Locale('ig', 'NG'),
            Locale('zu', 'ZA'),
            Locale('af', 'ZA'),
            Locale('ca', 'ES'),
            Locale('eu', 'ES'),
            Locale('gl', 'ES'),
            Locale('ga', 'IE'),
            Locale('gd', 'GB'),
            Locale('cy', 'GB'),
            Locale('is', 'IS'),
            Locale('mt', 'MT'),
            Locale('co', 'FR'),
            Locale('lb', 'LU'),
            Locale('eo', 'XX'),
            Locale('la', 'VA'),
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
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          home: const AuthStateWrapper(
            child: MainScreen(),
          ),
          routes: {
            '/settings': (context) => const SettingsScreen(),
          },
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode &&
                  supportedLocale.countryCode == locale?.countryCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
        );
      },
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
    const AIHomepage(),
    const RealTimeConversationScreen(),
    const CameraScreen(),
    const BooksScreen(),
    const HistoryScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final translatorProvider = context.read<TranslatorProvider>();
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
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
            label: translatorProvider.getLocalizedText('translate'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.record_voice_over),
            label: 'İki Taraflı',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.camera_alt),
            label: translatorProvider.getLocalizedText('camera'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book),
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: translatorProvider.getLocalizedText('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: translatorProvider.getLocalizedText('favorites'),
          ),
        ],
      ),
    );
  }
}
