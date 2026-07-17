import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditFeedbackScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const EditFeedbackScreen({
    super.key,
    required this.docId,
    required this.currentData,
  });

  @override
  State<EditFeedbackScreen> createState() => _EditFeedbackScreenState();
}

class _EditFeedbackScreenState extends State<EditFeedbackScreen> {
  late TextEditingController _nameController;
  late TextEditingController _commentController;
  late TextEditingController _typeController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData['name']);
    _commentController = TextEditingController(
      text: widget.currentData['comment'],
    );
    // Naye controllers init kiye
    _typeController = TextEditingController(
      text: widget.currentData['type'] ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.currentData['category'] ?? '',
    );
  }

  Future<void> _updateFeedback() async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.docId)
        .update({
          'name': _nameController.text.trim(),
          'comment': _commentController.text.trim(),
          'type': _typeController.text.trim(),
          'category': _categoryController.text.trim(),
        });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Feedback")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: "Role (Type)"),
              ),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: "Reviewing for (Category)",
                ),
              ),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: "Comment"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateFeedback,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
