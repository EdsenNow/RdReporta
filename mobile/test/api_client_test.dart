import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdreporta/core/networking/api_client.dart';
import 'package:rdreporta/shared/models/models.dart';

class FakeAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  FakeAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) async =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Map<String, dynamic> data) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
Map<String, dynamic> session(String token) => {
      'success': true,
      'data': {'accessToken': token, 'refreshToken': 'refresh-$token'}
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('login persists both access and refresh tokens', () async {
    final client = ApiClient.forTesting(
        FakeAdapter((_) => jsonResponse(200, session('new'))));
    expect((await client.login('a@b.do', 'password'))['success'], true);
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'jwt_token'), 'new');
    expect(await storage.read(key: 'refresh_token'), 'refresh-new');
  });

  test('session remains available after recreating the client', () async {
    final client = ApiClient.forTesting(
        FakeAdapter((_) => jsonResponse(200, session('temporary'))));
    await client.login('a@b.do', 'password');
    expect(await client.isLoggedIn(), true);
    expect(
        await const FlutterSecureStorage().read(key: 'jwt_token'), 'temporary');
    expect(
        await ApiClient.forTesting(FakeAdapter((_) => jsonResponse(200, {})))
            .isLoggedIn(),
        true);
  });

  test('concurrent expired requests share one refresh and retry with new token',
      () async {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': 'old', 'refresh_token': 'refresh-old'});
    var refreshes = 0;
    var retries = 0;
    final client = ApiClient.forTesting(FakeAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshes++;
        expect(options.data['refreshToken'], 'refresh-old');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return jsonResponse(200, session('new'));
      }
      if (options.headers['Authorization'] == 'Bearer old') {
        return jsonResponse(401, {});
      }
      expect(options.headers['Authorization'], 'Bearer new');
      retries++;
      return jsonResponse(200, {'success': true, 'data': []});
    }));
    await Future.wait([client.getCategories(), client.getCategories()]);
    expect(refreshes, 1);
    expect(retries, 2);
  });

  test('rejected refresh clears credentials and does not loop', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': 'old', 'refresh_token': 'old'});
    var calls = 0;
    final client = ApiClient.forTesting(FakeAdapter((options) {
      calls++;
      return jsonResponse(
          options.path == '/auth/refresh' ? 400 : 401, {'success': false});
    }));
    await expectLater(client.getCategories(), throwsA(isA<DioException>()));
    expect(calls, 2);
    expect(await client.isLoggedIn(), false);
  });

  test('server outage does not turn a failed list into an empty success',
      () async {
    final client = ApiClient.forTesting(FakeAdapter(
        (_) => jsonResponse(503, {'message': 'Temporalmente no disponible'})));
    await expectLater(client.getRecentPosts(), throwsA(isA<DioException>()));
  });

  test('temporary refresh outage preserves the session for retry', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': 'old', 'refresh_token': 'old'});
    final client = ApiClient.forTesting(FakeAdapter((options) =>
        jsonResponse(options.path == '/auth/refresh' ? 503 : 401, {})));
    await expectLater(client.getCategories(), throwsA(isA<DioException>()));
    expect(await client.isLoggedIn(), true);
  });

  test('logout clears credentials even if the server is unavailable', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': 'old', 'refresh_token': 'old'});
    final client =
        ApiClient.forTesting(FakeAdapter((_) => jsonResponse(503, {})));
    await client.logout();
    expect(await client.isLoggedIn(), false);
    expect(
        await const FlutterSecureStorage().read(key: 'refresh_token'), isNull);
  });

  test('profile reads the membership field', () {
    final user = UserModel.fromJson({
      'id': 'id',
      'username': 'ciudadano',
      'email': 'a@b.do',
      'memberSince': '2025-03-01T12:00:00Z'
    });
    expect(user.createdAt, DateTime.utc(2025, 3, 1, 12));
  });

  test('plain text HTTP error has a usable message', () {
    final request = RequestOptions(path: '/posts');
    final error = DioException(
        requestOptions: request,
        response: Response(
            requestOptions: request, statusCode: 502, data: 'Bad gateway'));
    expect(ApiClient.errorMessage(error), contains('No se pudo conectar'));
  });
}
