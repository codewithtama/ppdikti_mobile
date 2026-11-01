import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/detail_kampus.dart';
import '../../data/model/kelulusan.dart';
import '../../data/model/pencarian_global.dart';
import '../../data/repo/kelulusan_repo.dart';
import 'kampus_vm.dart';

final kelulusanRepoProvider = Provider((ref) => KelulusanRepo(ref.watch(apiSumberProvider)));

final kelulusanProvider = FutureProvider.family<Kelulusan, String>((ref, kode) async {
  final kampus = ref.watch(detailKampusProvider(kode));
  if (kampus == null || kampus.idSp.isEmpty) {
    return const Kelulusan(idSp: '', angka: 0.0);
  }
  final repo = ref.watch(kelulusanRepoProvider);
  return repo.dapatkanKelulusan(kode, kampus.idSp);
});

final detailProfilKampusProvider = FutureProvider.family<DetailKampus?, String>((ref, kode) async {
  final kampus = ref.watch(detailKampusProvider(kode));
  if (kampus == null) return null;
  final repo = ref.watch(kampusRepoProvider);
  return repo.dapatkanDetailKampus(kampus.idSp, fallback: kampus);
});

final prodiKampusProvider = FutureProvider.family<List<HasilProdi>, String>((ref, namaPt) async {
  final clean = namaPt.trim();
  if (clean.isEmpty) return const [];
  final repo = ref.watch(kampusRepoProvider);
  return repo.dapatkanProdiKampus(clean);
});
