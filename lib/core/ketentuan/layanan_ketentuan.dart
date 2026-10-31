import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LayananKetentuan {
  static const String _namaBerkas = 'status_persetujuan_v1.json';

  @visibleForTesting
  static Directory? direktoriUji;
  static Directory? _dirAktif;

  static Future<Directory> _dapatkanDir() async {
    if (direktoriUji != null) return direktoriUji!;
    if (_dirAktif != null) return _dirAktif!;
    try {
      _dirAktif = await getApplicationSupportDirectory();
    } catch (_) {
      _dirAktif = Directory.systemTemp.createTempSync('pddikti_ketentuan_');
    }
    return _dirAktif!;
  }

  /// Memeriksa apakah pengguna sudah pernah menyetujui ketentuan layanan
  static Future<bool> sudahSetuju() async {
    try {
      final dir = await _dapatkanDir();
      final berkas = File('${dir.path}/$_namaBerkas');
      if (!await berkas.exists()) return false;
      final raw = await berkas.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['disetujui'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Menyimpan status persetujuan ke penyimpanan lokal
  static Future<void> simpanPersetujuan() async {
    try {
      final dir = await _dapatkanDir();
      final berkas = File('${dir.path}/$_namaBerkas');
      final payload = {
        'disetujui': true,
        'waktu': DateTime.now().toIso8601String(),
        'versi_ketentuan': '1.0.0',
      };
      await berkas.writeAsString(jsonEncode(payload));
    } catch (_) {}
  }
}

