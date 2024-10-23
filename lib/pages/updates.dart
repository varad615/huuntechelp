import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  _UpdatesPageState createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  final DatabaseReference _updatesRef =
      FirebaseDatabase.instance.ref().child('updates');
  final List<Map<String, dynamic>> _updates = [];
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _fetchUpdates();
  }

  void _fetchUpdates() async {
    try {
      // Clear previous updates
      _updates.clear();

      // Get the data from Firebase
      final snapshot = await _updatesRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;

        // Parse the data into the desired structure
        data.forEach((key, value) {
          final updateData =
              Map<String, dynamic>.from(value as Map<Object?, Object?>);
          updateData['id'] = key; // Store the id in the data
          _updates.add(updateData);
        });
      }
    } catch (error) {
      print("Error fetching updates: $error");
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false after fetching data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates'),
        backgroundColor: const Color(0xFF51011A), // Maroon color
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading icon
          : _updates.isEmpty
              ? const Center(
                  child: Text('No updates available.')) // No data message
              : ListView.builder(
                  itemCount: _updates.length,
                  itemBuilder: (context, index) {
                    final update = _updates[index];
                    return Container(
                      // Use Container to apply margin
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text(update['text'] ?? 'No text available'),
                        subtitle:
                            Text(update['createdOn'] ?? 'No date available'),
                        contentPadding: const EdgeInsets.all(10),
                        tileColor:
                            Colors.grey[200], // Background color for the tile
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
