import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'welcome_screen.dart';
import 'package:flutter_project/security/encryption_helper.dart';
class JournalScreen extends StatefulWidget {
  final String userId;
  final String? userEmail;
  final String? userName;

  const JournalScreen({super.key, required this.userId, this.userEmail, this.userName});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController journalController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _pickedImages = [];
  List<Uint8List> _imageBytesList = [];

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _pickedImages.add(image);
      _imageBytesList.add(bytes);
    });
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from library'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<String>> uploadImagesIfPresent() async {
    if (_pickedImages.isEmpty) return [];

    List<String> downloadUrls = [];
    final uid = FirebaseAuth.instance.currentUser!.uid;

    for (int i = 0; i < _pickedImages.length; i++) {
      final fileName = 'journal_images/$uid/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      try {
        final bytes = await _pickedImages[i].readAsBytes();
        await ref.putData(bytes);
        final url = await ref.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        print('Error uploading image $i: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image $i')),
        );
      }
    }

    return downloadUrls;
  }
void saveJournalEntry() async {
  final entry = journalController.text.trim();

  if (entry.isNotEmpty || _pickedImages.isNotEmpty) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final encryptedEntry = EncryptionHelper.encryptText(entry);
      final imageUrls = await uploadImagesIfPresent();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('journals')
          .add({
        'text': encryptedEntry,
        'image_urls': imageUrls,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry saved!')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              userEmail: widget.userEmail ?? '',
              username: widget.userName ?? '',
            ),
          ),
          (route) => false,
        );

        journalController.clear();
        setState(() {
          _pickedImages.clear();
          _imageBytesList.clear();
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Always close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving journal: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final previewImageWidget = _pickedImages.isEmpty
        ? SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_pickedImages.length, (index) {
                return Image.memory(_imageBytesList[index], height: 100);
              }),
            ),
          );

    return Scaffold(
      appBar: AppBar(title: Text('Your Journal')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: journalController,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText: 'How was your day?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showImageSourcePicker,
                            icon: Icon(Icons.photo_library),
                            label: Text('Add Image'),
                          ),
                          SizedBox(width: 10),
                          if (_pickedImages.isNotEmpty)
                            Text('${_pickedImages.length} image(s) selected',
                                style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      previewImageWidget,
                      Spacer(),
                      Center(
                        child: ElevatedButton(
                          onPressed: saveJournalEntry,
                          child: Text('Save Entry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
