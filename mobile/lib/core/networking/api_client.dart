import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../../shared/models/models.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient? _testClient;
  factory ApiClient() => _testClient ?? _instance;

  @visibleForTesting
  static void useForTesting(ApiClient? client) => _testClient = client;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<bool>? _refreshing;
  bool _persistSession = true;
  Map<String, String>? _memorySession;
  final ValueNotifier<int> changes = ValueNotifier(0);

  void notifyChanged() => changes.value++;

  Future<void> _saveSession(dynamic data) async {
    if (!_persistSession) {
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
      _memorySession = {
        'jwt_token': data['accessToken'],
        'refresh_token': data['refreshToken']
      };
      return;
    }
    _memorySession = null;
    await _storage.write(key: 'jwt_token', value: data['accessToken']);
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);
  }

  Future<String?> _credential(String key) async =>
      _memorySession?[key] ?? await _storage.read(key: key);

  Future<bool> _refresh() async {
    final token = await _credential('jwt_token');
    final refreshToken = await _credential('refresh_token');
    if (token == null || refreshToken == null) return false;
    try {
      final res = await _dio.post(ApiConstants.authRefresh,
          data: {'accessToken': token, 'refreshToken': refreshToken});
      await _saveSession(res.data['data']);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        await _clearSession();
      }
      return false;
    }
  }

  Future<void> _clearSession() async {
    _memorySession = null;
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data['message'] is String) return data['message'];
        if (data['errors'] is Map) {
          return (data['errors'] as Map)
              .values
              .expand((v) => v is List ? v : [v])
              .join(' ');
        }
      }
      if (error.response?.statusCode == 401) {
        return 'Inicia sesión para continuar.';
      }
      if (error.response?.statusCode == 429) {
        return 'Espera un momento antes de volver a intentarlo.';
      }
      return 'No se pudo conectar. Revisa tu conexión y vuelve a intentar.';
    }
    return 'No se pudo completar la operación.';
  }

  @visibleForTesting
  ApiClient.forTesting(HttpClientAdapter adapter)
      : this._internal(adapter: adapter);

  ApiClient._internal({HttpClientAdapter? adapter}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    if (adapter != null) _dio.httpClientAdapter = adapter;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _credential('jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode == 401 &&
              !request.path.startsWith('/auth/') &&
              request.extra['retried'] != true) {
            _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
            if (await _refreshing!) {
              try {
                request.extra['retried'] = true;
                if (request.data is FormData) {
                  request.data = (request.data as FormData).clone();
                }
                return handler.resolve(await _dio.fetch(request));
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password,
      {bool remember = true}) async {
    try {
      final res = await _dio.post(
        ApiConstants.authLogin,
        data: {'email': email, 'password': password},
      );
      if (res.data['success'] == true) {
        _persistSession = remember;
        await _saveSession(res.data['data']);
        return {'success': true, 'data': res.data['data']};
      }
      return {
        'success': false,
        'message': res.data['message'] ?? 'Credenciales inválidas'
      };
    } on DioException catch (e) {
      final msg = errorMessage(e);
      return {'success': false, 'message': msg};
    } catch (_) {
      return {'success': false, 'message': 'Ocurrió un error inesperado'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? province,
    String? municipality,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.authRegister,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'province': province,
          'municipality': municipality,
        },
      );
      if (res.data['success'] == true) {
        await _saveSession(res.data['data']);
        return {'success': true, 'data': res.data['data']};
      }
      return {
        'success': false,
        'message': res.data['message'] ?? 'Error al registrar'
      };
    } on DioException catch (e) {
      final msg = errorMessage(e);
      return {'success': false, 'message': msg};
    } catch (_) {
      return {'success': false, 'message': 'Ocurrió un error inesperado'};
    }
  }

  Future<bool> loginWithGoogle(String idToken) async {
    try {
      final res = await _dio.post('/auth/google', data: {'idToken': idToken});
      if (res.data['success'] == true) {
        await _saveSession(res.data['data']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loginWithApple(String identityToken) async {
    try {
      final res = await _dio
          .post('/auth/apple', data: {'identityToken': identityToken});
      if (res.data['success'] == true) {
        await _saveSession(res.data['data']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {/* Clear local credentials even when offline. */}
    await _clearSession();
    notifyChanged();
  }

  Future<Map<String, dynamic>> recoverPassword(String email) =>
      _authAction('/auth/forgot-password', {'email': email});
  Future<Map<String, dynamic>> resetPassword(String token, String password) =>
      _authAction(
          '/auth/reset-password', {'token': token, 'password': password});
  Future<Map<String, dynamic>> _authAction(
      String path, Map<String, dynamic> data) async {
    try {
      return Map<String, dynamic>.from(
          (await _dio.post(path, data: data)).data);
    } catch (e) {
      return {'success': false, 'message': errorMessage(e)};
    }
  }

  Future<void> updateProfile({
    String? avatarUrl,
    String? displayName,
    String? username,
    String? province,
    String? municipality,
  }) async {
    await _dio.patch(ApiConstants.usersMe, data: {
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (displayName != null) 'displayName': displayName,
      if (username != null) 'username': username,
      if (province != null) 'province': province,
      if (municipality != null) 'municipality': municipality,
    });
    notifyChanged();
  }

  Future<List<PostModel>> getMyPosts({int page = 1}) async {
    final res = await _dio.get('/posts/mine', queryParameters: {'page': page});
    return (res.data['data']['items'] as List)
        .map((e) => PostModel.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/posts/stats');
    return Map<String, dynamic>.from(res.data['data']);
  }

  // --- Categories ---
  Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await _dio.get(ApiConstants.categories);
      final list = res.data['data'] as List<dynamic>? ?? [];
      return list.map((e) => CategoryModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  // --- Posts & Feeds ---
  Future<List<PostModel>> getRecentPosts(
      {int page = 1, int? categoryId}) async {
    try {
      final res = await _dio.get(
        ApiConstants.postsRecent,
        queryParameters: {
          'page': page,
          'pageSize': 20,
          if (categoryId != null) 'categoryId': categoryId
        },
      );
      final items = res.data['data']['items'] as List<dynamic>? ?? [];
      return items.map((e) => PostModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<List<PostModel>> getNearbyPosts({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? categoryId,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.postsNearby,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          'pageNumber': page,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );
      final items = res.data['data']['items'] as List<dynamic>? ?? [];
      return items.map((e) => PostModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<List<PostModel>> getPopularPosts({int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiConstants.postsPopular,
        queryParameters: {'page': page, 'pageSize': 20},
      );
      final items = res.data['data']['items'] as List<dynamic>? ?? [];
      return items.map((e) => PostModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  // --- Interaction ---
  Future<bool> confirmPost(String postId, {double? lat, double? lng}) async {
    try {
      final res = await _dio.post(
        '/posts/$postId/confirm',
        data: {'latitude': lat, 'longitude': lng},
      );
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleReaction(String postId, String reactionType) async {
    try {
      final res = await _dio.post(
        '/posts/$postId/reactions',
        data: {'reactionType': reactionType},
      );
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // --- Auth Session & Profile ---
  Future<bool> isLoggedIn() async {
    final token = await _credential('jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await _dio.get(ApiConstants.usersMe);
      if (res.data['success'] == true && res.data['data'] != null) {
        return UserModel.fromJson(res.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUserProfile(String id) async {
    final res = await _dio.get('/users/$id');
    return res.data['data'] == null ? null : UserModel.fromJson(res.data['data']);
  }

  Future<bool> toggleFollow(String id) async {
    final res = await _dio.post('/users/$id/follow');
    notifyChanged();
    return res.data['data'] as bool? ?? false;
  }

  Future<List<PostModel>> getUserPosts(String id, {int page = 1}) async {
    final res = await _dio.get('/users/$id/posts', queryParameters: {'page': page});
    return (res.data['data'] as List<dynamic>? ?? [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return (res.data['data'] as List<dynamic>? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markNotificationsRead() async {
    await _dio.post('/notifications/read');
  }

  Future<void> registerDeviceToken(String token, String platform) async {
    await _dio.post('/notifications/devices', data: {'token': token, 'platform': platform});
  }

  // --- Create & Upload ---
  Future<String?> uploadImage(String filePath) async {
    try {
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final res = await _dio.post(
        ApiConstants.uploadImage,
        data: formData,
      );

      if (res.data['success'] == true && res.data['url'] != null) {
        final rawUrl = res.data['url'] as String;
        return rawUrl;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createPost({
    required int categoryId,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String province,
    required String municipality,
    String? neighborhood,
    String? addressReference,
    List<String>? imageUrls,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.createPost,
        data: {
          'categoryId': categoryId,
          'title': title,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'province': province,
          'municipality': municipality,
          'neighborhood': neighborhood,
          'addressReference': addressReference,
          'imageUrls': imageUrls ?? [],
        },
      );
      if (res.data['success'] == true) {
        return {'success': true, 'data': res.data['data']};
      }
      return {
        'success': false,
        'message': res.data['message'] ?? 'Error al publicar reporte'
      };
    } on DioException catch (e) {
      final msg = errorMessage(e);
      return {'success': false, 'message': msg};
    } catch (_) {
      return {'success': false, 'message': 'Ocurrió un error inesperado'};
    }
  }

  // --- Post Detail & Map ---
  Future<PostModel?> getPostById(String id) async {
    try {
      final res = await _dio.get('/posts/$id');
      if (res.data['success'] == true && res.data['data'] != null) {
        return PostModel.fromJson(res.data['data']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<PostMapPinModel>> getMapPins({
    double minLat = 17.5,
    double maxLat = 20.0,
    double minLng = -72.0,
    double maxLng = -68.3,
    int? categoryId,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.postsMap,
        queryParameters: {
          'minLat': minLat,
          'maxLat': maxLat,
          'minLng': minLng,
          'maxLng': maxLng,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );
      final list = res.data['data'] as List<dynamic>? ?? [];
      return list.map((e) => PostMapPinModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  // --- Moderation ---
  Future<bool> reportPost({
    required String postId,
    required String reason,
    String? description,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.moderationReport,
        data: {
          'postId': postId,
          'reason': reason,
          'description': description,
        },
      );
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
