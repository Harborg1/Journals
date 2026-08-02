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
  late TextEditingController identifierController; // username or email
  late TextEditingController passwordController;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    identifierController = TextEditingController();
    passwordController = TextEditingController();
    identifierController.clear();
    passwordController.clear();
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    final identifier = identifierController.text.trim();
    final passwordText = passwordController.text.trim();

    if (identifier.isEmpty || passwordText.isEmpty) {
      setState(() => errorMessage = 'Both fields are required');
      return;
    }

    try {
      // Determine if input is an email or username
      final bool isEmail = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(identifier);
      String emailToUse = identifier;

      if (!isEmail) {
        // Look up email by username
        final usernameDoc = await FirebaseFirestore.instance
            .collection('usernames')
            .doc(identifier)
            .get();
        
      
        if (!usernameDoc.exists) {
          setState(() => errorMessage = 'Username not found');
          return;
        }

        emailToUse = usernameDoc['email'];
      }

      // Sign in with resolved email
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailToUse, password: passwordText);

      final uid = userCredential.user!.uid;

      // Get data from userDoc field
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final salt = userDoc['salt'] as String;
      final userName = userDoc['username'] as String;
      final encryptedMasterKey = userDoc['encryptedMasterKey'] as String;
      final derivedKey = await deriveKeyFromPasswordAndSalt(passwordText, salt);
      final masterKey = decryptMasterKey(encryptedMasterKey, derivedKey);

      SessionKeyManager().setKey(masterKey);

      // Clear fields and navigate
      identifierController.clear();
      passwordController.clear();

  
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(userEmail: emailToUse,username: userName),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Journals'),centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              "Start journalling today!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: identifierController,
              decoration: InputDecoration(
                labelText: 'Username or Email',
                hintText: 'Enter your username or email',
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
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
