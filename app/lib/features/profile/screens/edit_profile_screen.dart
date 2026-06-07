import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../providers/user_profile_provider.dart';

/// AURA Social – Edit Profile Screen
///
/// Cho phép chỉnh sửa: displayName, username, bio, interests, avatar.
/// Avatar upload trực tiếp lên Firebase Storage.
/// Save → update Firestore users/{uid}.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  File? _newAvatar;
  String? _currentAvatarUrl;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, imageQuality: 85);
    if (picked != null) setState(() => _newAvatar = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final service = ref.read(userProfileServiceProvider);
      final userAsync = ref.read(currentUserProfileProvider);
      final user = userAsync.valueOrNull;
      if (user == null) return;

      String? avatarUrl = _currentAvatarUrl;

      // Upload avatar mới lên Firebase Storage (giống chat)
      if (_newAvatar != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('avatars/${user.uid}.jpg');
          final uploadTask = storageRef.putFile(
            _newAvatar!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final snapshot = await uploadTask;
          final newUrl = await snapshot.ref.getDownloadURL();
          avatarUrl = newUrl;
          debugPrint('[EditProfile] Avatar upload success, URL: $newUrl');
        } catch (e) {
          debugPrint('[EditProfile] Avatar upload exception: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('⚠️ Upload avatar thất bại: $e'),
              backgroundColor: AuraColors.warning,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }

      // Parse interests từ comma-separated string
      final interests = _interestsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Update profile
      await service.updateProfile(
        uid: user.uid,
        displayName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        interests: interests,
      );

      // Update avatar nếu có URL mới
      if (avatarUrl != null && avatarUrl != _currentAvatarUrl) {
        await service.updateAvatar(user.uid, avatarUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã cập nhật hồ sơ! ✅'),
          backgroundColor: AuraColors.success,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AuraColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20), minimumSize: const Size(0, 36)),
              child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Lưu'),
            )),
        ],
      ),
      body: userAsync.when(
        loading: () => const AuraLoadingWidget(),
        error: (e, _) => AuraErrorWidget(message: e.toString()),
        data: (user) {
          if (user == null) return const AuraErrorWidget(message: 'Không tìm thấy user');

          // Populate fields lần đầu
          if (!_initialized) {
            _nameCtrl.text = user.displayName;
            _usernameCtrl.text = user.username;
            _bioCtrl.text = user.bio ?? '';
            _interestsCtrl.text = user.interests.join(', ');
            _currentAvatarUrl = user.avatarUrl;
            _initialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(key: _formKey, child: Column(children: [
              // ── Avatar ──
              GestureDetector(
                onTap: _saving ? null : _pickAvatar,
                child: Stack(children: [
                  AuraRing(
                    size: 100,
                    imageUrl: _newAvatar == null ? user.avatarUrl : null,
                    glowIntensity: 0.3,
                    child: _newAvatar != null
                        ? ClipOval(child: Image.file(_newAvatar!, fit: BoxFit.cover, width: 88, height: 88))
                        : null,
                  ),
                  Positioned(bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AuraColors.primary, shape: BoxShape.circle, border: Border.all(color: AuraColors.background, width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    )),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Display Name ──
              TextFormField(
                controller: _nameCtrl, enabled: !_saving,
                style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Tên hiển thị', prefixIcon: Icon(Icons.person_outline, size: 20)),
                validator: (v) => v == null || v.trim().length < 2 ? 'Tên tối thiểu 2 ký tự' : null,
              ),
              const SizedBox(height: 16),

              // ── Username ──
              TextFormField(
                controller: _usernameCtrl, enabled: !_saving,
                style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email, size: 20)),
                validator: (v) => v == null || v.trim().length < 3 ? 'Username tối thiểu 3 ký tự' : null,
              ),
              const SizedBox(height: 16),

              // ── Bio ──
              TextFormField(
                controller: _bioCtrl, enabled: !_saving, maxLines: 3, maxLength: 150,
                style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Giới thiệu', prefixIcon: Icon(Icons.edit_note, size: 20), alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),

              // ── Interests ──
              TextFormField(
                controller: _interestsCtrl, enabled: !_saving,
                style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Sở thích (phân cách bằng dấu phẩy)', prefixIcon: Icon(Icons.tag, size: 20),
                  hintText: 'music, coding, travel'),
              ),
              const SizedBox(height: 32),
            ])),
          );
        },
      ),
    );
  }
}
