import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/net/galat.dart';
import '../../data/model/pencarian_global.dart';
import '../../data/repo/pencarian_repo.dart';
import '../kampus/kampus_vm.dart';

enum KategoriPencarian {
  semua('Semua'),
  kampus('Kampus'),
  mahasiswa('Mahasiswa'),
  dosen('Dosen'),
  prodi('Program Studi');

  const KategoriPencarian(this.label);
  final String label;
}

final pencarianRepoProvider = Provider<PencarianRepo>((ref) {
  final api = ref.watch(apiSumberProvider);
  final kampusRepo = ref.watch(kampusRepoProvider);
  return PencarianRepo(api, kampusRepo);
});

class StatePencarianGlobal {
  const StatePencarianGlobal({
    this.query = '',
    this.kategori = KategoriPencarian.semua,
    this.hasil = const HasilPencarianGlobal(),
    this.sedangMemuat = false,
    this.butuhVerifikasi = false,
    this.pesanGalat,
  });

  final String query;
  final KategoriPencarian kategori;
  final HasilPencarianGlobal hasil;
  final bool sedangMemuat;
  final bool butuhVerifikasi;
  final String? pesanGalat;

  StatePencarianGlobal copyWith({
    String? query,
    KategoriPencarian? kategori,
    HasilPencarianGlobal? hasil,
    bool? sedangMemuat,
    bool? butuhVerifikasi,
    String? pesanGalat,
  }) =>
      StatePencarianGlobal(
        query: query ?? this.query,
        kategori: kategori ?? this.kategori,
        hasil: hasil ?? this.hasil,
        sedangMemuat: sedangMemuat ?? this.sedangMemuat,
        butuhVerifikasi: butuhVerifikasi ?? this.butuhVerifikasi,
        pesanGalat: pesanGalat,
      );
}

class PencarianGlobalNotifier extends StateNotifier<StatePencarianGlobal> {
  PencarianGlobalNotifier(this._repo) : super(const StatePencarianGlobal());

  final PencarianRepo _repo;
  Timer? _debounceTimer;

  void aturKategori(KategoriPencarian kat) {
    if (state.kategori == kat) return;
    state = state.copyWith(kategori: kat);
  }

  void aturQuery(String q) {
    if (state.query == q) return;
    state = state.copyWith(query: q);

    _debounceTimer?.cancel();
    if (q.trim().isEmpty) {
      state = state.copyWith(
        hasil: const HasilPencarianGlobal(),
        sedangMemuat: false,
        butuhVerifikasi: false,
        pesanGalat: null,
      );
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      lakukanPencarian(q);
    });
  }

  Future<void> lakukanPencarian(String q) async {
    final kataKunci = q.trim();
    if (kataKunci.isEmpty) return;

    state = state.copyWith(sedangMemuat: true, pesanGalat: null);

    try {
      final hasil = await _repo.cari(keyword: kataKunci);
      if (state.query.trim() == kataKunci) {
        state = state.copyWith(
          hasil: hasil,
          sedangMemuat: false,
          butuhVerifikasi: false,
          pesanGalat: null,
        );
      }
    } on ButuhVerifikasiCloudflare {
      final hasilLuring = await _repo.cariLuringHanya(kataKunci);
      if (state.query.trim() == kataKunci) {
        state = state.copyWith(
          hasil: hasilLuring,
          sedangMemuat: false,
          butuhVerifikasi: true,
          pesanGalat: null,
        );
      }
    } catch (_) {
      final hasilLuring = await _repo.cariLuringHanya(kataKunci);
      if (state.query.trim() == kataKunci) {
        state = state.copyWith(
          hasil: hasilLuring,
          sedangMemuat: false,
          pesanGalat: null,
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final pencarianGlobalProvider =
    StateNotifierProvider<PencarianGlobalNotifier, StatePencarianGlobal>((ref) {
  final repo = ref.watch(pencarianRepoProvider);
  return PencarianGlobalNotifier(repo);
});
