import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdreporta/core/networking/api_client.dart';

class UploadAdapter implements HttpClientAdapter {
  UploadAdapter(this.handle);
  final ResponseBody Function(RequestOptions) handle;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    if (options.method == 'PUT') {
      final received = await stream!.expand((bytes) => bytes).toList();
      expect(received, options.data);
      expect(received.length.toString(),
          options.headers['Content-Length'].toString());
    }
    return handle(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody reply(Map<String, dynamic> data) =>
    ResponseBody.fromString(jsonEncode(data), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File video;
  const size = 512 * 1024 + 8;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('rdreporta-video-test-');
    video = await File('${directory.path}/sample.mp4')
        .writeAsBytes(Uint8List(size));
  });
  tearDown(() => directory.delete(recursive: true));

  test('lost response retries only the same block and reports confirmed bytes',
      () async {
    final offsets = <int>[];
    final progress = <int>[];
    final transferred = <int>[];
    final client = ApiClient.forTesting(UploadAdapter((options) {
      if (options.method == 'GET') {
        return reply({
          'data': {'id': 'test-owner'}
        });
      }
      final offset = options.queryParameters['offset'] as int;
      // Sending bytes must not acknowledge them before the server responds.
      expect(progress.last, offset);
      expect(transferred.last, offset + (options.data as List<int>).length);
      offsets.add(offset);
      if (offsets.length == 2) {
        throw DioException(
            requestOptions: options, type: DioExceptionType.connectionError);
      }
      return reply({
        'success': true,
        'receivedBytes': offset == 0 ? 512 * 1024 : size,
        if (offset > 0) 'url': '/uploads/completed.mp4'
      });
    }));
    expect(
        await client.uploadVideo(video.path,
            onTransferProgress: (sent, _) => transferred.add(sent),
            onSendProgress: (sent, _) => progress.add(sent)),
        '/uploads/completed.mp4');
    expect(offsets, [0, 512 * 1024, 512 * 1024]);
    expect(progress, [0, 512 * 1024, size]);
    expect(transferred.length, greaterThan(progress.length));
  });

  test(
      'retry after cancellation resumes confirmed blocks with the same upload ID',
      () async {
    final offsets = <int>[];
    final paths = <String>[];
    final token = CancelToken();
    final client = ApiClient.forTesting(UploadAdapter((options) {
      if (options.method == 'GET') {
        return reply({
          'data': {'id': 'test-owner'}
        });
      }
      final offset = options.queryParameters['offset'] as int;
      offsets.add(offset);
      paths.add(options.path);
      return reply({
        'success': true,
        'receivedBytes': offset == 0 ? 512 * 1024 : size,
        if (offset > 0) 'url': '/uploads/completed.mp4'
      });
    }));
    await expectLater(
        client.uploadVideo(video.path, cancelToken: token,
            onSendProgress: (sent, _) {
          if (sent > 0) token.cancel('test');
        }),
        throwsA(isA<DioException>()));
    expect(await client.uploadVideo(video.path), '/uploads/completed.mp4');
    expect(offsets, [0, 512 * 1024]);
    expect(paths.toSet().length, 1);
  });
}
