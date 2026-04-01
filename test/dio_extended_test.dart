import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_extended/src/interceptors/dio_interceptor.dart';
import 'package:test/test.dart';

void main() {
  group('DioInterceptor', () {
    test('keeps custom content-type on retry for non-FormData', () async {
      final dio = Dio();
      final adapter = _QueueAdapter(
        statusCodes: [401, 200],
      );
      dio.httpClientAdapter = adapter;

      dio.interceptors.add(
        DioInterceptor(
          dio: dio,
          tokenExpiredCode: 401,
          refreshTokenCallback: () async => {
            'Authorization': 'Bearer new_token',
          },
        ),
      );

      final response = await dio.post<dynamic>(
        '/plaintext',
        data: 'hello world',
        options: Options(headers: {
          'content-type': 'text/plain',
        }),
      );

      expect(response.statusCode, 200);
      expect(adapter.callCount, 2);

      final retried = adapter.requests[1];
      final effectiveContentType = _resolveContentType(retried);
      expect(effectiveContentType, contains('text/plain'));
      expect(effectiveContentType, isNot(contains('application/json')));
    });

    test('does not leak FormData content-type into next JSON request',
        () async {
      final dio = Dio();
      final adapter = _QueueAdapter(
        statusCodes: [200, 200],
      );
      dio.httpClientAdapter = adapter;

      dio.interceptors.add(
        DioInterceptor(
          dio: dio,
          tokenExpiredCode: 401,
          refreshTokenCallback: () async => {
            'Authorization': 'Bearer new_token',
          },
        ),
      );

      await dio.post<dynamic>(
        '/upload',
        data: FormData.fromMap({
          'name': 'john',
          'file': MultipartFile.fromBytes(
            Uint8List.fromList([1, 2, 3, 4]),
            filename: 'avatar.png',
          ),
        }),
      );

      await dio.post<dynamic>(
        '/json',
        data: {'hello': 'world'},
      );

      expect(adapter.callCount, 2);
      final secondRequest = adapter.requests[1];
      final effectiveContentType = _resolveContentType(secondRequest);
      expect(effectiveContentType, contains('application/json'));
    });

    test('does not deadlock when refresh callback uses the same Dio', () async {
      final dio = Dio();
      final adapter = _QueueAdapter(
        statusCodes: [401, 401],
      );
      dio.httpClientAdapter = adapter;
      var refreshCount = 0;

      dio.interceptors.add(
        DioInterceptor(
          dio: dio,
          tokenExpiredCode: 401,
          refreshTokenCallback: () async {
            refreshCount += 1;
            await dio.post<dynamic>('/refresh', data: {});
            return {
              'Authorization': 'Bearer new_token',
            };
          },
        ),
      );

      await expectLater(
        () => dio.post<dynamic>(
          '/logout',
          data: {},
        ).timeout(const Duration(seconds: 2)),
        throwsA(isA<DioException>()),
      );

      expect(refreshCount, 1);
      expect(adapter.callCount, 2);
    });

    test('does not refresh repeatedly when retry still returns 401', () async {
      final dio = Dio();
      final adapter = _QueueAdapter(
        statusCodes: [401, 401],
      );
      dio.httpClientAdapter = adapter;
      var refreshCount = 0;

      dio.interceptors.add(
        DioInterceptor(
          dio: dio,
          tokenExpiredCode: 401,
          refreshTokenCallback: () async {
            refreshCount += 1;
            return {
              'Authorization': 'Bearer new_token',
            };
          },
        ),
      );

      await expectLater(
        () => dio.post<dynamic>(
          '/logout',
          data: {},
        ),
        throwsA(isA<DioException>()),
      );

      expect(refreshCount, 1);
      expect(adapter.callCount, 2);
    });

    test('retries JSON request after token refresh', () async {
      final dio = Dio();
      final adapter = _QueueAdapter(
        statusCodes: [401, 200],
      );
      dio.httpClientAdapter = adapter;

      dio.interceptors.add(
        DioInterceptor(
          dio: dio,
          tokenExpiredCode: 401,
          refreshTokenCallback: () async => {
            'Authorization': 'Bearer new_token',
          },
        ),
      );

      final response = await dio.post<dynamic>(
        '/posts',
        data: {'title': 'hello'},
      );

      expect(response.statusCode, 200);
      expect(adapter.callCount, 2);
    });

    test('retries FormData request after token refresh', () async {
      final dio = Dio();
      final adapter = _QueueAdapter(
        statusCodes: [401, 200],
      );
      dio.httpClientAdapter = adapter;

      dio.interceptors.add(
        DioInterceptor(
          dio: dio,
          tokenExpiredCode: 401,
          refreshTokenCallback: () async => {
            'Authorization': 'Bearer new_token',
          },
        ),
      );

      final response = await dio.post<dynamic>(
        '/upload',
        data: FormData.fromMap({
          'name': 'john',
          'file': MultipartFile.fromBytes(
            Uint8List.fromList([1, 2, 3, 4]),
            filename: 'avatar.png',
          ),
        }),
      );

      expect(response.statusCode, 200);
      expect(adapter.callCount, 2);
    });
  });
}

class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter({required this.statusCodes});

  final List<int> statusCodes;
  final List<RequestOptions> requests = [];
  int callCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount += 1;
    requests.add(options);
    final index = callCount - 1;
    final status = index < statusCodes.length ? statusCodes[index] : 200;
    return ResponseBody.fromString(
      '{"ok":true}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

String _resolveContentType(RequestOptions options) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == Headers.contentTypeHeader) {
      return entry.value.toString().toLowerCase();
    }
  }
  return (options.contentType ?? '').toLowerCase();
}
