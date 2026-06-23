import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/ofg_theme.dart';

class LocalVideoPlayer extends StatefulWidget {
  final String url;
  final bool isShort;
  final bool shouldPlay;

  const LocalVideoPlayer({
    super.key, 
    required this.url, 
    this.isShort = false,
    this.shouldPlay = true,
  });

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showPauseIcon = false;
  bool _hasError = false;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(widget.isShort);
        if (widget.shouldPlay) {
          _controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(LocalVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized && widget.shouldPlay != oldWidget.shouldPlay) {
      if (widget.shouldPlay) {
        _controller.play();
      } else {
        _controller.pause();
        if (widget.isShort) {
          // Reset short to beginning when swiped away for instant replay later
          _controller.seekTo(Duration.zero); 
        }
      }
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showPauseIcon = true;
      } else {
        _controller.play();
        _showPauseIcon = true;
        _pauseTimer?.cancel();
        _pauseTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showPauseIcon = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white54, size: 40),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: kAccent),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: widget.isShort ? BoxFit.cover : BoxFit.contain,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          // Smooth fade-in to prevent visual stuttering when video loads
          AnimatedOpacity(
            opacity: _isInitialized ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(color: Colors.black),
          ),
          if (_showPauseIcon && !_controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.play_arrow, size: 50, color: Colors.white),
            ),
          if (_showPauseIcon && _controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.pause, size: 50, color: Colors.white),
            ),
        ],
      ),
    );
  }
}