import 'dart:typed_data';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/net/dio_klien.dart';
import '../../data/model/kampus.dart';
import '../../data/repo/kampus_repo.dart';
import '../../data/sumber/api_sumber.dart';
import 'indeks_pencarian.dart';

// Capabilities provider (Section 11.4)
class Capabilities {
  const Capabilities({
    this.cariProdi = true,
    this.cariDosen = true,
    this.cariMahasiswa = true,
    this.akreditasi = true,
  });
  final bool cariProdi, cariDosen, cariMahasiswa, akreditasi;
}

final capabilitiesProvider = Provider<Capabilities>((ref) => const Capabilities());

// Dio & API Sumber Provider
final dioProvider = Provider((ref) => buatDioKlien());
final apiSumberProvider = Provider((ref) => ApiSumber(ref.watch(dioProvider)));
final kampusRepoProvider = Provider((ref) => KampusRepo(ref.watch(apiSumberProvider)));

// State unduhan / progress kampus
final progressDaftarKampusProvider = StateProvider<String?>((ref) => null);

// Notifier pemuat data kampus
class DaftarKampusNotifier extends AsyncNotifier<DataParsedKampus> {
  @override
  Future<DataParsedKampus> build() async {
    final repo = ref.watch(kampusRepoProvider);
    final progressNotifier = ref.read(progressDaftarKampusProvider.notifier);
    return repo.muatDataKampus(
      onProgressUpdate: (pesan) {
        progressNotifier.state = pesan;
      },
    );
  }

  Future<void> segarkan() async {
    state = const AsyncValue.loading();
    final progressNotifier = ref.read(progressDaftarKampusProvider.notifier);
    progressNotifier.state = 'Mengunduh daftar kampus (sekitar 1,2 MB)';
    state = await AsyncValue.guard(() async {
      final repo = ref.read(kampusRepoProvider);
      return repo.muatDataKampus(
        paksaSegar: true,
        onProgressUpdate: (pesan) {
          progressNotifier.state = pesan;
        },
      );
    });
  }
}

final daftarKampusProvider = AsyncNotifierProvider<DaftarKampusNotifier, DataParsedKampus>(
  () => DaftarKampusNotifier(),
);

// State Query
class KampusQuery {
  const KampusQuery({
    this.q = '',
    this.kelompok = const {},
    this.pembina = const {},
    this.kota = const {},
  });

  final String q;
  final Set<String> kelompok;
  final Set<String> pembina;
  final Set<String> kota;

  bool get adaFilter =>
      q.trim().isNotEmpty ||
      kelompok.isNotEmpty ||
      pembina.isNotEmpty ||
      kota.isNotEmpty;

  int get totalKategoriFilterAktif {
    int count = 0;
    if (kelompok.isNotEmpty) count++;
    if (pembina.isNotEmpty) count++;
    if (kota.isNotEmpty) count++;
    return count;
  }

  KampusQuery copyWith({
    String? q,
    Set<String>? kelompok,
    Set<String>? pembina,
    Set<String>? kota,
  }) =>
      KampusQuery(
        q: q ?? this.q,
        kelompok: kelompok ?? this.kelompok,
        pembina: pembina ?? this.pembina,
        kota: kota ?? this.kota,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KampusQuery &&
          runtimeType == other.runtimeType &&
          q == other.q &&
          const SetEquality<String>().equals(kelompok, other.kelompok) &&
          const SetEquality<String>().equals(pembina, other.pembina) &&
          const SetEquality<String>().equals(kota, other.kota);

  @override
  int get hashCode => Object.hash(
        q,
        const SetEquality<String>().hash(kelompok),
        const SetEquality<String>().hash(pembina),
        const SetEquality<String>().hash(kota),
      );
}

class KampusQueryNotifier extends Notifier<KampusQuery> {
  @override
  KampusQuery build() => const KampusQuery();

  void perbaruiQ(String q) {
    state = state.copyWith(q: q);
  }

  void perbaruiFilter({
    Set<String>? kelompok,
    Set<String>? pembina,
    Set<String>? kota,
  }) {
    state = state.copyWith(
      kelompok: kelompok,
      pembina: pembina,
      kota: kota,
    );
  }

  void hapusSemuaFilter() {
    state = const KampusQuery();
  }

  void hapusKelompokTertentu(String k) {
    final baru = Set<String>.from(state.kelompok)..remove(k);
    state = state.copyWith(kelompok: baru);
  }

  void hapusPembinaTertentu(String p) {
    final baru = Set<String>.from(state.pembina)..remove(p);
    state = state.copyWith(pembina: baru);
  }

  void hapusKotaTertentu(String c) {
    final baru = Set<String>.from(state.kota)..remove(c);
    state = state.copyWith(kota: baru);
  }
}

final kampusQueryProvider = NotifierProvider<KampusQueryNotifier, KampusQuery>(
  () => KampusQueryNotifier(),
);

// Hasil pencarian & filter gabungan
class HasilKampus {
  const HasilKampus({
    required this.daftar,
    required this.kodeCocok,
    required this.titikRedup,
    required this.titikSorot,
    required this.adaFilter,
    required this.totalKampus,
    required this.cincinTunggal,
  });

