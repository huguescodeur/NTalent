import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/services/providers/get_user_infos_provider.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final String postId;
  final String description;
  final List<String> skills;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.description,
    required this.skills,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late TextEditingController _descriptionController;
  late List<String> _skills;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.description);
    _skills = List.from(widget.skills);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'description': _descriptionController.text,
        'skills': _skills,
      });

      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating post: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Widget> _buildSkillChips() {
    final user = ref.watch(userProvider);
    if (user == null || user.sport == null) return [];

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

  List<String> _getSkillsForSport(String sport) {
    // Même méthode que dans CreatePostScreen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updatePost,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
        ],
      ),
    );
  }
}
