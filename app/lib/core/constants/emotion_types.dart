/// AURA Social – Emotion Types
///
/// 8 cảm xúc cơ bản theo mô hình Plutchik's Wheel of Emotions
enum EmotionType {
  joy('joy', '😊', 'Vui vẻ'),
  trust('trust', '🤝', 'Tin tưởng'),
  anticipation('anticipation', '🎯', 'Kỳ vọng'),
  surprise('surprise', '😮', 'Bất ngờ'),
  sadness('sadness', '😢', 'Buồn'),
  fear('fear', '😰', 'Lo lắng'),
  anger('anger', '😠', 'Tức giận'),
  disgust('disgust', '🤢', 'Ghê tởm');

  const EmotionType(this.key, this.emoji, this.labelVi);

  final String key;
  final String emoji;
  final String labelVi;

  /// Tạo default emotion vector (đều nhau)
  static Map<String, double> defaultVector() {
    return {for (final e in values) e.key: 0.125};
  }
}

/// 5 Emotional Modes – quyết định loại content hiển thị
enum EmotionalMode {
  gentleUplift('gentle_uplift', '🌤️', 'Nâng đỡ nhẹ nhàng'),
  empatheticMirror('empathetic_mirror', '🪞', 'Đồng cảm'),
  amplify('amplify', '🚀', 'Khuếch đại'),
  deepChill('deep_chill', '🌙', 'Thư giãn sâu'),
  explore('explore', '🧭', 'Khám phá');

  const EmotionalMode(this.key, this.emoji, this.labelVi);

  final String key;
  final String emoji;
  final String labelVi;
}
