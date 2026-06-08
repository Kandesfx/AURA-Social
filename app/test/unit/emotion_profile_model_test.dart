import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/models/emotion_profile_model.dart';

void main() {
  group('EmotionProfileModel', () {
    test('dominantEmotion returns highest value emotion', () {
      final model = EmotionProfileModel(
        currentEmotionVector: {
          'joy': 0.7, 'trust': 0.1, 'anticipation': 0.05,
          'surprise': 0.05, 'sadness': 0.05, 'fear': 0.02,
          'anger': 0.02, 'disgust': 0.01,
        },
        valence: 0.8,
      );
      expect(model.dominantEmotion, 'joy');
    });

    test('dominantEmotion returns first if all equal', () {
      final model = EmotionProfileModel(
        currentEmotionVector: EmotionProfileModel.defaultVector,
        valence: 0.0,
      );
      expect(model.dominantEmotion, 'joy');
    });

    test('hasData returns false when no inferences', () {
      final model = const EmotionProfileModel(totalInferences: 0);
      expect(model.hasData, false);
    });

    test('hasData returns true when has inferences and vector', () {
      final model = EmotionProfileModel(
        totalInferences: 5,
        currentEmotionVector: EmotionProfileModel.defaultVector,
      );
      expect(model.hasData, true);
    });

    test('emotionCounts returns from weeklyTrend if available', () {
      final model = EmotionProfileModel(
        weeklyTrend: {
          'emotion_counts': {'joy': 10, 'sadness': 3},
        },
      );
      expect(model.emotionCounts['joy'], 10);
      expect(model.emotionCounts['sadness'], 3);
    });

    test('moodTrendData returns day_0 when available', () {
      final model = EmotionProfileModel(
        valence: 0.5,
        weeklyTrend: {'day_0': 0.7, 'day_1': 0.6},
      );
      expect(model.moodTrendData['day_0'], 0.7);
    });

    test('moodTrendData fallback generates 7 days', () {
      final model = EmotionProfileModel(valence: 0.3);
      expect(model.moodTrendData.containsKey('day_6'), true);
    });
  });
}
