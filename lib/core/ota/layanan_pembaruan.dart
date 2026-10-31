import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'model_pembaruan.dart';

const String defaultOtaManifestUrl = String.fromEnvironment(
  'OTA_MANIFEST_URL',
  defaultValue: 'https://raw.githubusercontent.com/codewithtama/ppdikti_mobile/main/version.json',
);

const String defaultGithubReleaseUrl = String.fromEnvironment(
  'GITHUB_RELEASE_URL',
  defaultValue: 'https://api.github.com/repos/codewithtama/ppdikti_mobile/releases/latest',
);

final layananPembaruanProvider = Provider<LayananPembaruan>((ref) {
  return LayananPembaruan(Dio());
});

class LayananPembaruan {
  LayananPembaruan(this._dio);
  final Dio _dio;

  /// Memeriksa apakah ada rilis terbaru di repositori GitHub
  Future<StatusCekPembaruan> periksaPembaruan({String? manifestUrl}) async {
    try {
      final infoLokal = await PackageInfo.fromPlatform();
      final versiLokal = infoLokal.version;
      final buildLokal = int.tryParse(infoLokal.buildNumber) ?? 1;

      InfoPembaruan? infoRemote;

      // 1. Coba baca manifest version.json dari GitHub
      try {
        final targetUrl = manifestUrl ?? defaultOtaManifestUrl;
        final res = await _dio.get<String>(
          targetUrl,
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        if (res.data != null && res.data!.isNotEmpty) {
          final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
          infoRemote = InfoPembaruan.fromJson(decoded);
        }
      } catch (_) {
        // Fallback ke GitHub Releases API
        try {
          final res = await _dio.get<Map<String, dynamic>>(
            defaultGithubReleaseUrl,
            options: Options(
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {'Accept': 'application/vnd.github.v3+json'},
            ),
          );
          if (res.data != null) {
            final tag = (res.data!['tag_name'] ?? '').toString().replaceAll('v', '');
            final body = (res.data!['body'] ?? '').toString();
            final assets = (res.data!['assets'] as List<dynamic>?) ?? [];
            String downloadUrl = '';
            double? sizeMb;
            for (final a in assets) {
              if (a is Map<String, dynamic> && a['name'].toString().endsWith('.apk')) {
                downloadUrl = a['browser_download_url']?.toString() ?? '';
                final sizeBytes = int.tryParse(a['size']?.toString() ?? '0') ?? 0;
                if (sizeBytes > 0) sizeMb = sizeBytes / (1024 * 1024);
                break;
              }
            }
            if (downloadUrl.isNotEmpty) {
              infoRemote = InfoPembaruan(
                versi: tag,
                nomorBuild: 1,
                tanggalRilis: res.data!['published_at']?.toString() ?? '',
                catatanRilis: body.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                tautanUnduh: downloadUrl,
                ukuranMb: sizeMb,
              );
            }
          }
        } catch (_) {}
      }

      if (infoRemote == null) {
        return StatusCekPembaruan(
          adaPembaruan: false,
          versiSaatIni: versiLokal,
          buildSaatIni: buildLokal,
          pesan: 'Tidak dapat memeriksa versi terbaru saat ini.',
        );
      }

      final adaPembaruan = bandingkanVersi(
        versiRemote: infoRemote.versi,
        buildRemote: infoRemote.nomorBuild,
        versiLokal: versiLokal,
        buildLokal: buildLokal,
      );

      return StatusCekPembaruan(
        adaPembaruan: adaPembaruan,
        info: infoRemote,
        versiSaatIni: versiLokal,
        buildSaatIni: buildLokal,
      );
    } catch (e) {
      return StatusCekPembaruan(
        adaPembaruan: false,
        pesan: 'Galat: $e',
      );
    }
  }

  /// Membandingkan semantik versi (contoh: 1.0.1 > 1.0.0 atau nomor build lebih tinggi)
  static bool bandingkanVersi({
    required String versiRemote,
    required int buildRemote,
    required String versiLokal,
    required int buildLokal,
  }) {
    final vR = versiRemote.replaceAll('v', '').trim().split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final vL = versiLokal.replaceAll('v', '').trim().split('.').map((s) => int.tryParse(s) ?? 0).toList();

    while (vR.length < 3) {
      vR.add(0);
    }
    while (vL.length < 3) {
      vL.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (vR[i] > vL[i]) return true;
      if (vR[i] < vL[i]) return false;
    }

    // Jika versi mayor.minor.patch sama, bandingkan nomor build
    return buildRemote > buildLokal;
  }

  /// Mengunduh APK, memvalidasi SHA-256 (bila ada), dan memicu penginstalan sistem
  Future<void> unduhDanPasangApk({
    required String url,
    String? sha256Expected,
    required void Function(double persen, int diterima, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final fileApk = File('${tempDir.path}/pddikti_mobile_update.apk');

    if (fileApk.existsSync()) {
      try {
        fileApk.deleteSync();
      } catch (_) {}
    }

    // 1. Unduh APK dengan pelacak progres
    await _dio.download(
      url,
      fileApk.path,
      cancelToken: cancelToken,
      onReceiveProgress: (diterima, total) {
        if (total > 0) {
          final p = diterima / total;
          onProgress(p, diterima, total);
        } else {
          onProgress(-1, diterima, total);
        }
      },
    );

    // 2. Verifikasi Integritas SHA-256 (Aturan Keamanan 2026)
    if (sha256Expected != null && sha256Expected.trim().isNotEmpty) {
      final bytes = await fileApk.readAsBytes();
      final digest = sha256.convert(bytes);
      final hashActual = digest.toString().toLowerCase().trim();
      final hashTarget = sha256Expected.toLowerCase().trim();

      if (hashActual != hashTarget) {
        try {
          fileApk.deleteSync();
        } catch (_) {}
        throw Exception(
          'Integritas berkas APK gagal diverifikasi (Checksum SHA-256 tidak cocok). Unduhan dibatalkan demi keamanan.',
        );
      }
    }

    // 3. Picu instalasi via Android PackageInstaller
    final result = await OpenFilex.open(
      fileApk.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      throw Exception('Gagal membuka paket penginstal: ${result.message}');
    }
  }
}

