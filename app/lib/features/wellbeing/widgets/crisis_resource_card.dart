import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Crisis Resource Card
///
/// Person 4, Task #9 (Trung bình)
/// Card hỗ trợ khẩn cấp hiển thị khi hệ thống phát hiện trạng thái khủng hoảng tâm lý (crisis_detected = true).
/// Thiết kế Glassmorphism sang trọng với các hotline hỗ trợ sức khỏe tinh thần tại Việt Nam.
class CrisisResourceCard extends StatelessWidget {
  const CrisisResourceCard({
    super.key,
    this.onDismiss,
    this.onStartAnonymousChat,
    this.onCallHotline,
    this.customHotlineName = 'Đường dây nóng Ngày Mai',
    this.customHotlinePhone = '0963061414',
  });

  final VoidCallback? onDismiss;
  final VoidCallback? onStartAnonymousChat;
  final VoidCallback? onCallHotline;
  final String customHotlineName;
  final String customHotlinePhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3A1C2A), // Màu đỏ/tím đậm nhẹ nhàng, giảm stress
            const Color(0xFF1F0D16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AuraColors.error.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AuraColors.error.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với Icon và Tiêu đề
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AuraColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('💜', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chúng mình luôn ở đây vì bạn',
                      style: AuraTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hỗ trợ khủng hoảng tâm lý',
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Nội dung chia sẻ, trấn an
          Text(
            'Nếu bạn đang cảm thấy quá tải, mệt mỏi hoặc cần một ai đó lắng nghe, xin đừng chịu đựng một mình. Hãy kết nối với các dịch vụ hỗ trợ miễn phí và bảo mật dưới đây.',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Thông tin hotline hỗ trợ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customHotlineName,
                        style: AuraTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hotline: $customHotlinePhone (Miễn phí)',
                        style: AuraTypography.bodySmall.copyWith(
                          color: AuraColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onCallHotline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                  label: Text(
                    'Gọi Ngay',
                    style: AuraTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Các nút hành động khác
          Row(
            children: [
              if (onStartAnonymousChat != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStartAnonymousChat,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AuraColors.secondary,
                      side: BorderSide(
                        color: AuraColors.secondary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.question_answer_rounded, size: 16),
                    label: Text(
                      'Chat Ẩn Danh',
                      style: AuraTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: AuraColors.textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Để sau',
                    style: AuraTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
