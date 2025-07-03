import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project/security/encryption_helper.dart';
import 'package:flutter_project/security/security_manager.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();

    // Clear text fields to ensure they don't retain values
    emailController.clear();
    passwordController.clear();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
  final passwordText = passwordController.text.trim();
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordText,
    );

    final uid = userCredential.user!.uid;

    // 1. Fetch salt and encrypted master key from Firestore
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final salt = userDoc['salt'] as String;
    final encryptedMasterKey = userDoc['encryptedMasterKey'] as String;

    // 2. Derive password-based key
    final derivedKey = await deriveKeyFromPasswordAndSalt(passwordText, salt);

    // 3. Decrypt the master key
    final masterKey = decryptMasterKey(encryptedMasterKey, derivedKey); // You must implement this function

    // 4. Store master key in session
    SessionKeyManager().setKey(masterKey);

    print("✅ Master key loaded and set in session");

    // Proceed to welcome screen
    emailController.clear();
    passwordController.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WelcomeScreen(userEmail: userCredential.user!.email!),
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
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration:
                  InputDecoration(labelText: 'Email', hintText: 'Enter email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: 'Password', hintText: 'Enter password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: signIn, child: Text('Sign In')),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text("Don't have an account? Register here"),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              )
          ],
        ),
      ),
    );
  }
}
