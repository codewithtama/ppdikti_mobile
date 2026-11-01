import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../model/detail_kampus.dart';
import '../model/kampus.dart';
import '../model/pencarian_global.dart';
import '../sumber/api_sumber.dart';
import '../sumber/cache_berkas.dart';
import '../../fitur/kampus/indeks_pencarian.dart';
import '../../fitur/beranda/peta/grid_ketuk.dart';

class DataParsedKampus {
  const DataParsedKampus({
    required this.daftarKampus,
    required this.indeks,
    required this.semuaTitik,
    required this.titikBiasaBuffer,
    required this.grid,
    required this.waktuUnduh,
    required this.dariCache,
    required this.aliasMap,
  });

  final List<Kampus> daftarKampus;
  final List<EntriIndeks> indeks;
  final List<TitikTerproyeksi> semuaTitik;
  final Float32List titikBiasaBuffer;
  final GridKetuk grid;
  final DateTime waktuUnduh;
  final bool dariCache;
  final Map<String, String> aliasMap;
}

/// Dijalankan di Isolate.run untuk efisiensi cold start & parse
DataParsedKampus _prosesDiIsolate(({String jsonStr, DateTime waktuUnduh, bool dariCache, Map<String, String> aliasMap}) params) {
  final dynamic decoded = jsonDecode(params.jsonStr);
  final List<dynamic> listRaw;
  if (decoded is List) {
    listRaw = decoded;
  } else if (decoded is Map<String, dynamic>) {
    listRaw = (decoded['data'] as List<dynamic>?) ?? [];
  } else {
    listRaw = [];
  }

  final daftarKampus = <Kampus>[];
  final indeks = <EntriIndeks>[];
  final titikList = <TitikTerproyeksi>[];

  for (final item in listRaw) {
    if (item is Map<String, dynamic>) {
      final kampus = Kampus.fromJson(item);
      daftarKampus.add(kampus);
      indeks.add(EntriIndeks(kampus));

      final k = kampus.koordinat;
      if (k != null) {
        final pr = GridKetuk.proyeksikan(k.lintang, k.bujur);
        titikList.add(TitikTerproyeksi(
          kampus: kampus,
          x: pr.x,
          y: pr.y,
        ));
      }
    }
  }

  // Urut titik dari barat ke timur (x naik) untuk animasi sapuan titik
  titikList.sort((a, b) => a.x.compareTo(b.x));

  final buffer = Float32List(titikList.length * 2);
  for (int i = 0; i < titikList.length; i++) {
    buffer[i * 2] = titikList[i].x;
    buffer[i * 2 + 1] = titikList[i].y;
  }

  final grid = GridKetuk(titikList);

  return DataParsedKampus(
    daftarKampus: daftarKampus,
    indeks: indeks,
    semuaTitik: titikList,
    titikBiasaBuffer: buffer,
    grid: grid,
    waktuUnduh: params.waktuUnduh,
    dariCache: params.dariCache,
    aliasMap: params.aliasMap,
  );
}

/// Fungsi level atas untuk memanggil Isolate.run tanpa menangkap closure konteks pemanggil
Future<DataParsedKampus> _jalankanIsolateDiBackground({
  required String jsonStr,
  required DateTime waktuUnduh,
  required bool dariCache,
  required Map<String, String> aliasMap,
}) {
  return Isolate.run(
    () => _prosesDiIsolate((
      jsonStr: jsonStr,
      waktuUnduh: waktuUnduh,
      dariCache: dariCache,
      aliasMap: aliasMap,
    )),
  );
}

class KampusRepo {
  KampusRepo(this._api);
  final ApiSumber _api;
  final Map<String, DetailKampus> _cacheDetailKampus = {};
  final Map<String, List<HasilProdi>> _cacheProdiKampus = {};

  Future<DetailKampus?> dapatkanDetailKampus(String idSp, {Kampus? fallback}) async {
    if (_cacheDetailKampus.containsKey(idSp)) {
      return _cacheDetailKampus[idSp];
    }
    final detail = await _api.ambilDetailKampus(idSp, fallback: fallback);
    if (detail != null) {
      _cacheDetailKampus[idSp] = detail;
    }
    return detail;
  }

  Future<List<HasilProdi>> dapatkanProdiKampus(String namaPt) async {
    final k = namaPt.trim().toLowerCase();
    if (_cacheProdiKampus.containsKey(k)) {
      return _cacheProdiKampus[k]!;
    }
    final list = await _api.ambilProdiKampus(namaPt);
    _cacheProdiKampus[k] = list;
    return list;
  }

  Future<Map<String, String>> _muatAlias() async {
    try {
      final str = await rootBundle.loadString('assets/alias.json');
      final map = jsonDecode(str) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k.toLowerCase().trim(), v.toString().trim()));
    } catch (_) {
      return {};
    }
  }

  Future<DataParsedKampus> muatDataKampus({
    void Function(String pesan)? onProgressUpdate,
    bool paksaSegar = false,
  }) async {
    final aliasMap = await _muatAlias();

    // 1. Cek cache berkas
    if (!paksaSegar) {
      final cache = await CacheBerkas.baca('locations');
      if (cache.data != null) {
        final waktu = cache.meta?.waktuUnduh ?? DateTime.now();
        onProgressUpdate?.call('Menyiapkan peta');
        final hasil = await _jalankanIsolateDiBackground(
          jsonStr: cache.data!,
          waktuUnduh: waktu,
          dariCache: true,
          aliasMap: aliasMap,
        );

        // Jika cache sudah lebih dari 7 hari, picu unduhan di latar belakang
        final selisihHari = DateTime.now().difference(waktu).inDays;
        if (selisihHari >= 7) {
          _unduhDanSimpanLatar();
        }

        return hasil;
      }
    }

    // 2. Unduh dari API jika cache kosong atau paksa segar
    onProgressUpdate?.call('Mengunduh daftar kampus (sekitar 1,2 MB)');

    List<dynamic>? rawList;
    bool dariAsset = false;
    try {
      rawList = await _api.ambilLocationsRaw(
        onProgress: (received, total) {
          if (total > 0) {
            final recMb = (received / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');
            final totMb = (total / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');
            onProgressUpdate?.call('Mengunduh daftar kampus. $recMb dari $totMb MB.');
          } else {
            onProgressUpdate?.call('Mengunduh daftar kampus (sekitar 1,2 MB)');
          }
        },
      );
    } catch (e) {
      // Cadangan luring: muat dari aset bawaan aplikasi jika jaringan tidak tersedia
      try {
        final bundleStr = await rootBundle.loadString('assets/data/locations.json');
        final decoded = jsonDecode(bundleStr);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          rawList = decoded['data'] as List<dynamic>;
          dariAsset = true;
        }
      } catch (_) {}

      if (rawList == null) rethrow;
    }

    onProgressUpdate?.call('Menyiapkan peta');
    final jsonStr = jsonEncode(rawList);
    final sekarang = DateTime.now();
    if (!dariAsset) {
      await CacheBerkas.simpan('locations', jsonStr, waktu: sekarang);
    }

    return _jalankanIsolateDiBackground(
      jsonStr: jsonStr,
      waktuUnduh: sekarang,
      dariCache: dariAsset,
      aliasMap: aliasMap,
    );
  }

  void _unduhDanSimpanLatar() {
    _api.ambilLocationsRaw().then((list) {
      final jsonStr = jsonEncode(list);
      CacheBerkas.simpan('locations', jsonStr, waktu: DateTime.now());
    }).catchError((_) {});
  }
}
