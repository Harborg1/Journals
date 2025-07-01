import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/security/encryption_helper.dart';

class JournalEntriesScreen extends StatefulWidget {
  final String userId;

  const JournalEntriesScreen({super.key, required this.userId});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  late Future<List<Map<String, dynamic>>> _decryptedEntries;

  @override
  void initState() {
    super.initState();
    _decryptedEntries = _loadDecryptedEntries();
  }

  Future<List<Map<String, dynamic>>> _loadDecryptedEntries() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('journals')
        .orderBy('createdAt', descending: true)
        .get();

    final decrypted = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final encryptedText = doc['text'] as String;
      final timestamp = doc['createdAt'] as Timestamp;
      final date = timestamp.toDate();
      final decryptedText = EncryptionHelper.decryptText(encryptedText);

      decrypted.add({
        'docRef': doc.reference,
        'text': decryptedText,
        'date': date,
      });
    }
    return decrypted;
  }

  void _refreshEntries() {
    setState(() {
      _decryptedEntries = _loadDecryptedEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Journal posts')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _decryptedEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No journal entries found.'));
          }

          final entries = snapshot.data!;
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final date = entry['date'] as DateTime;
              final formattedDate = "${date.day}/${date.month}/${date.year}";
              final decryptedText = entry['text'] as String;
              final docRef = entry['docRef'] as DocumentReference;

              return ListTile(
                title: Text(formattedDate),
                subtitle: Text(
                  decryptedText.length > 50
                      ? '${decryptedText.substring(0, 50)}...'
                      : decryptedText,
                ),
                trailing: Wrap(
                  spacing: 8.0,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility),
                      tooltip: 'View entry',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Entry - $formattedDate'),
                            content: SingleChildScrollView(
                              child: Text(decryptedText)
                            ),
                            actions: [
                               Tooltip(
                                message: 'Close',
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Icon(Icons.close),
                                ),
                              ),
                            ],
                            ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      tooltip: 'Edit entry',
                      onPressed: () {
                        final controller = TextEditingController(text: decryptedText);
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Edit Entry - $formattedDate'),
                            content: TextField(
                              controller: controller,
                              maxLines: null,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Journal Text',
                              ),
                            ),
                            actions: [
                             Tooltip(
                                message: 'Close',
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Icon(Icons.close),
                                ),
                              ),
                            
                            Tooltip(
                              message: 'Update entry',
                              child: ElevatedButton(
                                onPressed: () async {
                                  final newText = controller.text.trim();
                                  if (newText.isNotEmpty) {
                                    final encrypted = EncryptionHelper.encryptText(newText);
                                    await docRef.update({'text': encrypted});
                                    Navigator.pop(context);
                                    _refreshEntries();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(content: Text('Entry updated')),
                                    );
                                    
                                  }
                                },
                                child: Icon(Icons.save),
                              ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      tooltip: 'Delete entry',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Delete Entry'),
                            content: Text(
                                'Are you sure you want to delete this journal entry?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await docRef.delete();
                          _refreshEntries();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Entry deleted')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
