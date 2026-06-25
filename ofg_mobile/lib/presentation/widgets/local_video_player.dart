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
    _seekTimer?.cancel();
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

  void _seek(int seconds) {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition + Duration(seconds: seconds);
    _controller.seekTo(targetPosition);
    
    // Show visual feedback for seek
    setState(() {
      _seekText = seconds > 0 ? '+${seconds}s' : '${seconds}s';
      _isSeekingForward = seconds > 0;
      _showSeekFeedback = true;
    });
    
    _seekTimer?.cancel();
    _seekTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showSeekFeedback = false);
    });
  }

  String _seekText = '';
  bool _isSeekingForward = true;
  bool _showSeekFeedback = false;
  Timer? _seekTimer;

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
      onDoubleTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth / 2) {
          _seek(-10);
        } else {
          _seek(10);
        }
      },
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
          
          // Play/Pause icon feedback
          if (_showPauseIcon && !_controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.play_arrow, size: 50, color: Colors.white),
            ),
          if (_showPauseIcon && _controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.pause, size: 50, color: Colors.white),
            ),
            
          // Seek feedback (+10s / -10s)
          if (_showSeekFeedback)
            Positioned(
              left: _isSeekingForward ? null : 40,
              right: _isSeekingForward ? 40 : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSeekingForward ? Icons.fast_forward : Icons.fast_rewind,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _seekText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
          // Progress Bar at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: EdgeInsets.symmetric(vertical: widget.isShort ? 2 : 12),
              colors: const VideoProgressColors(
                playedColor: kAccent,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}