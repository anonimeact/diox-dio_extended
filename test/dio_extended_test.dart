import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_extended/src/interceptors/dio_interceptor.dart';
import 'package:test/test.dart';

void main() {
  group('DioInterceptor', () {
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
