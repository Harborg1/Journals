import 'dart:ui'; // Needed for PointerDeviceKind
import 'package:flutter/gestures.dart'; // Needed for PointerDeviceKind
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; 
import 'theme/theme.dart'; 
import 'theme/theme_provider.dart'; 
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse, // Allow mouse dragging
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Firebase Demo',
      home: const LoginScreen(),
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: themeProvider.themeMode,

      // 👇 Enable mouse dragging globally
      scrollBehavior: MyCustomScrollBehavior(),
    );
  }
}
