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
  static String get _baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // Android emulator dùng 10.0.2.2, iOS simulator / web / desktop dùng localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  late final Dio dio;

  AuraApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
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

  /// Upload file (multipart) with extended timeouts and retry logic.
  ///
  /// Uses longer timeouts (60s connect, 120s send/receive) compared to
  /// normal API calls, because file uploads can take significantly longer
  /// especially when going through FastAPI → Cloudflare R2.
  ///
  /// Retries up to [maxRetries] times on connection timeout.
  Future<Response> uploadFile(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraFields,
    void Function(int, int)? onSendProgress,
    int maxRetries = 2,
  }) async {
    debugPrint('[API Upload] POST $_baseUrl$path');
    debugPrint('[API Upload] File: $filePath');

    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      if (extraFields != null) ...extraFields,
    });

    DioException? lastError;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('[API Upload] Retry attempt $attempt/$maxRetries...');
          // Re-create FormData because Dio consumes the stream
          final retryFormData = FormData.fromMap({
            fieldName: await MultipartFile.fromFile(filePath),
            if (extraFields != null) ...extraFields,
          });
          final response = await dio.post(
            path,
            data: retryFormData,
            onSendProgress: onSendProgress,
            options: Options(
              headers: {'Content-Type': 'multipart/form-data'},
              sendTimeout: const Duration(seconds: 120),
              receiveTimeout: const Duration(seconds: 120),
            ),
          );
          debugPrint('[API Upload] Response status: ${response.statusCode}');
          debugPrint('[API Upload] Response data: ${response.data}');
          return response;
        } else {
          final response = await dio.post(
            path,
            data: formData,
            onSendProgress: onSendProgress,
            options: Options(
              headers: {'Content-Type': 'multipart/form-data'},
              sendTimeout: const Duration(seconds: 120),
              receiveTimeout: const Duration(seconds: 120),
            ),
          );
          debugPrint('[API Upload] Response status: ${response.statusCode}');
          debugPrint('[API Upload] Response data: ${response.data}');
          return response;
        }
      } on DioException catch (e) {
        lastError = e;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          debugPrint('[API Upload] Timeout on attempt $attempt: ${e.type}');
          if (attempt < maxRetries) {
            // Wait before retrying (exponential backoff)
            await Future.delayed(Duration(seconds: (attempt + 1) * 2));
            continue;
          }
        }
        debugPrint('[API Upload] FAILED: $e');
        debugPrint('[API Upload] Base URL: $_baseUrl');
        debugPrint('[API Upload] Tip: If running on a physical device, set API_URL to your machine\'s LAN IP');
        rethrow;
      } catch (e) {
        debugPrint('[API Upload] FAILED: $e');
        debugPrint('[API Upload] Base URL: $_baseUrl');
        debugPrint('[API Upload] Tip: If running on a physical device, set API_URL to your machine\'s LAN IP');
        rethrow;
      }
    }
    // Should not reach here, but just in case
    throw lastError ?? DioException(requestOptions: RequestOptions(path: path), message: 'Upload failed after $maxRetries retries');
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
