import 'dart:io';
import 'package:dio/dio.dart';
import 'galat.dart';
import 'sesi_cloudflare.dart';

const String defaultPddiktiBaseUrl = String.fromEnvironment(
  'PDDIKTI_BASE_URL',
  defaultValue: 'https://api-pddikti.kemdiktisaintek.go.id',
);

/// Mengecek apakah respons HTTP 403 berasal dari proteksi reCAPTCHA atau Cloudflare
bool adalahGalatVerifikasi(Response<dynamic>? response) {
  if (response == null || response.statusCode != 403) return false;
  final data = response.data;
  final text = data is Map
      ? '${data['message'] ?? ''} ${data['error'] ?? ''} $data'.toLowerCase()
      : (data?.toString() ?? '').toLowerCase();
  return text.contains('recaptcha') ||
      text.contains('cloudflare') ||
      text.contains('cf-ray') ||
      text.contains('turnstile') ||
      text.contains('challenge');
}

Dio buatDioKlien({String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? defaultPddiktiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Connection': 'keep-alive',
        'Host': 'api-pddikti.kemdiktisaintek.go.id',
        'Origin': 'https://pddikti.kemdiktisaintek.go.id',
        'Referer': 'https://pddikti.kemdiktisaintek.go.id/',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'X-User-IP': '103.47.132.29',
        'sec-ch-ua': '"Chromium";v="131", "Not_A Brand";v="24"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        final customBase = SesiCloudflareNotifier.baseUrlAktif;
        if (baseUrl == null && customBase != null && customBase.isNotEmpty) {
          options.baseUrl = customBase;
        }

        final cookies = SesiCloudflareNotifier.cookiesAktif;
        if (cookies != null && cookies.isNotEmpty) {
          options.headers['Cookie'] = cookies;
        }

        final ua = SesiCloudflareNotifier.userAgentAktif;
        if (ua != null && ua.isNotEmpty) {
          options.headers['User-Agent'] = ua;
        }

        final recaptchaToken = SesiCloudflareNotifier.recaptchaTokenAktif;
        if (recaptchaToken != null && recaptchaToken.isNotEmpty) {
          options.headers['X-Recaptcha-Token'] = recaptchaToken;
        }

        return handler.next(options);
      },
      onError: (DioException err, ErrorInterceptorHandler handler) async {
        final requestOptions = err.requestOptions;
        int retries = (requestOptions.extra['retries'] as int?) ?? 0;

        // Cek apakah layak diulang: waktu habis, gagal sambung, atau 5xx
        final isTimeout = err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout;
        final isConnectionError = err.type == DioExceptionType.connectionError;
        final statusCode = err.response?.statusCode;
        final is5xx = statusCode != null && statusCode >= 500 && statusCode < 600;

        if ((isTimeout || isConnectionError || is5xx) && retries < 2) {
          retries++;
          requestOptions.extra['retries'] = retries;
          final delayMs = retries == 1 ? 400 : 1200;
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          try {
            final response = await dio.fetch<dynamic>(requestOptions);
            return handler.resolve(response);
          } catch (e) {
            if (e is DioException) {
              return handler.next(e);
            }
          }
        }

        return handler.next(err);
      },
    ),
  );

  return dio;
}

Galat petakanDioError(dynamic error) {
  if (error is Galat) return error;

  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const WaktuHabis();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return const TanpaJaringan();
    }
    if (adalahGalatVerifikasi(error.response)) {
      return const ButuhVerifikasiCloudflare();
    }
    final status = error.response?.statusCode;
    if (status != null) {
      if (status >= 500) {
        return Server(status);
      } else if (status >= 400) {
        return Ditolak(status);
      }
    }
  }

  return FormatTakTerduga(error?.toString());
}
