import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/screens/journal_entries_screen.dart';
import 'package:flutter_project/screens/settings_screen.dart';
import 'journal_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final String userEmail;
  const WelcomeScreen({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
  PopupMenuButton<String>(
    icon: const Icon(Icons.settings),
    onSelected: (String choice) async {
      if (choice == 'logout') {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else if (choice == 'preferences') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Settings()),
        );
      }
    },
    itemBuilder: (BuildContext context) => [
      const PopupMenuItem<String>(
        value: 'preferences',
        child: Text('Settings'),
      ),
      const PopupMenuItem<String>(
        value: 'logout',
        child: Text('Log Out'),
      ),
    ],
  ),
],

      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Hello $userEmail!',
                      textAlign: isWide ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final userId = FirebaseAuth.instance.currentUser?.uid;
                          final email = FirebaseAuth.instance.currentUser?.email;
                          if (userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JournalScreen(
                                  userId: userId,
                                  userEmail: email,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User not logged in')),
                            );
                          }
                        },
                        child: const Text('Write Journal'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final userId = FirebaseAuth.instance.currentUser?.uid;
                          if (userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    JournalEntriesScreen(userId: userId),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User not logged in')),
                            );
                          }
                        },
                        child: const Text('View Past Entries'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
