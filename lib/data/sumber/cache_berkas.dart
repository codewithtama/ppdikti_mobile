import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheMeta {
  const CacheMeta({required this.waktuUnduh});
  final DateTime waktuUnduh;

  Map<String, dynamic> toJson() => {'waktuUnduh': waktuUnduh.toIso8601String()};

  factory CacheMeta.fromJson(Map<String, dynamic> j) {
    final str = j['waktuUnduh'] as String?;
    return CacheMeta(
      waktuUnduh: str != null ? (DateTime.tryParse(str) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

class CacheBerkas {
  static Directory? _supportDir;

  static Future<Directory> _dapatkanDir() async {
    return _supportDir ??= await getApplicationSupportDirectory();
  }

  /// Simpan teks JSON dan metadata waktu unduh
  static Future<void> simpan(String namaBerkas, String kontenJson, {DateTime? waktu}) async {
    final dir = await _dapatkanDir();
    final berkas = File('${dir.path}/$namaBerkas.json');
    await berkas.writeAsString(kontenJson);

    final metaBerkas = File('${dir.path}/$namaBerkas.meta.json');
    final meta = CacheMeta(waktuUnduh: waktu ?? DateTime.now());
    await metaBerkas.writeAsString(jsonEncode(meta.toJson()));
  }

  /// Baca konten JSON dan metadata waktu unduh
  static Future<({String? data, CacheMeta? meta})> baca(String namaBerkas) async {
    try {
      final dir = await _dapatkanDir();
      final berkas = File('${dir.path}/$namaBerkas.json');
      if (!await berkas.exists()) return (data: null, meta: null);

      final data = await berkas.readAsString();

      final metaBerkas = File('${dir.path}/$namaBerkas.meta.json');
      CacheMeta? meta;
      if (await metaBerkas.exists()) {
        try {
          final metaStr = await metaBerkas.readAsString();
          meta = CacheMeta.fromJson(jsonDecode(metaStr) as Map<String, dynamic>);
        } catch (_) {}
      }

      return (data: data, meta: meta);
    } catch (_) {
      return (data: null, meta: null);
    }
  }

  /// Simpan / perbarui map kelulusan per kode kampus
  static Future<void> simpanKelulusan(String kode, double nilai) async {
    try {
      final dir = await _dapatkanDir();
      final berkas = File('${dir.path}/kelulusan.json');
      Map<String, dynamic> map = {};
      if (await berkas.exists()) {
        try {
          final str = await berkas.readAsString();
          map = jsonDecode(str) as Map<String, dynamic>;
        } catch (_) {}
      }

      map[kode] = {
        'nilai': nilai,
        'waktu': DateTime.now().toIso8601String(),
      };
      await berkas.writeAsString(jsonEncode(map));
    } catch (_) {}
  }

  /// Baca nilai kelulusan dari cache bila masih dalam masa berlaku TTL 24 jam
  static Future<double?> bacaKelulusan(String kode) async {
    try {
      final dir = await _dapatkanDir();
      final berkas = File('${dir.path}/kelulusan.json');
      if (!await berkas.exists()) return null;

      final str = await berkas.readAsString();
      final map = jsonDecode(str) as Map<String, dynamic>;
      final entry = map[kode] as Map<String, dynamic>?;
      if (entry == null) return null;

      final waktuStr = entry['waktu'] as String?;
      if (waktuStr == null) return null;
      final waktu = DateTime.tryParse(waktuStr);
      if (waktu == null) return null;

      if (DateTime.now().difference(waktu).inHours > 24) {
        return null; // TTL 24 jam habis
      }

      final nilai = entry['nilai'];
      if (nilai is num) return nilai.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }
}

