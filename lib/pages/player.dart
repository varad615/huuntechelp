import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  final String videoTitle;

  VideoPlayerPage({required this.videoId, required this.videoTitle});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoTitle),
      ),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          onReady: () {
            _controller.addListener(() {});
          },
        ),
        builder: (context, player) {
          return Column(
            children: [
              player, // The YouTube player widget
              SizedBox(height: 10),
              Text(
                widget.videoTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }
}
