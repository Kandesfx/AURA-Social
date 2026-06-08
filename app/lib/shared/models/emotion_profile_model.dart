import 'package:cloud_firestore/cloud_firestore.dart';

/// AURA Social – Emotion Profile Model
///
/// Model cho subcollection `users/{userId}/emotion_profile/current`.
/// Chứa emotion vector 8D (Plutchik), meta-dimensions, behavioral signals,
/// weekly patterns, và inference metadata.
///
/// ### Firestore path: `/users/{userId}/emotion_profile/current`
///
/// Document này được cập nhật liên tục bởi Emotion Inference Engine (FastAPI)
/// thông qua Cloud Functions. Client chỉ đọc (read-only).
class EmotionProfileModel {
  /// Emotion vector 8D theo mô hình Plutchik
  /// Keys: joy, trust, anticipation, surprise, sadness, fear, anger, disgust
  /// Values: 0.0 – 1.0 (tổng = 1.0)
  final Map<String, double> currentEmotionVector;

  // Meta-dimensions
  /// Valence: -1.0 (tiêu cực) → +1.0 (tích cực)
  final double valence;

  /// Arousal: 0.0 (bình tĩnh) → 1.0 (phấn khích)
  final double arousal;

  /// Dominance: 0.0 (thụ động) → 1.0 (chủ động)
  final double dominance;

  // Inference metadata
  /// Độ tin cậy của inference (0.0 – 1.0)
  final double emotionConfidence;

  /// Nguồn inference: "inferred" | "expressed" | "hybrid"
  final String emotionSource;

  /// Emotional mode hiện tại: gentle_uplift | empathetic_mirror | amplify | deep_chill | explore
  final String emotionalMode;

  /// Các signal đã sử dụng cho inference
  final List<String> signalsUsed;

  // Behavioral fingerprint
  final Map<String, dynamic> behaviorSignals;

  // Weekly pattern
  final Map<String, dynamic> weeklyPattern;

  // Weekly trend
  final Map<String, dynamic> weeklyTrend;

  // Timestamps
  final DateTime? updatedAt;
  final DateTime? lastCalibrationAt;
  final DateTime? firstInferenceAt;
  final int totalInferences;

  const EmotionProfileModel({
    this.currentEmotionVector = const {},
    this.valence = 0.0,
    this.arousal = 0.0,
    this.dominance = 0.5,
    this.emotionConfidence = 0.0,
    this.emotionSource = 'inferred',
    this.emotionalMode = 'explore',
    this.signalsUsed = const [],
    this.behaviorSignals = const {},
    this.weeklyPattern = const {},
    this.weeklyTrend = const {},
    this.updatedAt,
    this.lastCalibrationAt,
    this.firstInferenceAt,
    this.totalInferences = 0,
  });

  /// Tạo từ Firestore DocumentSnapshot
  factory EmotionProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmotionProfileModel(
      currentEmotionVector: _parseVector(data['current_emotion_vector']),
      valence: (data['valence'] ?? 0.0).toDouble(),
      arousal: (data['arousal'] ?? 0.0).toDouble(),
      dominance: (data['dominance'] ?? 0.5).toDouble(),
      emotionConfidence: (data['emotion_confidence'] ?? 0.0).toDouble(),
      emotionSource: data['emotion_source'] ?? 'inferred',
      emotionalMode: data['emotional_mode'] ?? 'explore',
      signalsUsed: List<String>.from(data['signals_used'] ?? []),
      behaviorSignals: Map<String, dynamic>.from(data['behavior_signals'] ?? {}),
      weeklyPattern: Map<String, dynamic>.from(data['weekly_pattern'] ?? {}),
      weeklyTrend: Map<String, dynamic>.from(data['weekly_trend'] ?? {}),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      lastCalibrationAt: (data['last_calibration_at'] as Timestamp?)?.toDate(),
      firstInferenceAt: (data['first_inference_at'] as Timestamp?)?.toDate(),
      totalInferences: data['total_inferences'] ?? 0,
    );
  }

  /// Parse emotion vector an toàn
  static Map<String, double> _parseVector(dynamic raw) {
    if (raw == null) return defaultVector;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
    return defaultVector;
  }

  /// Default emotion vector (đều nhau)
  static const Map<String, double> defaultVector = {
    'joy': 0.125, 'trust': 0.125, 'anticipation': 0.125, 'surprise': 0.125,
    'sadness': 0.125, 'fear': 0.125, 'anger': 0.125, 'disgust': 0.125,
  };

  /// Cảm xúc dominant (cao nhất trong vector)
  String get dominantEmotion {
    if (currentEmotionVector.isEmpty) return 'explore';
    final sorted = currentEmotionVector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// Mood text mô tả (cho UI)
  String get moodDescription {
    if (valence > 0.5) return 'Đang rất tích cực 🌟';
    if (valence > 0.2) return 'Đang vui vẻ 😊';
    if (valence > -0.2) return 'Bình thường 😌';
    if (valence > -0.5) return 'Hơi buồn 😔';
    return 'Đang cần được động viên 💙';
  }

  /// Kiểm tra đã có dữ liệu inference chưa
  bool get hasData => totalInferences > 0 && currentEmotionVector.isNotEmpty;

  /// Emotion counts cho distribution chart (7 ngày)
  /// Lấy từ weeklyTrend['emotion_counts'] hoặc tính từ weeklyPattern
  Map<String, int> get emotionCounts {
    if (weeklyTrend.containsKey('emotion_counts') &&
        weeklyTrend['emotion_counts'] is Map) {
      final raw = weeklyTrend['emotion_counts'] as Map;
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    // Fallback: estimate từ current vector * 7 days
    return currentEmotionVector.map(
      (k, v) => MapEntry(k, (v * 7).round().clamp(0, 100)),
    );
  }

  /// Weekly data cho mood trend chart (valence theo ngày)
  Map<String, dynamic> get moodTrendData {
    if (weeklyTrend.containsKey('day_0')) {
      return Map<String, dynamic>.from(weeklyTrend);
    }
    // Fallback: trả về 7 ngày mặc định
    return {
      'day_0': valence,
      'day_1': valence * 0.9,
      'day_2': valence * 0.85,
      'day_3': valence * 0.8,
      'day_4': valence * 0.9,
      'day_5': valence * 0.95,
      'day_6': valence,
    };
  }
}
