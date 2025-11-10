import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../core/constants/colors.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final user = authVM.currentUser;
    if (user != null) {
      _fullNameCtrl.text = user.fullName;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phoneNumber;
      // avatar is managed via local _avatarFile preview and current user url
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final userVM = Provider.of<UserViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar preview + change button
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : (authVM.currentUser?.profilePictureUrl != null
                          ? NetworkImage(authVM.currentUser!.profilePictureUrl!)
                          : null) as ImageProvider<Object>?,
                  child: (_avatarFile == null && authVM.currentUser?.profilePictureUrl == null)
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (picked != null) {
                      setState(() => _avatarFile = File(picked.path));
                    }
                  },
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: Text('Change Avatar', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _input('Fullname', _fullNameCtrl),
            const SizedBox(height: 12),
            _input('Email', _emailCtrl),
            const SizedBox(height: 12),
            _input('Phone Number', _phoneCtrl),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final jwt = authVM.jwtToken;
                        if (jwt == null || jwt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again')),
      );
                          return;
                        }
                        setState(() => _saving = true);
                        String? avatarKey;
                        if (_avatarFile != null) {
                          avatarKey = await userVM.uploadAvatarFromFile(jwt: jwt, file: _avatarFile!);
                          if (avatarKey == null) {
                            if (!mounted) return; 
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar upload failed')));
                          }
                        }
                        final updated = await userVM.updateProfile(
                          jwt: jwt,
                          fullName: _fullNameCtrl.text.trim(),
                          phoneNumber: _phoneCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                          profilePictureUrl: avatarKey,
                        );
                        setState(() => _saving = false);
                        if (updated != null) {
                          if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
                          Navigator.of(context).pop();
                        } else {
                          if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed')),
      );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
            : Text('Save', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.purpleAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}