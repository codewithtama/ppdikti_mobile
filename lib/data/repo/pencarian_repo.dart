import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/net/galat.dart';
import '../model/kampus.dart';
import '../model/pencarian_global.dart';
import '../sumber/api_sumber.dart';
import 'kampus_repo.dart';

class PencarianRepo {
  PencarianRepo(this._api, this._kampusRepo);
  final ApiSumber _api;
  final KampusRepo _kampusRepo;

  Map<String, dynamic>? _cacheSample;

  Future<Map<String, dynamic>> _muatSamplePencarian() async {
    if (_cacheSample != null) return _cacheSample!;
    try {
      final str = await rootBundle.loadString('assets/data/sample_pencarian.json');
      _cacheSample = jsonDecode(str) as Map<String, dynamic>;
      return _cacheSample!;
    } catch (_) {
      return {};
    }
  }

  Future<HasilPencarianGlobal> cari({
    required String keyword,
    bool forceOffline = false,
  }) async {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) return const HasilPencarianGlobal();

    // 1. Jika tidak dipaksa luring, coba ke API resmi dulu
    if (!forceOffline) {
      try {
        final hasilApi = await _api.cariGlobal(keyword);
        if (!hasilApi.kosong) {
          return hasilApi;
        }
      } on ButuhVerifikasiCloudflare {
        // Rethrow agar UI tahu bahwa Cloudflare meminta verifikasi
        rethrow;
      } catch (_) {
        // Fallback jika terjadi galat koneksi lain
      }
    }

    // 2. Fallback luring terpadu
    return _cariLuring(q);
  }

  Future<HasilPencarianGlobal> cariLuringHanya(String keyword) async {
    final q = keyword.trim().toLowerCase();
    return _cariLuring(q);
  }

  Future<HasilPencarianGlobal> _cariLuring(String query) async {
    final sample = await _muatSamplePencarian();

    final rawMhs = (sample['mahasiswa'] as List<dynamic>?) ?? [];
    final rawDosen = (sample['dosen'] as List<dynamic>?) ?? [];
    final rawProdi = (sample['prodi'] as List<dynamic>?) ?? [];

    final listMhs = <HasilMahasiswa>[];
    for (final item in rawMhs) {
      if (item is Map<String, dynamic>) {
        final nama = (item['nama'] ?? '').toString().toLowerCase();
        final nim = (item['nim'] ?? '').toString().toLowerCase();
        final pt = (item['nama_pt'] ?? item['singkatan_pt'] ?? '').toString().toLowerCase();
        final prodi = (item['nama_prodi'] ?? '').toString().toLowerCase();

        if (nama.contains(query) || nim.contains(query) || pt.contains(query) || prodi.contains(query)) {
          listMhs.add(HasilMahasiswa.fromJson(item));
        }
      }
    }

    final listDosen = <HasilDosen>[];
    for (final item in rawDosen) {
      if (item is Map<String, dynamic>) {
        final nama = (item['nama'] ?? '').toString().toLowerCase();
        final nidn = (item['nidn'] ?? '').toString().toLowerCase();
        final pt = (item['nama_pt'] ?? item['singkatan_pt'] ?? '').toString().toLowerCase();
        final prodi = (item['nama_prodi'] ?? '').toString().toLowerCase();

        if (nama.contains(query) || nidn.contains(query) || pt.contains(query) || prodi.contains(query)) {
          listDosen.add(HasilDosen.fromJson(item));
        }
      }
    }

    final listProdi = <HasilProdi>[];
    for (final item in rawProdi) {
      if (item is Map<String, dynamic>) {
        final nama = (item['nama'] ?? '').toString().toLowerCase();
        final pt = (item['pt'] ?? item['pt_singkat'] ?? '').toString().toLowerCase();
        final jenjang = (item['jenjang'] ?? '').toString().toLowerCase();

        if (nama.contains(query) || pt.contains(query) || jenjang.contains(query)) {
          listProdi.add(HasilProdi.fromJson(item));
        }
      }
    }

    // Cari juga kampus dari direktori 4.342 kampus
    final listPt = <Kampus>[];
    try {
      final dataKampus = await _kampusRepo.muatDataKampus();
      for (final kampus in dataKampus.daftarKampus) {
        final nama = kampus.nama.toLowerCase();
        final kode = kampus.kode.toLowerCase();
        final kota = (kampus.kota ?? '').toLowerCase();
        if (nama.contains(query) || kode.contains(query) || kota.contains(query)) {
          listPt.add(kampus);
          if (listPt.length >= 25) break; // Batasi untuk efisiensi
        }
      }
    } catch (_) {}

    return HasilPencarianGlobal(
      mahasiswa: listMhs,
      dosen: listDosen,
      prodi: listProdi,
      pt: listPt,
      dariCache: true,
    );
  }

  Future<DetailMahasiswa?> ambilDetailMahasiswa(String id, {HasilMahasiswa? fallback}) async {
    try {
      final res = await _api.ambilDetailMahasiswa(id, ringkasan: fallback);
      if (res != null) return res;
    } catch (_) {}

    // Cari dari sample luring
    final sample = await _muatSamplePencarian();
    final rawMhs = (sample['mahasiswa'] as List<dynamic>?) ?? [];
    for (final item in rawMhs) {
      if (item is Map<String, dynamic> && item['id'] == id) {
        return DetailMahasiswa.fromJson(item, fallback: fallback);
      }
    }

    return fallback != null ? DetailMahasiswa(ringkasan: fallback) : null;
  }

  Future<DetailDosen?> ambilDetailDosen(String id, {HasilDosen? fallback}) async {
    try {
      final res = await _api.ambilDetailDosen(id, ringkasan: fallback);
      if (res != null) return res;
    } catch (_) {}

    // Cari dari sample luring
    final sample = await _muatSamplePencarian();
    final rawDosen = (sample['dosen'] as List<dynamic>?) ?? [];
    for (final item in rawDosen) {
      if (item is Map<String, dynamic> && item['id'] == id) {
        return DetailDosen.fromJson(item, fallback: fallback);
      }
    }

    return fallback != null ? DetailDosen(ringkasan: fallback) : null;
  }
}
