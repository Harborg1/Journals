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

      final uid = userCredential.user?.uid;
      final email = userCredential.user?.email;
      if (uid == null || email == null) throw Exception('User creation failed');

      // 2. Generate salt and master key
      final salt = generateSalt();
      final masterKey = generateMasterKey();

      // 3. Derive password-based key
      final derivedKey = await deriveKeyFromPasswordAndSalt(passwordText, salt);

      // 4. Encrypt master key using password-derived key
      final encryptedMasterKey = encryptMasterKey(masterKey, derivedKey);

      // 5. Store encryptedMasterKey and salt in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'createdAt': Timestamp.now(),
        'salt': salt,
        'encryptedMasterKey': encryptedMasterKey,
        'isDarkMode':false
      });

      // 6. Store masterKey in session memory for encrypting entries
      SessionKeyManager().setKey(masterKey);

      // 7. Navigate to Welcome screen
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
