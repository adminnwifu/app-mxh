import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'features/auth/login_screen.dart';
import 'features/feed/feed_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/profile/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

/// Chế độ giao diện mặc định MÀU ĐEN (ThemeMode.dark)

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,

  );

  runApp(const MiniSocialApp());

}



class MiniSocialApp extends StatelessWidget {

  const MiniSocialApp({super.key});



  @override

  Widget build(BuildContext context) {

    final primaryColor = const Color(0xFF6366F1); // Indigo Accent

    final secondaryColor = const Color(0xFFEC4899); // Pink Accent

    final borderSide = const BorderSide(color: Color(0xFF475569), width: 1.5);



    return ValueListenableBuilder<ThemeMode>(

      valueListenable: themeNotifier,

      builder: (context, currentMode, _) {

        return MaterialApp(

          title: 'MiniSocial',

          debugShowCheckedModeBanner: false,

          themeMode: currentMode,



          // BỘ PHÓNG TO CỠ CHỮ TOÀN BỘ ỨNG DỤNG (Điều chỉnh vừa phải 1.15 để tránh tràn màn hình)

          builder: (context, child) {

            return MediaQuery(

              data: MediaQuery.of(context).copyWith(

                textScaler: const TextScaler.linear(1.15),

              ),

              child: child!,

            );

          },


          // 1. GIAO DIỆN SÁNG (Light Theme)

          theme: ThemeData(

            useMaterial3: true,

            brightness: Brightness.light,

            colorScheme: ColorScheme.fromSeed(

              seedColor: primaryColor,

              primary: primaryColor,

              secondary: secondaryColor,

              brightness: Brightness.light,

            ),

            scaffoldBackgroundColor: const Color(0xFFF8FAFC),

            textTheme: const TextTheme(

              bodyLarge: TextStyle(fontSize: 18),

              bodyMedium: TextStyle(fontSize: 16),

              bodySmall: TextStyle(fontSize: 14),

              titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

              titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),

              titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

            ),

            appBarTheme: const AppBarTheme(

              centerTitle: false,

              elevation: 0,

              backgroundColor: Colors.white,

              foregroundColor: Colors.black87,

              titleTextStyle: TextStyle(

                color: Colors.black87,

                fontSize: 22,

                fontWeight: FontWeight.bold,

              ),

            ),

          ),



        // 2. GIAO DIỆN TỐI (Dark Theme cao cấp)

          darkTheme: ThemeData(

            useMaterial3: true,

            brightness: Brightness.dark,

            colorScheme: ColorScheme.fromSeed(

              seedColor: primaryColor,

              primary: primaryColor,

              secondary: secondaryColor,

              brightness: Brightness.dark,

              surface: const Color(0xFF1E293B),

            ),

            scaffoldBackgroundColor: const Color(0xFF0F172A),

            textTheme: const TextTheme(

              bodyLarge: TextStyle(fontSize: 18),

              bodyMedium: TextStyle(fontSize: 16),

              bodySmall: TextStyle(fontSize: 14),

              titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

              titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),

              titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

            ),

            appBarTheme: const AppBarTheme(

              centerTitle: false,

              elevation: 0,

              backgroundColor: Color(0xFF0F172A),

              foregroundColor: Colors.white,

              titleTextStyle: TextStyle(

                color: Colors.white,

                fontSize: 22,

                fontWeight: FontWeight.bold,

              ),

            ),

            cardTheme: CardThemeData(

              elevation: 0,

              shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(16),

                side: const BorderSide(color: Color(0xFF334155), width: 1.5),

              ),

              color: const Color(0xFF1E293B),

            ),

            inputDecorationTheme: InputDecorationTheme(

              filled: true,

              fillColor: const Color(0xFF1E293B),

              border: OutlineInputBorder(

                borderRadius: BorderRadius.circular(12),

                borderSide: BorderSide.none,

              ),

              enabledBorder: OutlineInputBorder(

                borderRadius: BorderRadius.circular(12),

                borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),

              ),

              focusedBorder: OutlineInputBorder(

                borderRadius: BorderRadius.circular(12),

                borderSide: BorderSide(color: primaryColor, width: 1.5),

              ),

              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),

            ),

            outlinedButtonTheme: OutlinedButtonThemeData(

              style: OutlinedButton.styleFrom(

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(24),

                ),

                side: borderSide,

                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),

                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),

              ),

            ),

            filledButtonTheme: FilledButtonThemeData(

              style: FilledButton.styleFrom(

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(12),

                ),

                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),

                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),

              ),

            ),

            navigationBarTheme: NavigationBarThemeData(

              backgroundColor: const Color(0xFF1E293B),

              indicatorColor: primaryColor.withValues(alpha: 0.25),

              elevation: 8,

              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

              height: 65,

            ),

          ),

          home: const AuthGate(),

        );

      },

    );

  }

}

/// Cổng kiểm tra trạng thái đăng nhập tự động
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

/// Màn hình khung chứa Bottom Navigation Bar hiện đại & Lắng nghe Thông báo
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    KeyedSubtree(key: ValueKey('feed_tab'), child: FeedScreen()),
    KeyedSubtree(key: ValueKey('friends_tab'), child: FriendsScreen()),
    KeyedSubtree(key: ValueKey('profile_tab'), child: ProfileScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid != null) {
      final notifService = NotificationService();
      await notifService.initializeLocalNotifications();
      notifService.listenToRealtimeNotifications(currentUid);
    }
  }

  @override
  void dispose() {
    NotificationService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: primary),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded, color: primary),
              label: 'Bạn bè',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: primary),
              label: 'Trang cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
