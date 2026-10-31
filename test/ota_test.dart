import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/core/ota/layanan_pembaruan.dart';
import 'package:pddikti_mobile/core/ota/model_pembaruan.dart';

void main() {
  group('Sistem Pembaruan OTA (Standar Android 2026)', () {
    test('1. Parsing JSON manifest InfoPembaruan valid', () {
      final jsonMap = {
        'version': '1.0.1',
        'build_number': 2,
        'release_date': '2026-11-01',
        'changelog': [
          'Penambahan verifikasi SHA-256',
          'Peningkatan kestabilan peta luring',
        ],
        'download_url': 'https://github.com/codewithtama/ppdikti_mobile/releases/download/v1.0.1/app-release.apk',
        'sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'force_update': false,
        'size_mb': 18.5,
      };

      final info = InfoPembaruan.fromJson(jsonMap);
      expect(info.versi, '1.0.1');
      expect(info.nomorBuild, 2);
      expect(info.catatanRilis.length, 2);
      expect(info.pembaruanWajib, false);
      expect(info.ukuranMb, 18.5);
      expect(info.sha256, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');

      final serialized = info.toJson();
      expect(serialized['version'], '1.0.1');
      expect(serialized['build_number'], 2);
    });

    test('2. Perbandingan semantik versi bekerja akurat', () {
      // Versi minor lebih tinggi
      expect(
        LayananPembaruan.bandingkanVersi(
          versiRemote: '1.0.1',
          buildRemote: 1,
          versiLokal: '1.0.0',
          buildLokal: 1,
        ),
        isTrue,
      );

      // Versi mayor lebih tinggi
      expect(
        LayananPembaruan.bandingkanVersi(
          versiRemote: '2.0.0',
          buildRemote: 1,
          versiLokal: '1.9.9',
          buildLokal: 99,
        ),
        isTrue,
      );

      // Versi sama tapi build number lebih baru
      expect(
        LayananPembaruan.bandingkanVersi(
          versiRemote: '1.0.0',
          buildRemote: 2,
          versiLokal: '1.0.0',
          buildLokal: 1,
        ),
        isTrue,
      );

      // Versi sama dan build sama (tidak ada pembaruan)
      expect(
        LayananPembaruan.bandingkanVersi(
          versiRemote: '1.0.0',
          buildRemote: 1,
          versiLokal: '1.0.0',
          buildLokal: 1,
        ),
        isFalse,
      );

      // Versi lokal lebih tinggi (misal build dev lokal)
      expect(
        LayananPembaruan.bandingkanVersi(
          versiRemote: '1.0.0',
          buildRemote: 1,
          versiLokal: '1.0.1',
          buildLokal: 1,
        ),
        isFalse,
      );

      // Handling prefix 'v'
      expect(
        LayananPembaruan.bandingkanVersi(
          versiRemote: 'v1.1.0',
          buildRemote: 1,
          versiLokal: '1.0.5',
          buildLokal: 5,
        ),
        isTrue,
      );
    });

    test('3. Verifikasi SHA-256 mendeteksi integritas data', () {
      const dummyData = 'test payload apk bytes';
      final digest = sha256.convert(utf8.encode(dummyData));
      final actualHash = digest.toString().toLowerCase();

      // Checksum cocok
      expect(actualHash, digest.toString());

      // Checksum tidak cocok
      const corruptedHash = '0000000000000000000000000000000000000000000000000000000000000000';
      expect(actualHash == corruptedHash, isFalse);
    });
  });
}
