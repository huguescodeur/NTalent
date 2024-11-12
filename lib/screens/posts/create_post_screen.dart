import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nt/services/providers/get_user_infos_provider.dart';
import 'package:nt/widgets/video_preview.dart';
import 'package:video_compress/video_compress.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  File? _videoFile;
  final _descriptionController = TextEditingController();
  final _skills = <String>[];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          if (_videoFile != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isUploading ? null : _handlePost,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_videoFile == null)
            Center(
              child: ElevatedButton(
                onPressed: _pickVideo,
                child: const Text('Select Video'),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPreview(file: _videoFile!),
            ),
          const SizedBox(height: 16),
          if (_videoFile != null) ...[
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Share details about your skills...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Skills Shown (tap to select):'),
            Wrap(
              spacing: 8,
              children: _buildSkillChips(),
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSkillChips() {
    final user = ref.watch(userProvider);
    if (user == null) return [];

    final availableSkills = _getSkillsForSport(user.sport!);
    return availableSkills.map((skill) {
      final isSelected = _skills.contains(skill);
      return FilterChip(
        label: Text(skill),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _skills.add(skill);
            } else {
              _skills.remove(skill);
            }
          });
        },
      );
    }).toList();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videoFile = File(video.path);
      });
    }
  }

  Future<void> _handlePost() async {
    if (_videoFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Compress video
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        _videoFile!.path,
        quality: VideoQuality.MediumQuality,
      );

      if (mediaInfo?.file == null) throw Exception('Video compression failed');

      // Generate thumbnail
      final thumbnail = await VideoCompress.getFileThumbnail(_videoFile!.path);

      // Upload to Firebase Storage
      final user = ref.watch(userProvider);
      if (user == null) throw Exception('User not logged in');

      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      final batch = FirebaseFirestore.instance.batch();

      final videoRef = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child(user.id)
          .child('$postId.mp4');

      final thumbnailRef = FirebaseStorage.instance
          .ref()
          .child('thumbnails')
          .child(user.id)
          .child('$postId.jpg');

      // Upload compressed video and thumbnail
      await videoRef.putFile(mediaInfo!.file!);
      await thumbnailRef.putFile(thumbnail);

      // Get download URLs
      final videoUrl = await videoRef.getDownloadURL();
      final thumbnailUrl = await thumbnailRef.getDownloadURL();

      // Create post in Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).set({
        'id': postId,
        'userId': user.id,
        'description': _descriptionController.text,
        'videoUrl': videoUrl,
        'thumbnail': thumbnailUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'skills': _skills,
        'likes': [],
        'comments': [],
      });

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.id);
      batch.update(userRef, {
        'postsCount': FieldValue.increment(1),
      });

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  List<String> _getSkillsForSport(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return [
          'Shooting',
          'Dribbling',
          'Passing',
          'Defense',
          'Rebounds',
          'Court Vision',
        ];
      case 'football':
        return [
          'Passing',
          'Running',
          'Catching',
          'Blocking',
          'Defense',
          'Speed',
        ];
      case 'soccer':
        return [
          'Dribbling',
          'Shooting',
          'Passing',
          'Ball Control',
          'Headers',
          'Defense',
        ];
      default:
        return [];
    }
  }
}
