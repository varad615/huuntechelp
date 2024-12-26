import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:hunttechelp/pages/player.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _videoHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('videoHistory') ?? [];

    // Decode each video entry and store it in _videoHistory
    setState(() {
      _videoHistory = history.map((video) {
        return Map<String, dynamic>.from(jsonDecode(video));
      }).toList();
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('videoHistory');
    setState(() {
      _videoHistory.clear();
    });
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to clear your video history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _clearHistory();
              Navigator.pop(context); // Close dialog after clearing history
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  String _formatDate(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('MMM dd, yyyy, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmClearHistory, // Show confirmation dialog
          ),
        ],
      ),
      body: _videoHistory.isEmpty
          ? const Center(child: Text("No history available"))
          : ListView.builder(
              itemCount: _videoHistory.length,
              itemBuilder: (context, index) {
                var video = _videoHistory[index];
                var title = video['title'];
                var description = video['description'];
                var timestamp = _formatDate(video['timestamp']);
                var videoId = video['id'];
                
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerPage(
                          videoId: videoId,
                          videoTitle: title,
                        ),
                      ),
                    );
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      'https://img.youtube.com/vi/$videoId/0.jpg',
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Last seen: $timestamp',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
