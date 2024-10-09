import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:hunttechelp/pages/player.dart';

class YouTubePage extends StatefulWidget {
  @override
  _YouTubePageState createState() => _YouTubePageState();
}

class _YouTubePageState extends State<YouTubePage> {
  TextEditingController _searchController = TextEditingController();
  List _videos = [];
  List _filteredVideos = [];
  String _apiKey = 'AIzaSyCN47LtDXNy5pLIbNcarZqOgF3xtzN2L4w';
  String _channelId = 'UC8zteQuBHOUz4Ej1iomSgeQ';

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
        _filteredVideos = _videos; // Initialize with all videos
      });
    }
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
        title: Text('Videos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredVideos.length,
              itemBuilder: (context, index) {
                var video = _filteredVideos[index];
                var videoId = video['id']['videoId']; // Get the video ID
                var videoTitle =
                    video['snippet']['title']; // Get the video title
                return ListTile(
                  leading: Image.network(
                      video['snippet']['thumbnails']['default']['url']),
                  title: Text(videoTitle),
                  subtitle: Text(video['snippet']['channelTitle']),
                  onTap: () {
                    // Navigate to the video player page
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
