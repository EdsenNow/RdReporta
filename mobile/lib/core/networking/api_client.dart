import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../../shared/models/models.dart';
import 'post_views_store.dart';

class _VideoTransfer {
  _VideoTransfer(this.id);
  final String id;
  int acknowledged = 0;
}

class ApiClient {
  final Map<String, _VideoTransfer> _videoTransfers = {};
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient? _testClient;
  factory ApiClient() => _testClient ?? _instance;

  @visibleForTesting
  static void useForTesting(ApiClient? client) => _testClient = client;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<bool>? _refreshing;
  Future<String?>? _currentUserIdRequest;
  final Map<String, Future<bool?>> _followingRequests = {};
  final Set<String> _recordedPostViews = {};
  int _viewSession = 0;
  final Map<String, Future<int?>> _postViewRequests = {};
  final ValueNotifier<int> changes = ValueNotifier(0);
  final ValueNotifier<int> sessionChanges = ValueNotifier(0);
  final ValueNotifier<int> unreadNotifications = ValueNotifier(0);
  int _notificationRequest = 0;
  Future<void> Function()? beforeLogout;
  late final PostViewsStore postViews = PostViewsStore(_streamPostViews);

  Stream<Map<String, dynamic>> _streamPostViews(List<String> ids) {
    final cancelToken = CancelToken();
    StreamSubscription<String>? subscription;
    var cancelled = false;
    late StreamController<Map<String, dynamic>> controller;

    Future<void> open() async {
      try {
        final response = await _dio.get<ResponseBody>(
          '/posts/views/live',
          queryParameters: {'ids': ids.take(200).join(',')},
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: Duration.zero,
            headers: {'Accept': 'text/event-stream'},
          ),
        );
        if (cancelled) return;
        final lines = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());
        subscription = lines.listen((line) {
          if (!line.startsWith('data: ')) return;
          try {
            final event = jsonDecode(line.substring(6));
            if (event is Map<String, dynamic>) controller.add(event);
          } catch (error, stack) {
            controller.addError(error, stack);
          }
        }, onError: controller.addError, onDone: controller.close);
      } catch (error, stack) {
        if (!cancelled) {
          controller.addError(error, stack);
          await controller.close();
        }
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: open,
      onCancel: () async {
        cancelled = true;
        cancelToken.cancel('Live view subscription closed');
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  void notifyChanged() => changes.value++;

  Future<void> _saveSession(dynamic data) async {
    _resetViewSession();
    _currentUserIdRequest = null;
    _followingRequests.clear();
    await _storage.write(key: 'jwt_token', value: data['accessToken']);
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);
    sessionChanges.value++;
  }

  Future<String?> _credential(String key) async =>
      await _storage.read(key: key);

  Future<bool> _refresh() async {
    final token = await _credential('jwt_token');
    final refreshToken = await _credential('refresh_token');
    if (token == null || refreshToken == null) {
      await _clearSession();
      return false;
    }
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
    _notificationRequest++;
    unreadNotifications.value = 0;
    _resetViewSession();
    _currentUserIdRequest = null;
    _followingRequests.clear();
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    sessionChanges.value++;
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
      if (error.response?.statusCode == 502 ||
          error.response?.statusCode == 503 ||
          error.response?.statusCode == 504) {
        return 'No se pudo conectar con el servidor de RDReporta. Comprueba que la API esté encendida y vuelve a intentarlo.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'No se pudo conectar con el servidor de RDReporta. Comprueba que la API esté encendida y vuelve a intentarlo.';
      }
      if (error.response != null) {
        return 'El servidor no pudo completar la solicitud (${error.response!.statusCode}).';
      }
      return 'No se pudo completar la conexión con RDReporta.';
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
          if ((error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.connectionError) &&
              request.extra['fallback_host_tried'] != true &&
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android) {
            request.extra['fallback_host_tried'] = true;
            final currentBase = _dio.options.baseUrl;
            final altBase = currentBase.contains('127.0.0.1')
                ? currentBase.replaceFirst('127.0.0.1', '10.0.2.2')
                : currentBase.replaceFirst('10.0.2.2', '127.0.0.1');
            if (altBase != currentBase) {
              _dio.options.baseUrl = altBase;
              request.baseUrl = altBase;
              try {
                return handler.resolve(await _dio.fetch(request));
              } catch (_) {}
            }
          }
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
                if (retryError.response?.statusCode == 401) {
                  await _clearSession();
                }
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
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post(
        ApiConstants.authLogin,
        data: {'email': email, 'password': password},
      );
      if (res.data['success'] == true) {
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

  Future<void> loginWithGoogle(String idToken) async {
    try {
      final res = await _dio.post('/auth/google', data: {'idToken': idToken});
      if (res.data['success'] != true || res.data['data'] == null) {
        throw Exception(res.data['message']?.toString() ??
            'No se pudo iniciar sesión con Google.');
      }
      await _saveSession(res.data['data']);
      notifyChanged();
    } on DioException catch (error) {
      throw Exception(errorMessage(error));
    }
  }

  Future<bool> loginWithApple(String identityToken, {String? fullName}) async {
    try {
      final res = await _dio.post('/auth/apple', data: {
        'identityToken': identityToken,
        if (fullName != null && fullName.trim().isNotEmpty) 'fullName': fullName.trim(),
      });
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
    await beforeLogout?.call();
    try {
      await _dio.post('/auth/logout');
    } catch (_) {/* Clear local credentials even when offline. */}
    await _clearSession();
    notifyChanged();
  }

  Future<void> deleteAccount() async {
    final res = await _dio.delete('/users/me');
    if (res.data['success'] != true) {
      throw Exception(
          res.data['message']?.toString() ?? 'No se pudo eliminar la cuenta.');
    }
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

  Future<void> deletePost(String id) async {
    final res = await _dio.delete('/posts/$id');
    if (res.data['success'] != true) {
      throw Exception(
          res.data['message']?.toString() ?? 'No se pudo eliminar el reporte.');
    }
    notifyChanged();
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
  void _resetViewSession() {
    _viewSession++;
    _recordedPostViews.clear();
    _postViewRequests.clear();
  }

  Future<int?> recordPostView(String postId) {
    if (_recordedPostViews.contains(postId)) {
      return Future.value(null);
    }

    final pending = _postViewRequests[postId];
    if (pending != null) return pending;

    final session = _viewSession;
    final request = (() async {
      try {
        final res = await _dio.post('/posts/$postId/views');
        if (res.data['success'] == true && res.data['data'] != null) {
          if (session == _viewSession) _recordedPostViews.add(postId);
          final count = (res.data['data'] as num).toInt();
          postViews.update(postId, count);
          return count;
        }
      } catch (e) {
        // Las impresiones no deben interrumpir la lectura ni mostrar errores.
        print('Error recording view: $e');
      } finally {
        if (session == _viewSession) _postViewRequests.remove(postId);
      }
      return null;
    })();
    _postViewRequests[postId] = request;
    return request;
  }

  Future<String?> toggleReaction(String postId, String reactionType) async {
    final session = _viewSession;
    try {
      final res = await _dio.post(
        '/posts/$postId/reactions',
        data: {'reactionType': reactionType},
      );
      if (res.data['success'] == true) {
        final count = res.data['viewsCount'];
        if (count is num) {
          if (session == _viewSession) _recordedPostViews.add(postId);
          postViews.update(postId, count.toInt());
        }
        return null;
      }
      return res.data['message']?.toString() ??
          'No se pudo guardar la reacción.';
    } catch (error) {
      return errorMessage(error);
    }
  }

  // --- Auth Session & Profile ---
  Future<bool> isLoggedIn() async {
    final token = await _credential('jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> restoreSession() async {
    if (!await isLoggedIn()) return false;
    // Validate/renew when the API is available. A network outage must not
    // discard saved credentials or send an authenticated user to login.
    await getCurrentUser();
    return isLoggedIn();
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

  Future<String?> getCurrentUserId() async {
    final id = await (_currentUserIdRequest ??=
        getCurrentUser().then((user) => user?.id));
    if (id == null) _currentUserIdRequest = null;
    return id;
  }

  Future<UserModel?> getUserProfile(String id) async {
    final res = await _dio.get('/users/$id');
    return res.data['data'] == null
        ? null
        : UserModel.fromJson(res.data['data']);
  }

  Future<bool?> getFollowingState(String id) =>
      _followingRequests.putIfAbsent(id, () async {
        try {
          return (await getUserProfile(id))?.isFollowing;
        } catch (_) {
          _followingRequests.remove(id);
          return null;
        }
      });

  Future<bool> toggleFollow(String id) async {
    final res = await _dio.post('/users/$id/follow');
    final following = res.data['data'] as bool? ?? false;
    _followingRequests[id] = Future.value(following);
    return following;
  }

  Future<List<PostModel>> getUserPosts(String id, {int page = 1}) async {
    final res =
        await _dio.get('/users/$id/posts', queryParameters: {'page': page});
    return (res.data['data'] as List<dynamic>? ?? [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NotificationModel>> getNotifications({int page = 1}) async {
    final res =
        await _dio.get('/notifications', queryParameters: {'page': page});
    return (res.data['data'] as List<dynamic>? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refreshUnreadNotifications() async {
    final request = ++_notificationRequest;
    final session = sessionChanges.value;
    try {
      if (!await isLoggedIn()) {
        if (request == _notificationRequest) unreadNotifications.value = 0;
        return;
      }
      final res = await _dio.get('/notifications/unread-count');
      if (request == _notificationRequest && session == sessionChanges.value) {
        unreadNotifications.value = (res.data['data'] as num).toInt();
      }
    } catch (_) {
      // Preserve the last confirmed count while offline.
    }
  }

  Future<void> markNotificationsRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await _dio.post('/notifications/read', data: {'ids': ids});
    await refreshUnreadNotifications();
  }

  Future<void> registerDeviceToken(String token, String platform) async {
    await _dio.post('/notifications/devices',
        data: {'token': token, 'platform': platform});
    final previous = await _storage.read(key: 'push_token');
    await _storage.write(key: 'push_token', value: token);
    if (previous != null && previous != token) {
      await _dio.delete('/notifications/devices', data: {'token': previous});
    }
  }

  Future<void> unregisterDeviceToken() async {
    final token = await _storage.read(key: 'push_token');
    if (token == null) return;
    await _dio.delete('/notifications/devices', data: {'token': token});
    await _storage.delete(key: 'push_token');
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

  Future<String?> uploadVideo(
    String filePath, {
    void Function(int sentBytes, int totalBytes)? onSendProgress,
    void Function(int sentBytes, int totalBytes)? onTransferProgress,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    final user = await _dio.get(ApiConstants.usersMe, cancelToken: token);
    final userId = user.data['data']['id'];
    if (userId == null) throw StateError('No se pudo identificar la sesión.');
    final file = File(filePath);
    final stat = await file.stat();
    final total = stat.size;
    if (total <= 0 || total > 150 * 1024 * 1024) {
      throw StateError('El video debe tener entre 1 byte y 150 MB.');
    }
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? '' : fileName.substring(dot).toLowerCase();
    final key =
        '$userId|$filePath|$total|${stat.modified.millisecondsSinceEpoch}';
    final transfer = _videoTransfers.putIfAbsent(key, () {
      final random = Random.secure();
      final hex = List.generate(
              16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();
      return _VideoTransfer(
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}');
    });
    const chunkSize = 512 * 1024;
    final reader = await file.open();
    try {
      onSendProgress?.call(transfer.acknowledged, total);
      onTransferProgress?.call(transfer.acknowledged, total);
      while (transfer.acknowledged < total) {
        if (token.isCancelled) throw token.cancelError!;
        final offset = transfer.acknowledged;
        await reader.setPosition(offset);
        final bytes = await reader.read(min(chunkSize, total - offset));
        if (bytes.length != min(chunkSize, total - offset)) {
          throw StateError('El archivo de video cambió durante la subida.');
        }
        for (var attempt = 0;; attempt++) {
          try {
            final response = await _dio.put(
              '${ApiConstants.uploadVideo}/chunks/${transfer.id}',
              queryParameters: {
                'offset': offset,
                'total': total,
                'extension': extension
              },
              data: bytes,
              onSendProgress: (sent, _) {
                if (!token.isCancelled) {
                  onTransferProgress?.call(
                      offset + min(sent, bytes.length), total);
                }
              },
              options: Options(
                contentType: 'application/octet-stream',
                headers: {'Content-Length': bytes.length},
                sendTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(seconds: 45),
              ),
              cancelToken: token,
            );
            final received = (response.data['receivedBytes'] as num).toInt();
            if (received < offset + bytes.length || received > total) {
              throw StateError('El servidor no confirmó el bloque enviado.');
            }
            final url = response.data['url'] as String?;
            if (received == total && (url == null || url.isEmpty)) {
              throw StateError('El servidor no confirmó el video completo.');
            }
            transfer.acknowledged = received;
            onSendProgress?.call(received, total);
            onTransferProgress?.call(received, total);
            if (received == total) {
              _videoTransfers.remove(key);
              return url;
            }
            break;
          } on DioException catch (error) {
            final status = error.response?.statusCode;
            final retryable = error.type == DioExceptionType.connectionError ||
                error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                (status != null && status >= 500);
            if (status == 409) _videoTransfers.remove(key);
            if (!retryable || attempt >= 3 || token.isCancelled) rethrow;
            await Future.any([
              Future<void>.delayed(Duration(seconds: 1 << attempt)),
              token.whenCancel.then<void>((_) {}),
            ]);
            if (token.isCancelled) throw token.cancelError!;
          }
        }
      }
      return null;
    } finally {
      await reader.close();
    }
  }

  Future<Map<String, dynamic>> createPost({
    required int categoryId,
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    required String province,
    required String municipality,
    String? neighborhood,
    String? addressReference,
    List<String>? imageUrls,
    String? videoUrl,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.createPost,
        data: {
          'categoryId': categoryId,
          'title': title,
          'description': description,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'province': province,
          'municipality': municipality,
          'neighborhood': neighborhood,
          'addressReference': addressReference,
          'imageUrls': imageUrls ?? [],
          if (videoUrl != null && videoUrl.isNotEmpty) 'videoUrl': videoUrl,
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
