// lib/presentation/pages/create_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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

  bool _uploading = false;
  bool _picking = false;  // Guard against "already active" crash
  double _progress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _thumbnailFile = File(picked.path);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Detect MIME type from file extension
  String _mimeType(String path) {
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

  Future<void> _pickVideo() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final size = await file.length();
        setState(() {
          _videoFile = file;
          _videoSize = size;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a video file')));
      return;
    }

    setState(() { _uploading = true; _progress = 0.05; });

    try {
      final api = ref.read(apiClientProvider);

      // 1. Detect real MIME type from actual file extension
      final videoPath = _videoFile!.path;
      final videoMime = _mimeType(videoPath);
      final videoFileName = videoPath.split('/').last;

      // 2. Get presigned upload URL from our backend
      final videoInit = await api.initUpload(
        filename: videoFileName,
        contentType: videoMime,
        type: _isShort ? 'short' : 'video',
      );
      final videoUploadUrl = videoInit['uploadUrl'] as String;
      final videoMediaUrl  = videoInit['mediaUrl']  as String;

      setState(() => _progress = 0.1);

      // 3. STREAM video directly to R2 using the API Client
      await api.streamedUpload(videoUploadUrl, _videoFile!, videoMime);

      setState(() => _progress = 0.7);

      // 4. Thumbnail upload (optional)
      String thumbnailUrl = '';
      if (_thumbnailFile != null) {
        final thumbInit = await api.initUpload(
          filename: _thumbnailFile!.path.split('/').last,
          contentType: 'image/jpeg',
          type: 'thumbnail',
        );
        thumbnailUrl = thumbInit['mediaUrl'] as String;
        
        // STREAM thumbnail safely
        await api.streamedUpload(
            thumbInit['uploadUrl'] as String, _thumbnailFile!, 'image/jpeg');
      }

      setState(() => _progress = 0.85);

      // 5. Save video metadata to the backend database
      await api.submitUpload(
        title:        _titleController.text.trim(),
        description:  _descController.text.trim(),
        category:     _category,
        mediaUrl:     videoMediaUrl,
        thumbnailUrl: thumbnailUrl,
        duration:     '0:00',
        isShort:      _isShort,
      );

      setState(() => _progress = 1.0);
      ref.invalidate(feedProvider);
      ref.invalidate(creatorVideosProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Video published successfully! 🎉'),
                backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

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
            width: 40,
            height: 4,
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
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step = 0)),
                Text(_isShort ? 'Upload Short' : 'Upload Message', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            OfgInput(controller: _titleController, label: 'Title'),
            const SizedBox(height: 16),
            OfgInput(controller: _descController, label: 'Description', maxLines: 3),
            const SizedBox(height: 16),
            
            // Category Dropdown
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
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickThumbnail,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: kPanel2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                        image: _thumbnailFile != null ? DecorationImage(image: FileImage(_thumbnailFile!), fit: BoxFit.cover) : null,
                      ),
                      child: _thumbnailFile == null ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: kMuted),
                          SizedBox(height: 4),
                          Text('Add Thumbnail', style: TextStyle(color: kMuted, fontSize: 12)),
                        ],
                      ) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickVideo,
                    child: Container(
                      height: 100,
                      decoration: ofgPanelDecoration(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_videoFile != null ? Icons.check_circle : Icons.video_file, color: _videoFile != null ? Colors.green : kMuted),
                          const SizedBox(height: 4),
                          Text(_videoFile != null ? '${(_videoSize / 1024 / 1024).toStringAsFixed(1)} MB' : 'Select Video', style: const TextStyle(color: kMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            if (_uploading) ...[
              LinearProgressIndicator(value: _progress, backgroundColor: kBorder, color: kAccent),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toInt()}% uploaded...', textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
              const SizedBox(height: 16),
            ],
            OfgPrimaryButton(
              label: 'Publish',
              onTap: _publish,
              loading: _uploading,
            ),
          ],
        ),
      ),
    );
  }
}