  final List<Kampus> daftar;
  final Set<String> kodeCocok;
  final Float32List titikRedup;
  final Float32List titikSorot;
  final bool adaFilter;
  final int totalKampus;
  final Offset? cincinTunggal;
}

final hasilKampusProvider = Provider<HasilKampus>((ref) {
  final dataAsync = ref.watch(daftarKampusProvider);
  final query = ref.watch(kampusQueryProvider);

  final data = dataAsync.value;
  if (data == null) {
    return HasilKampus(
      daftar: const [],
      kodeCocok: const {},
      titikRedup: Float32List(0),
      titikSorot: Float32List(0),
      adaFilter: false,
      totalKampus: 0,
      cincinTunggal: null,
    );
  }

  final qMurni = query.q.trim();
  final adaQ = qMurni.isNotEmpty;
  final qNorm = normalisasi(qMurni);
  final kataQ = qNorm.isEmpty ? const <String>[] : qNorm.split(' ');

  // Filter kelompok, pembina, kota
  bool cocokKategori(Kampus k) {
    if (query.kelompok.isNotEmpty && !query.kelompok.contains(k.kelompok)) {
      return false;
    }
    if (query.pembina.isNotEmpty && !query.pembina.contains(k.pembina)) {
      return false;
    }
    if (query.kota.isNotEmpty) {
      if (k.kota == null || !query.kota.contains(k.kota)) {
        return false;
      }
    }
    return true;
  }

  final hasilDaftar = <({Kampus kampus, int skor})>[];

  for (final e in data.indeks) {
    if (!cocokKategori(e.kampus)) continue;

    if (!adaQ) {
      hasilDaftar.add((kampus: e.kampus, skor: 0));
    } else {
      final s = hitungSkor(
        e: e,
        q: qNorm,
        kataQ: kataQ,
        aliasMap: data.aliasMap,
      );
      if (s > 0) {
        hasilDaftar.add((kampus: e.kampus, skor: s));
      }
    }
  }

  // Urut hasil: skor menurun, lalu nama A..Z
  if (adaQ) {
    hasilDaftar.sort((a, b) {
      final cmp = b.skor.compareTo(a.skor);
      if (cmp != 0) return cmp;
      return a.kampus.nama.compareTo(b.kampus.nama);
    });
  } else {
    hasilDaftar.sort((a, b) => a.kampus.nama.compareTo(b.kampus.nama));
  }

  final daftarFinal = hasilDaftar.map((e) => e.kampus).toList();
  final kodeCocok = daftarFinal.map((e) => e.kode).toSet();

  // Hitung buffer titik peta
  final adaFilter = query.adaFilter;
  final Float32List bufferRedup;
  final Float32List bufferSorot;
  Offset? cincinTunggal;

  if (!adaFilter) {
    // Tanpa filter: semua titik digambar di lapisan redup (Warna.titikBiasa)
    bufferRedup = data.titikBiasaBuffer;
    bufferSorot = Float32List(0);
  } else {
    // Dengan filter: pisahkan titik redup dan titik sorot
    final sorotList = <({double x, double y})>[];
    final redupList = <({double x, double y})>[];

    for (final t in data.semuaTitik) {
      if (kodeCocok.contains(t.kampus.kode)) {
        sorotList.add((x: t.x, y: t.y));
      } else {
        redupList.add((x: t.x, y: t.y));
      }
    }

    bufferRedup = Float32List(redupList.length * 2);
    for (int i = 0; i < redupList.length; i++) {
      bufferRedup[i * 2] = redupList[i].x;
      bufferRedup[i * 2 + 1] = redupList[i].y;
    }

    bufferSorot = Float32List(sorotList.length * 2);
    for (int i = 0; i < sorotList.length; i++) {
      bufferSorot[i * 2] = sorotList[i].x;
      bufferSorot[i * 2 + 1] = sorotList[i].y;
    }

    // Jika tepat satu kampus berkoordinat yang cocok, buat cincin kunyit (Section 6.5)
    if (sorotList.length == 1) {
      cincinTunggal = Offset(sorotList.first.x, sorotList.first.y);
    }
  }

  return HasilKampus(
    daftar: daftarFinal,
    kodeCocok: kodeCocok,
    titikRedup: bufferRedup,
    titikSorot: bufferSorot,
    adaFilter: adaFilter,
    totalKampus: data.daftarKampus.length,
    cincinTunggal: cincinTunggal,
  );
});

// Detail Kampus Provider (by kode)
final detailKampusProvider = Provider.family<Kampus?, String>((ref, kode) {
  final data = ref.watch(daftarKampusProvider).value;
  if (data == null) return null;
  final kTrim = kode.trim();
  return data.daftarKampus.firstWhereOrNull((k) => k.kode == kTrim);
});

