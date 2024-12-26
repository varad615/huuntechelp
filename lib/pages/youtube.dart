import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hunttechelp/pages/player.dart';
import 'package:hunttechelp/pages/history.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YouTubePage extends StatefulWidget {
  const YouTubePage({super.key});

  @override
  _YouTubePageState createState() => _YouTubePageState();
}

class _YouTubePageState extends State<YouTubePage> {
  final TextEditingController _searchController = TextEditingController();
  List _videos = [];
  List _filteredVideos = [];
  final String _apiKey = 'AIzaSyAjCLRtoyb-DXSDduFnEYfKygQOSyvHlDo';
  final String _channelId = 'UCyi9lNn1XWLsK0Wcs983Hww';

  @override
  void initState() {
    super.initState();
    fetchVideos();
    _searchController.addListener(_filterVideos);
  }

  Future<void> fetchVideos() async {
    String url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$_channelId&type=video&maxResults=20&key=$_apiKey';

    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        _videos = data['items'];
        _filteredVideos = _videos;
      });
    }
  }

  Future<void> _storeVideoInHistory(
      String videoId, String title, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final String timestamp = DateTime.now().toIso8601String();

    Map<String, dynamic> videoEntry = {
      'id': videoId,
      'title': title,
      'description': description,
      'timestamp': timestamp,
    };

    // Debugging message
    print("Storing video with ID: $videoId to history");

    List<String> history = prefs.getStringList('videoHistory') ?? [];
    history.add(jsonEncode(videoEntry));
    await prefs.setStringList('videoHistory', history);

    // Confirm storage
    print("Video stored: ${jsonEncode(videoEntry)}");
  }

  void _filterVideos() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVideos = _videos.where((video) {
        var title = video['snippet']['title'].toLowerCase();
        return title.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Video Tutorials',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            color: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredVideos.length,
              itemBuilder: (context, index) {
                var video = _filteredVideos[index];
                var videoId = video['id']['videoId'];
                var videoTitle = video['snippet']['title'];
                var videoDescription = video['snippet']['description'];
                var thumbnailUrl =
                    video['snippet']['thumbnails']['high']['url'];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: InkWell(
                    onTap: () async {
                      // Debugging message
                      print("Tapped on video with ID: $videoId");

                      // Save video data to history only if not accessed from history
                      await _storeVideoInHistory(
                          videoId, videoTitle, videoDescription);

                      // Debugging message
                      print(
                          "Navigating to VideoPlayerPage for video ID: $videoId");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerPage(
                            videoId: videoId,
                            videoTitle: videoTitle,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                thumbnailUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            videoTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            videoDescription,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
