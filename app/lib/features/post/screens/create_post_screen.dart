import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/emotion_types.dart';

/// AURA Social – Create Post Screen (Fullscreen, no bottom nav)
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  String? _selectedMood;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _contentController.text.isEmpty ? null : () {},
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Post'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AuraTypography.bodyLarge.copyWith(
                  color: AuraColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Bạn đang nghĩ gì?...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: AuraTypography.bodyLarge.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // ── Optional Mood Expression ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AuraColors.surface,
              border: Border(
                top: BorderSide(color: AuraColors.surfaceBorder, width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Express your mood (optional)',
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: EmotionType.values.map((emotion) {
                      final isSelected = _selectedMood == emotion.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedMood = isSelected ? null : emotion.key;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AuraColors.getEmotionColor(emotion.key)
                                      .withValues(alpha: 0.15)
                                  : AuraColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(24),
                              border: isSelected
                                  ? Border.all(
                                      color: AuraColors.getEmotionColor(
                                          emotion.key).withValues(alpha: 0.5),
                                    )
                                  : Border.all(
                                      color: AuraColors.surfaceBorder,
                                      width: 0.5,
                                    ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emotion.emoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  emotion.labelVi,
                                  style: AuraTypography.labelSmall.copyWith(
                                    color: isSelected
                                        ? AuraColors.getEmotionColor(emotion.key)
                                        : AuraColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Toolbar
                Row(
                  children: [
                    _ToolButton(
                      icon: Icons.image_outlined,
                      label: 'Photo',
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _ToolButton(
                      icon: Icons.gif_box_outlined,
                      label: 'GIF',
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _ToolButton(
                      icon: Icons.poll_outlined,
                      label: 'Poll',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AuraColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AuraColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
