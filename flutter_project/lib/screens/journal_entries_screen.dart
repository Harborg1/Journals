import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/security/encryption_helper.dart';

class JournalEntriesScreen extends StatelessWidget {
  final String userId;

  JournalEntriesScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    final journalRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journals')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Journal Entries'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: journalRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text('No journal entries found.'));

          final entries = snapshot.data!.docs;

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final doc = entries[index];
              final encryptedText = doc['text'] as String;
              final timestamp = doc['createdAt'] as Timestamp;
              final date = timestamp.toDate();
              final formattedDate =
                  "${date.day}/${date.month}/${date.year}";

              return FutureBuilder<String>(
               future: Future.value(EncryptionHelper.decryptText(encryptedText)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      title: Text(formattedDate),
                      subtitle: Text('Decrypting...'),
                    );
                  }

                  final decryptedText = snapshot.data!;
                  return ListTile(
                    title: Text(formattedDate),
                    subtitle: Text(
                      decryptedText.length > 50
                          ? '${decryptedText.substring(0, 50)}...'
                          : decryptedText,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(formattedDate),
                          content: Text(decryptedText),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

