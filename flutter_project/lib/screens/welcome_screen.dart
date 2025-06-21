import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'journal_screen.dart';
class WelcomeScreen extends StatelessWidget {
  final String userEmail;

  WelcomeScreen({required this.userEmail});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hello $userEmail!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final userId = FirebaseAuth.instance.currentUser?.uid;

                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalScreen(userId: userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User not logged in')),
                  );
                }
              },
              child: Text('Write Journal'), // ✅ this was missing
            ),
          ],
        ),
      ),
    );
  }
}
