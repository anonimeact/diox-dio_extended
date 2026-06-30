import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';

/// Builds the Chucker interceptor without exposing the dependency
/// from the package's core entry point.
Interceptor createChuckerInterceptor() => ChuckerDioInterceptor();
