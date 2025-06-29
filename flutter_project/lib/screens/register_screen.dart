import '../main.dart'; // Adjust path if needed
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import '../security/encryption_helper.dart';
import '../security/security_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> register() async {
    
    final passwordText = passwordController.text.trim();
  try {
    // 1. Sign up with Firebase Auth
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordText,
    );

    final email = userCredential.user?.email;
    if (email == null) throw Exception('User email is null');

    // 2. Save to Firebase Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'email': email,
      'createdAt': Timestamp.now(),
    });

    // 3. Generate salt
    final salt = generateSalt();
   
    // 4. Insert into Supabase
   try {
    final response = await supabase.from('firebase_users').insert({
    'user_id': userCredential.user!.uid,
    'salt': salt,
    'created_at': DateTime.now().toIso8601String(),
  }).select();

    // Optionally log/print the result
    print("Insert result: $response");

  } catch (e) {
    // This is where you handle Supabase errors now
    throw Exception('Supabase insert failed: $e');
  }

  final encryptionKey = await deriveKeyFromPasswordAndSalt(passwordText, salt);

  SessionKeyManager().setKey(encryptionKey);

    // 5. Navigate to Welcome screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(userEmail: email),
      ),
    );
  } catch (e) {
    setState(() {
      errorMessage = e.toString();
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: Text('Register')),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(errorMessage, style: TextStyle(color: Colors.red)),
              )
          ],
        ),
      ),
    );
  }
}
