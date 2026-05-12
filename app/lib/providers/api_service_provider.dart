import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';

/// AURA Social – API Service Provider
///
/// Global Riverpod provider cho AuraApiService singleton.
/// Tất cả services (FeedService, SoulService, etc.) đều inject từ đây.
final apiServiceProvider = Provider<AuraApiService>((ref) {
  return AuraApiService();
});
