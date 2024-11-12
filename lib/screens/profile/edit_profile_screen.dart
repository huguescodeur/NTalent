import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _sportController;
  late TextEditingController _positionController;
  late TextEditingController _locationController;
  late TextEditingController _skillController;
  File? _imageFile;
  bool _isLoading = false;
  List<String> _skills = [];

  static const int maxCharacters = 150;
  int _remainingCharacters = maxCharacters;

  void _updateRemainingCharacters(String text) {
    setState(() {
      _remainingCharacters = maxCharacters - text.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _bioController = TextEditingController(text: widget.userData['bio']);
    _sportController = TextEditingController(text: widget.userData['sport']);
    _positionController =
        TextEditingController(text: widget.userData['position']);
    _locationController =
        TextEditingController(text: widget.userData['location']);
    _skillController = TextEditingController();
    _skills = List<String>.from(widget.userData['skills'] ?? []);

    _updateRemainingCharacters(_bioController.text);
    _bioController.addListener(() {
      _updateRemainingCharacters(_bioController.text);
    });
  }

  @override
  void dispose() {
    _bioController.removeListener(() {
      _updateRemainingCharacters(_bioController.text);
    });
    _nameController.dispose();
    _bioController.dispose();
    _sportController.dispose();
    _positionController.dispose();
    _locationController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return widget.userData['profileImage'];

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${widget.userId}.jpg');

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String? profileImageUrl = await _uploadImage();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'name': _nameController.text,
        'bio': _bioController.text,
        'sport': _sportController.text,
        'position': _positionController.text,
        'location': _locationController.text,
        'skills': _skills,
        if (profileImageUrl != null) 'profileImage': profileImageUrl,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSkillChips() {
    return Wrap(
      spacing: 8.0,
      children: _skills.map((skill) {
        return Chip(
          label: Text(skill),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _skills.remove(skill);
            });
          },
        );
      }).toList(),
    );
  }

  void _addSkill(String skill) {
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : NetworkImage(
                                        widget.userData['profileImage'] ??
                                            'https://via.placeholder.com/100')
                                    as ImageProvider,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _bioController,
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            border: const OutlineInputBorder(),
                            helperText:
                                '$_remainingCharacters caractères restants',
                            helperStyle: TextStyle(
                              color: _remainingCharacters < 20
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            suffixIcon: SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: (_bioController.text.length /
                                          maxCharacters),
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation(
                                        _remainingCharacters < 20
                                            ? Colors.red
                                            : _remainingCharacters < 50
                                                ? Colors.orange
                                                : Colors.blue,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                    Text(
                                      '${(_bioController.text.length / maxCharacters * 100).toInt()}%',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          maxLines: 3,
                          maxLength: maxCharacters,
                          buildCounter: (
                            context, {
                            required int currentLength,
                            required bool isFocused,
                            maxLength,
                          }) {
                            return null; // Cache le compteur par défaut
                          },
                          onChanged: (text) {
                            if (text.length > maxCharacters) {
                              _bioController.text =
                                  text.substring(0, maxCharacters);
                              _bioController.selection =
                                  TextSelection.collapsed(
                                      offset: maxCharacters);
                            }
                            _updateRemainingCharacters(_bioController.text);
                          },
                        ),
                      ],
                    ),
                    // TextFormField(
                    //   controller: _bioController,
                    //   decoration: InputDecoration(
                    //     labelText: 'Bio',
                    //     border: const OutlineInputBorder(),
                    //     helperText: '$_remainingWords mots restants',
                    //     helperStyle: TextStyle(
                    //       color:
                    //           _remainingWords < 10 ? Colors.red : Colors.grey,
                    //     ),
                    //     counterText:
                    //         '', // Cache le compteur de caractères par défaut
                    //   ),
                    //   // maxLines: 3,
                    //   onChanged: (text) {
                    //     final words = text
                    //         .trim()
                    //         .split(RegExp(r'\s+'))
                    //         .where((word) => word.isNotEmpty)
                    //         .length;
                    //     if (words > maxWords) {
                    //       // Si le nombre de mots dépasse la limite, on tronque le texte
                    //       final truncatedText = text
                    //           .trim()
                    //           .split(RegExp(r'\s+'))
                    //           .take(maxWords)
                    //           .join(' ');
                    //       _bioController.value = TextEditingValue(
                    //         text: truncatedText,
                    //         selection: TextSelection.collapsed(
                    //             offset: truncatedText.length),
                    //       );
                    //     }
                    //   },

                    //   validator: (value) {
                    //     if (value == null || value.isEmpty) return null;
                    //     final words = value
                    //         .trim()
                    //         .split(RegExp(r'\s+'))
                    //         .where((word) => word.isNotEmpty)
                    //         .length;
                    //     if (words > maxWords) {
                    //       return 'La bio ne peut pas dépasser $maxWords mots';
                    //     }
                    //     return null;
                    //   },
                    // ),
                    // TextFormField(
                    //   controller: _bioController,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Bio',
                    //     border: OutlineInputBorder(),
                    //   ),
                    //   maxLines: 3,
                    // ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sportController,
                      decoration: const InputDecoration(
                        labelText: 'Sport',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Position',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Localisation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skillController,
                            decoration: const InputDecoration(
                              labelText: 'Ajouter une compétence',
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (value) {
                              _addSkill(value);
                              _skillController.clear();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            _addSkill(_skillController.text);
                            _skillController.clear();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSkillChips(),
                  ],
                ),
              ),
            ),
    );
  }
}
