import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:supabase/supabase.dart';

final supabase = SupabaseClient(
  'https://fshjmxwerbnspjtvzomw.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzaGpteHdlcmJuc3BqdHZ6b213Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2MjU0MzMsImV4cCI6MjA2NjIwMTQzM30.0TY22SSEbWpH3T22Du7C9Fx4VUjXtaH4bkNqbGfahcM',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Demo',
      home: LoginScreen(),
    );
  }
}
