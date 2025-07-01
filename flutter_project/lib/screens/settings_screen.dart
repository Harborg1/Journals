import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/main.dart';
import 'login_screen.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _darkMode = false;

  Future<void> _deleteAccountAndData() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (user != null && uid != null) {
      try {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

        // Delete all journal entries (if they exist)
        final journalEntries = await userDoc.collection('journals').get();
        for (final doc in journalEntries.docs) {
          await doc.reference.delete();
        }

        // Delete the user document
        await userDoc.delete();

        // Delete the Firebase Auth user
        await user.delete();

        try {
        final result = await supabase
            .from('firebase_users')
            .delete()
            .eq('user_id', uid);

        debugPrint('Supabase deletion result: $result');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Supabase deletion failed: $e')),
        );
      }


        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccountAndData();
            },
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email != null) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkMode,
            onChanged: (val) {
              setState(() => _darkMode = val);
              // TODO: Add actual dark mode persistence with Provider or shared_preferences
            },
          ),
              ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Change Password'),
                  Icon(Icons.lock_reset),
                ],
              ),
              onTap: _changePassword,
            ),
                  ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Delete Account'),
              Icon(Icons.delete_forever),
            ],
          ),
          onTap: _showDeleteAccountDialog,
        ),
        ],
      ),
    );
  }
}
