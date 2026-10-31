import 'dart:io';
import 'package:flutter/services.dart';

class LayananIzinAndroid {
  static const MethodChannel _channel = MethodChannel('com.pddikti.pddikti_mobile/pengaturan');

  /// Memeriksa apakah aplikasi diizinkan memasang paket APK (Unknown Sources)
  static Future<bool> bisaInstallPaket() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('bisaInstallPaket');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Membuka halaman pengaturan sistem "Pasang aplikasi tidak dikenal" untuk aplikasi ini
  static Future<bool> bukaPengaturanInstallPaket() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('bukaPengaturanInstallPaket');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}

