import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AURA Social – API Service
///
/// HTTP client cho FastAPI AI Backend.
/// Auto-attach Firebase ID Token vào mỗi request.
///
/// Usage:
/// ```dart
/// final api = AuraApiService();
/// final response = await api.dio.post('/api/v1/soul/suggestions', data: {...});
/// ```
class AuraApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  late final Dio dio;

  AuraApiService() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor());
  }
}

/// Auto-attach Firebase ID Token
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: Force re-auth or refresh token
    }
    handler.next(err);
  }
}
