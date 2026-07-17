import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _searchQuery = "";
  int _filterRating = 0;

  void _showEditDialog(
    BuildContext context,
    String docId,
    String name,
    String email,
    String comment,
  ) {
    final n = TextEditingController(text: name);
    final e = TextEditingController(text: email);
    final c = TextEditingController(text: comment);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: n,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: e,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: c,
              decoration: const InputDecoration(labelText: 'Review'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(docId)
                  .update({
                    'name': n.text.trim(),
                    'email': e.text.trim(),
                    'comment': c.text.trim(),
                  });
              if (!context.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(docId)
                  .delete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(List<QueryDocumentSnapshot> docs) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            children: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return pw.Text(
                "${data['name']} (${data['type']}/${data['category']}): ${data['comment']}",
              );
            }).toList(),
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['name'] ?? "").toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) &&
                (_filterRating == 0 || (data['rating'] ?? 0) == _filterRating);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    _buildStatCard('Total', '${docs.length}', Colors.blue),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Avg',
                      (docs.isEmpty
                              ? 0
                              : docs.fold(
                                      0.0,
                                      (s, d) =>
                                          s +
                                          ((d.data() as Map)['rating'] ?? 0.0),
                                    ) /
                                    docs.length)
                          .toStringAsFixed(1),
                      Colors.amber,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: _filterRating,
                      items: [0, 1, 2, 3, 4, 5]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e == 0 ? 'All' : '$e⭐'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _filterRating = v!),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.blue.shade200, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        title: Text(
                          d['name'] ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Yahan Role aur Category add ho gaya
                            Text(
                              "${d['type'] ?? 'N/A'} | ${d['category'] ?? 'N/A'}",
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(d['comment'] ?? ''),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(
                                context,
                                docs[i].id,
                                d['name'],
                                d['email'],
                                d['comment'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteDialog(context, docs[i].id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _exportPdf(docs),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Export as PDF"),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String t, String v, Color c) => Expanded(
    child: Card(
      color: c.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              v,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}
