import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// AURA Social – API Service
///
/// HTTP client kết nối Flutter → FastAPI backend.
/// Tự động gắn Firebase ID Token vào mọi request.
///
/// ### Cách dùng:
/// ```dart
/// final api = ref.read(apiServiceProvider);
/// final response = await api.post('/api/v1/feed/generate', data: {...});
/// ```
class AuraApiService {
  /// Base URL của FastAPI backend (Cloud Run hoặc localhost)
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator → host machine
  );

  late final Dio dio;

  AuraApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor 1: Tự động gắn Firebase token
    dio.interceptors.add(_AuthInterceptor());

    // Interceptor 2: Logging (chỉ trong debug mode)
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[API] $obj'),
        ),
      );
    }
  }

  // ── Convenience methods ──

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get(path, queryParameters: queryParameters);
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.post(path, data: data, queryParameters: queryParameters);
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
  }) {
    return dio.put(path, data: data);
  }

  /// DELETE request
  Future<Response> delete(String path) {
    return dio.delete(path);
  }

  /// Upload file (multipart)
  Future<Response> uploadFile(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraFields,
    void Function(int, int)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      if (extraFields != null) ...extraFields,
    });

    return dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
  }
}

/// Interceptor tự động gắn Firebase ID Token vào header Authorization.
///
/// Mọi request gửi đến FastAPI đều cần Bearer token để xác thực.
/// Token được lấy từ `FirebaseAuth.instance.currentUser.getIdToken()`.
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        options.headers['Authorization'] = 'Bearer $token';
      } catch (e) {
        debugPrint('[AuthInterceptor] Failed to get token: $e');
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired hoặc invalid → force refresh token
      debugPrint('[AuthInterceptor] 401 Unauthorized – token may be expired');
      // Có thể trigger sign out hoặc refresh token ở đây
      // FirebaseAuth.instance.currentUser?.getIdToken(true); // force refresh
    }
    handler.next(err);
  }
}
