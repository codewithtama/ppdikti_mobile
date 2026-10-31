import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/beranda.dart';
import '../../data/repo/beranda_repo.dart';
import '../kampus/kampus_vm.dart';

final berandaRepoProvider = Provider((ref) => BerandaRepo(ref.watch(apiSumberProvider)));

final berandaProvider = FutureProvider<({BerandaData data, bool dariCache, DateTime? waktuCache})>((ref) async {
  final repo = ref.watch(berandaRepoProvider);
  return repo.dapatkanBeranda();
});

