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
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> register() async {
    final usernameText = usernameController.text.trim();
    final emailText = emailController.text.trim();
    final passwordText = passwordController.text.trim();

    if (usernameText.isEmpty || emailText.isEmpty || passwordText.isEmpty) {
      setState(() => errorMessage = 'All fields are required');
      return;
    }

    try {
      // 1. Check if username already exists
      final existingUsername = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(usernameText)
          .get();

      if (existingUsername.exists) {
        setState(() => errorMessage = 'Username already taken');
        return;
      }

      // 2. Create user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailText,
        password: passwordText,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('User creation failed');

      // 3. Generate salt and master key
      final salt = generateSalt();
      final masterKey = generateMasterKey();

      // 4. Derive password-based key
      final derivedKey = await deriveKeyFromPasswordAndSalt(passwordText, salt);

      // 5. Encrypt master key
      final encryptedMasterKey = encryptMasterKey(masterKey, derivedKey);

      // 6. Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': emailText,
        'username': usernameText,
        'createdAt': Timestamp.now(),
        'salt': salt,
        'encryptedMasterKey': encryptedMasterKey,
        'isDarkMode': false,
      });

      // 7. Store username → email mapping for login lookup
      await FirebaseFirestore.instance
      .collection('usernames')
      .doc(usernameText)
      .set({
        'email': emailText,
        'userId': uid, 
      });

      // 8. Store master key in session
      SessionKeyManager().setKey(masterKey);

      // 9. Navigate to welcome screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(userEmail: emailText, username: usernameText,),
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
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
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
