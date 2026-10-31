import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../model/beranda.dart';
import '../sumber/api_sumber.dart';
import '../sumber/cache_berkas.dart';

class BerandaRepo {
  BerandaRepo(this._api);
  final ApiSumber _api;

  Future<({BerandaData data, bool dariCache, DateTime? waktuCache})> dapatkanBeranda() async {
    final cache = await CacheBerkas.baca('beranda');
    BerandaData? dataCache;
    if (cache.data != null) {
      try {
        dataCache = BerandaData.fromJson(jsonDecode(cache.data!) as Map<String, dynamic>);
      } catch (_) {}
    }

    final waktuCache = cache.meta?.waktuUnduh;
    final cacheMasihSegar = waktuCache != null &&
        DateTime.now().difference(waktuCache).inHours < 24;

    if (dataCache != null && cacheMasihSegar) {
      return (data: dataCache, dariCache: true, waktuCache: waktuCache);
    }

    try {
      final dariApi = await _api.ambilBeranda();
      await CacheBerkas.simpan('beranda', jsonEncode(dariApi.toJson()));
      return (data: dariApi, dariCache: false, waktuCache: DateTime.now());
    } catch (e) {
      if (dataCache != null) {
        return (data: dataCache, dariCache: true, waktuCache: waktuCache);
      }
      // Cadangan bawaan aset
      try {
        final bundleStr = await rootBundle.loadString('assets/data/beranda.json');
        final decoded = jsonDecode(bundleStr) as Map<String, dynamic>;
        final dataBundle = BerandaData.fromJson(decoded);
        return (data: dataBundle, dariCache: true, waktuCache: DateTime(2026, 10, 30));
      } catch (_) {}
      rethrow;
    }
  }
}
