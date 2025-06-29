import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'package:flutter_project/security/encryption_helper.dart';

class JournalScreen extends StatefulWidget {
  final String userId;
  final String? userEmail;

  const JournalScreen({super.key, required this.userId, this.userEmail});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController journalController = TextEditingController();

  void saveJournalEntry() async {
  final entry = journalController.text.trim();

  if (entry.isNotEmpty) {
    final encryptedEntry = EncryptionHelper.encryptText(entry);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('journals')
        .add({
      'text': encryptedEntry,
      'createdAt': Timestamp.now(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Journal entry saved!')),
    );

  Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (context) => WelcomeScreen(userEmail: widget.userEmail ?? ''),
  ),
  (route) => false, // removes all previous routes
);
    journalController.clear();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Journal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: journalController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'How was your day?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveJournalEntry,
              child: Text('Save Entry'),
            )
          ],
        ),
      ),
    );
  }
}
