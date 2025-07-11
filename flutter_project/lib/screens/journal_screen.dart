import 'dart:typed_data';
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

  const JournalScreen({super.key, required this.userId, this.userEmail});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController journalController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _pickedImages = [];
  List<Uint8List> _imageBytesList = [];

  Future<void> pickImages() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImages.add(image);
        _imageBytesList.add(bytes);
      });
    }
  }

  Future<List<String>> uploadImagesIfPresent() async {
    if (_pickedImages.isEmpty) return [];

    List<String> downloadUrls = [];

    for (int i = 0; i < _pickedImages.length; i++) {
      final fileName = 'journal_images/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Journal entry saved!')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(userEmail: widget.userEmail ?? ''),
        ),
        (route) => false,
      );

      journalController.clear();
      setState(() {
        _pickedImages.clear();
        _imageBytesList.clear();
      });
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
                            onPressed: pickImages,
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