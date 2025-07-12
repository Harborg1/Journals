import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/security/encryption_helper.dart';
import 'package:flutter_project/security/security_manager.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_project/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

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

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No user is currently signed in.')),
    );
    return;
  }

  final TextEditingController newPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              Navigator.pop(dialogContext); // Close the dialog first

              try {
                await user.updatePassword(newPassword);

                final masterKey = SessionKeyManager().key;
                if (masterKey == null) {
                  throw Exception("Master key not found in session");
                }

                final newSalt = generateSalt();
                final newDerivedKey = await deriveKeyFromPasswordAndSalt(newPassword, newSalt);
                final newEncryptedMasterKey = encryptMasterKey(masterKey, newDerivedKey);

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'salt': newSalt,
                  'encryptedMasterKey': newEncryptedMasterKey,
                });
                // Defer snackbar to ensure context is valid
                if (mounted) {
                  Future.microtask(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed and encryption updated.')),
                    );
                  });
                }
              } catch (e) {
                if (mounted) {
                  Future.microtask(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  });
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Screen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
        SwitchListTile(
          title: const Text('Dark Mode'),
          value: themeProvider.isDarkMode,
          onChanged: (val) {
            themeProvider.toggleTheme(val);
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
