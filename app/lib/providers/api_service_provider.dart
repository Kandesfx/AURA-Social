import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';

/// Global provider cho AuraApiService (singleton).
///
/// Tất cả các feature (Feed, Post, Profile, etc.) dùng provider này
/// để truy cập FastAPI backend.
///
/// ### Cách dùng:
/// ```dart
/// final api = ref.read(apiServiceProvider);
/// final response = await api.post('/api/v1/feed/generate', data: {...});
/// ```
final apiServiceProvider = Provider<AuraApiService>((ref) {
  return AuraApiService();
});
