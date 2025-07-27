import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:flutter/animation.dart'; // required for AnimationController
import 'package:flutter_project/screens/journal_entries_screen.dart';
import 'package:flutter_project/screens/settings_screen.dart';
import 'package:flutter_project/screens/todo_screen.dart';
import 'journal_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final String userEmail;
  final String username;
  const WelcomeScreen({super.key, required this.userEmail, required this.username});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  bool showTree = false;
  bool animationCompleted = false;
  AnimationController? _animationController;

  void _openToDoScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ToDo()),
    );

    if (result == true) {
      _animationController?.dispose(); // Dispose old controller if exists

      _animationController = AnimationController(vsync: this);
      _animationController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            animationCompleted = true;
          });
        }
      });

      setState(() {
        showTree = true;
        animationCompleted = false; // Reset to show new animation
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🌱 You completed all tasks!')),
      );
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

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
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                      'Hello ${widget.username}!',
                      textAlign: isWide ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (showTree && !animationCompleted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: SizedBox(
                          height: 200,
                          child: _buildTreeAnimation(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          final uid = user.uid;
                          final email = user.email;

                          try {
                            final doc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .get();

                            final username = doc['username'] as String;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JournalScreen(
                                  userId: uid,
                                  userEmail: email,
                                  userName: username,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to load user data')),
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
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openToDoScreen,
                        child: const Text('Todo list'),
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

  Widget _buildTreeAnimation() {
    try {
      return lottie.Lottie.asset(
        'assets/tree_plant.json',
        controller: _animationController,
        onLoaded: (composition) {
          _animationController?.duration = composition.duration;
          _animationController?.forward();
        },
        repeat: false,
      );
    } catch (e) {
      debugPrint('Lottie load error: $e');
      return const Text('Animation failed to load');
    }
  }
}
