import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/detail_kampus.dart';
import '../../data/model/kampus.dart';
import '../../data/model/pencarian_global.dart';
import '../kampus/kampus_vm.dart';
import 'komparasi_model.dart';

class KomparasiNotifier extends StateNotifier<KomparasiState> {
  KomparasiNotifier(this._ref) : super(const KomparasiState());

  final Ref _ref;

  /// Tambah kampus ke perbandingan (maks 3)
  bool tambahKampus(Kampus kampus, {DetailKampus? detail}) {
    if (state.apakahKampusAda(kampus.kode)) {
      hapusKampus(kampus.kode);
      return false;
    }
    if (!state.bisaTambahKampus) return false;

    final item = ItemKomparasiKampus.dariKampus(kampus, detail: detail);
    final baru = [...state.daftarKampus, item];
    state = state.copyWith(daftarKampus: baru);

    // Jika detail belum lengkap, ambil secara asinkron di latar belakang
    if (detail == null && kampus.idSp.isNotEmpty) {
      _perkayaDetailKampus(kampus.idSp, kampus.kode);
    }
    return true;
  }

  /// Tambah dari DetailKampus
  bool tambahDariDetail(DetailKampus detail) {
    if (state.apakahKampusAda(detail.kode)) {
      hapusKampus(detail.kode);
      return false;
    }
    if (!state.bisaTambahKampus) return false;

    final item = ItemKomparasiKampus.dariDetail(detail);
    state = state.copyWith(daftarKampus: [...state.daftarKampus, item]);
    return true;
  }

  /// Hapus kampus dari perbandingan
  void hapusKampus(String kode) {
    final baru = state.daftarKampus
        .where((k) => k.kode.trim().toLowerCase() != kode.trim().toLowerCase())
        .toList();
    state = state.copyWith(daftarKampus: baru);
  }

  /// Tambah prodi ke perbandingan (maks 3)
  bool tambahProdi(HasilProdi prodi) {
    if (state.apakahProdiAda(prodi.id)) {
      hapusProdi(prodi.id);
      return false;
    }
    if (!state.bisaTambahProdi) return false;

    final item = ItemKomparasiProdi.dariHasilProdi(prodi);
    state = state.copyWith(daftarProdi: [...state.daftarProdi, item]);
    return true;
  }

  /// Hapus prodi dari perbandingan
  void hapusProdi(String id) {
    final baru = state.daftarProdi
        .where((p) => p.id.trim().toLowerCase() != id.trim().toLowerCase())
        .toList();
    state = state.copyWith(daftarProdi: baru);
  }

  /// Kosongkan daftar komparasi
  void bersihkanSemua() {
    state = const KomparasiState();
  }

  /// Kosongkan hanya kategori kampus
  void bersihkanKampus() {
    state = state.copyWith(daftarKampus: const []);
  }

  /// Kosongkan hanya kategori prodi
  void bersihkanProdi() {
    state = state.copyWith(daftarProdi: const []);
  }

  Future<void> _perkayaDetailKampus(String idSp, String kode) async {
    try {
      final repo = _ref.read(kampusRepoProvider);
      final d = await repo.dapatkanDetailKampus(idSp);
      if (d == null) return;

      final index = state.daftarKampus.indexWhere(
        (k) => k.kode.trim().toLowerCase() == kode.trim().toLowerCase(),
      );
      if (index != -1) {
        final listBaru = List<ItemKomparasiKampus>.from(state.daftarKampus);
        listBaru[index] = listBaru[index].salinDenganDetail(d);
        state = state.copyWith(daftarKampus: listBaru);
      }
    } catch (_) {}
  }
}

final komparasiProvider = StateNotifierProvider<KomparasiNotifier, KomparasiState>((ref) {
  return KomparasiNotifier(ref);
});

