import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project/security/encryption_helper.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class JournalEntriesScreen extends StatefulWidget {
  final String userId;

  const JournalEntriesScreen({super.key, required this.userId});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  late Future<List<Map<String, dynamic>>> _decryptedEntries;
  final Set<int> _expandedImageIndices = {};

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
      try {
        final encryptedText = doc['text'] as String;
        final timestamp = doc['createdAt'] as Timestamp;
        final date = timestamp.toDate();
        final decryptedText = EncryptionHelper.decryptText(encryptedText);
        final imageUrls = doc.data().containsKey('image_urls')
            ? List<String>.from(doc['image_urls'])
            : [];

        decrypted.add({
          'docRef': doc.reference,
          'text': decryptedText,
          'date': date,
          'image_urls': imageUrls,
        });
      } catch (e) {
        print("Failed to decrypt entry ${doc.id}: $e");
      }
    }

    return decrypted;
  }

  void _refreshEntries() {
    setState(() {
      _decryptedEntries = _loadDecryptedEntries();
    });
  }

final PageController _pageController = PageController(viewportFraction: 0.98);
      Widget _buildImageSlideshow(List<String> imageUrls, {bool showDots = true, PageController? controller,}) {
        final usedController = controller ?? _pageController;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: usedController,
                itemCount: imageUrls.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrls[i],
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) =>
                            Center(child: Text('Image failed')),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (showDots) ...[
              SizedBox(height: 8),
              SmoothPageIndicator(
                controller: usedController,
                count: imageUrls.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 6,
                  activeDotColor: Theme.of(context).primaryColor,
                  dotColor: Colors.grey.shade400,
                ),
              ),
            ],
          ],
        );
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
              final imageUrls = (entry['image_urls'] ?? []).whereType<String>().toList();

              final isImageVisible = _expandedImageIndices.contains(index);
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formattedDate,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text(
                        decryptedText.length > 50
                            ? '${decryptedText.substring(0, 50)}...'
                            : decryptedText,
                      ),
                      if (imageUrls.isNotEmpty) ...[
                        TextButton.icon(
                          icon: Icon(
                            isImageVisible
                                ? Icons.expand_less
                                : Icons.image_outlined,
                          ),
                          label: Text(
                              isImageVisible ? 'Hide Images' : 'Show Images'),
                          onPressed: () {
                            setState(() {
                              if (isImageVisible) {
                                _expandedImageIndices.remove(index);
                              } else {
                                _expandedImageIndices.add(index);
                              }
                            });
                          },
                        ),
                        if (isImageVisible) _buildImageSlideshow(imageUrls),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.visibility),
                            tooltip: 'View entry',
                            onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) {
                              final PageController dialogController = PageController();

                              return Dialog(
                                insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Entry - $formattedDate',
                                          style: Theme.of(context).textTheme.titleMedium),
                                      SizedBox(height: 10),
                                      Text(decryptedText),
                                      if (imageUrls.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: _buildImageSlideshow(imageUrls,
                                              showDots: true, controller: dialogController),
                                        ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Icon(Icons.close),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            );
                          },

                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            tooltip: 'Edit entry',
                            onPressed: () {
                              final controller =
                                  TextEditingController(text: decryptedText);
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
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: Icon(Icons.close),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final newText =
                                            controller.text.trim();
                                        if (newText.isNotEmpty) {
                                          final encrypted =
                                              EncryptionHelper.encryptText(
                                                  newText);
                                          await docRef
                                              .update({'text': encrypted});
                                          Navigator.pop(context);
                                          _refreshEntries();
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Entry updated'),
                                            ),
                                          );
                                        }
                                      },
                                      child: Icon(Icons.save),
                                    ),
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
