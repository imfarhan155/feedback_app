import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';

// ✨ Global notifier jo puri app ka theme control karega
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🚀 Firebase Manual Initialization
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDsN_m7mXd-96yvsT5oRUNkUBphiQd-v1c',
        appId: '1:484421635706:android:17bf995413fecb71f8f5c3',
        messagingSenderId: '484421635706',
        projectId: 'feedback-app-6e7b4',
      ),
    );

    // ⏱️ Native startup screen/icon ko thodi der screen par rokne ke liye delay
    await Future.delayed(const Duration(seconds: 2));
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder har dafa theme switch hone par UI refresh karega
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Feedback App',

          // ☀️ Light Theme Settings
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.grey.shade100,
          ),

          // 🌙 Dark Theme Settings
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
          ),

          themeMode: currentMode, // Dynamic theme state link
          home: const SplashScreen(),
        );
      },
    );
  }
}
