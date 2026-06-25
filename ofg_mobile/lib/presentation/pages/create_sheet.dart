// lib/presentation/pages/create_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../../api/api_client.dart';
import '../../logic/providers.dart';

class CreateSheet extends ConsumerStatefulWidget {
  const CreateSheet({super.key});

  @override
  ConsumerState<CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<CreateSheet> {
  int _step = 0; // 0 = menu, 1 = upload form

  bool _isShort = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'sermons';

  File? _thumbnailFile;
  File? _videoFile;
  int _videoSize = 0;
  String _videoDuration = '0:00';

  bool _uploading = false;
  bool _picking = false;
  double _progress = 0.0;       // 0.0 – 1.0
  String _statusMsg = '';       // shown below the progress bar

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  String _detectMime(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':  return 'video/mp4';
      case 'webm': return 'video/webm';
      case 'mov':  return 'video/quicktime';
      case 'avi':  return 'video/x-msvideo';
      case '3gp':  return 'video/3gpp';
      case 'mkv':  return 'video/x-matroska';
      default:     return 'video/mp4';
    }
  }

  void _setStatus(String msg, [double? progress]) {
    if (!mounted) return;
    setState(() {
      _statusMsg = msg;
      if (progress != null) _progress = progress.clamp(0.0, 1.0);
    });
  }

  /// Shows a persistent error dialog — unlike SnackBar it won't auto-dismiss
  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kPanel2,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Upload Failed', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SelectableText(
          message,
          style: const TextStyle(color: kMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }

  // ─── pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickThumbnail() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() => _thumbnailFile = File(picked.path));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.single.path != null && mounted) {
        final file = File(result.files.single.path!);
        final size = await file.length();
        
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        final duration = controller.value.duration;
        final mins = duration.inMinutes;
        final secs = duration.inSeconds % 60;
        final durationStr = '$mins:${secs.toString().padLeft(2, '0')}';
        await controller.dispose();

        setState(() { 
          _videoFile = file; 
          _videoSize = size; 
          _videoDuration = durationStr;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // ─── upload ─────────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title for your video.');
      return;
    }
    if (_videoFile == null) {
      _showError('Please select a video file.');
      return;
    }

    setState(() { _uploading = true; _progress = 0.02; _statusMsg = 'Preparing upload…'; });

    try {
      final api = ref.read(apiClientProvider);

      final videoPath     = _videoFile!.path;
      final videoMime     = _detectMime(videoPath);
      final videoFileName = videoPath.split('/').last;
      final videoSize     = _videoSize;

      // ── Phase 1: Upload video (0 → 70%) ──────────────────────────────────
      _setStatus('Uploading video to server… 0%', 0.05);

      final videoResult = await api.uploadViaProxy(
        _videoFile!,
        videoFileName,
        videoMime,
        type: _isShort ? 'short' : 'video',
        onProgress: (p) {
          final pct = (p * 100).toStringAsFixed(0);
          _setStatus(
            'Uploading video… $pct%  '
            '(${(p * videoSize / 1024 / 1024).toStringAsFixed(1)} / '
            '${(videoSize / 1024 / 1024).toStringAsFixed(1)} MB)',
            0.05 + p * 0.65,
          );
        },
      );
      final videoMediaUrl = videoResult['mediaUrl'] as String;

      // ── Phase 2: Thumbnail (70 → 85%) ─────────────────────────────────────
      _setStatus('Uploading thumbnail…', 0.70);
      String thumbnailUrl = '';
      if (_thumbnailFile != null) {
        final thumbResult = await api.uploadViaProxy(
          _thumbnailFile!,
          _thumbnailFile!.path.split('/').last,
          'image/jpeg',
          type: 'thumbnail',
          onProgress: (p) => _setStatus('Uploading thumbnail… ${(p * 100).toStringAsFixed(0)}%', 0.70 + p * 0.15),
        );
        thumbnailUrl = thumbResult['mediaUrl'] as String;
      }

      // ── Phase 3: Save metadata (85 → 100%) ────────────────────────────────
      _setStatus('Saving to database…', 0.87);
      await api.post('/upload', {
        'title':        _titleController.text.trim(),
        'description':  _descController.text.trim(),
        'category':     _category,
        'mediaUrl':     videoMediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'duration':     _videoDuration,
        'isShort':      _isShort,
      });

      _setStatus('Done!', 1.0);
      ref.invalidate(feedProvider);
      ref.invalidate(creatorVideosProvider);

      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Video published successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ));
      }
    } catch (e, stack) {
      debugPrint('Upload error: $e\n$stack');
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() { _uploading = false; _progress = 0; _statusMsg = ''; });
    }
  }

  // ─── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
          ),
          if (_step == 0) _buildMenu() else _buildForm(),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          const Text('Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(backgroundColor: kPanel2, child: Icon(Icons.upload, color: Colors.white)),
            title: const Text('Upload a Message'),
            onTap: () => setState(() { _step = 1; _isShort = false; }),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: kPanel2, child: Icon(Icons.play_arrow, color: Colors.white)),
            title: const Text('Create a Short'),
            subtitle: const Text('Vertical video less than 60s', style: TextStyle(fontSize: 12, color: kMuted)),
            onTap: () => setState(() { _step = 1; _isShort = true; }),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: kPanel2, child: Icon(Icons.sensors, color: Colors.white)),
            title: const Text('Go Live'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live streaming coming soon!')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Flexible(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── header ────────────────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _uploading ? null : () => setState(() => _step = 0),
                ),
                Text(
                  _isShort ? 'Upload Short' : 'Upload Message',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── fields ────────────────────────────────────────────────────────
            OfgInput(controller: _titleController, label: 'Title'),
            const SizedBox(height: 16),
            OfgInput(controller: _descController, label: 'Description', maxLines: 3),
            const SizedBox(height: 16),

            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: ofgPanelDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  dropdownColor: kPanel2,
                  items: kCategories
                      .where((c) => c != 'For You' && c != 'Live')
                      .map((c) => DropdownMenuItem(value: kCategoryApiMap[c]!, child: Text(c)))
                      .toList(),
                  onChanged: _uploading ? null : (v) => setState(() => _category = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── file pickers ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _uploading ? null : _pickThumbnail,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: kPanel2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                        image: _thumbnailFile != null
                            ? DecorationImage(image: FileImage(_thumbnailFile!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _thumbnailFile == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, color: kMuted),
                                SizedBox(height: 4),
                                Text('Add Thumbnail', style: TextStyle(color: kMuted, fontSize: 12)),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _uploading ? null : _pickVideo,
                    child: Container(
                      height: 100,
                      decoration: ofgPanelDecoration(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _videoFile != null ? Icons.check_circle : Icons.video_file,
                            color: _videoFile != null ? Colors.green : kMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _videoFile != null
                                ? '${(_videoSize / 1024 / 1024).toStringAsFixed(1)} MB selected'
                                : 'Select Video',
                            style: const TextStyle(color: kMuted, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── progress block (visible while uploading) ──────────────────────
            if (_uploading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _statusMsg,
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: kBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _progress >= 1.0 ? Colors.green : kAccent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── publish button ────────────────────────────────────────────────
            OfgPrimaryButton(
              label: _uploading ? 'Uploading…' : 'Publish',
              onTap: _uploading ? null : () => _publish(),
              loading: _uploading,
            ),
          ],
        ),
      ),
    );
  }
}