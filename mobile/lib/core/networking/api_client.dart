import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../../shared/models/models.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle 401 token refresh if needed
          return handler.next(error);
        },
      ),
    );
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post(
        ApiConstants.authLogin,
        data: {'email': email, 'password': password},
      );
      if (res.data['success'] == true) {
        final token = res.data['data']['accessToken'];
        await _storage.write(key: 'jwt_token', value: token);
        return {'success': true, 'data': res.data['data']};
      }
      return {'success': false, 'message': res.data['message'] ?? 'Credenciales inválidas'};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error de conexión con el servidor';
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
        final token = res.data['data']['accessToken'];
        await _storage.write(key: 'jwt_token', value: token);
        return {'success': true, 'data': res.data['data']};
      }
      return {'success': false, 'message': res.data['message'] ?? 'Error al registrar'};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error de conexión con el servidor';
      return {'success': false, 'message': msg};
    } catch (_) {
      return {'success': false, 'message': 'Ocurrió un error inesperado'};
    }
  }

  Future<bool> loginWithGoogle(String idToken) async {
    try {
      final res = await _dio.post('/auth/google', data: {'idToken': idToken});
      if (res.data['success'] == true) {
        final token = res.data['data']['accessToken'];
        await _storage.write(key: 'jwt_token', value: token);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loginWithApple(String identityToken) async {
    try {
      final res = await _dio.post('/auth/apple', data: {'identityToken': identityToken});
      if (res.data['success'] == true) {
        final token = res.data['data']['accessToken'];
        await _storage.write(key: 'jwt_token', value: token);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // --- Categories ---
  Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await _dio.get(ApiConstants.categories);
      final list = res.data['data'] as List<dynamic>? ?? [];
      return list.map((e) => CategoryModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Posts & Feeds ---
  Future<List<PostModel>> getRecentPosts({int page = 1, int? categoryId}) async {
    try {
      final res = await _dio.get(
        ApiConstants.postsRecent,
        queryParameters: {'page': page, 'pageSize': 20, if (categoryId != null) 'categoryId': categoryId},
      );
      final items = res.data['data']['items'] as List<dynamic>? ?? [];
      return items.map((e) => PostModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PostModel>> getNearbyPosts({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? categoryId,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.postsNearby,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );
      final items = res.data['data']['items'] as List<dynamic>? ?? [];
      return items.map((e) => PostModel.fromJson(e)).toList();
    } catch (_) {
      return [];
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
      return [];
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

  Future<Map<String, dynamic>> createPost({
    required int categoryId,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String province,
    required String municipality,
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
          'addressReference': addressReference,
          'imageUrls': imageUrls ?? [],
        },
      );
      if (res.data['success'] == true) {
        return {'success': true, 'data': res.data['data']};
      }
      return {'success': false, 'message': res.data['message'] ?? 'Error al publicar reporte'};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error de conexión con el servidor';
      return {'success': false, 'message': msg};
    } catch (_) {
      return {'success': false, 'message': 'Ocurrió un error inesperado'};
    }
  }
}
