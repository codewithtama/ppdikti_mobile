import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/pengumuman.dart';
import '../../data/model/halaman.dart';
import '../../data/repo/kabar_repo.dart';
import '../kampus/kampus_vm.dart';

final kabarRepoProvider = Provider((ref) => KabarRepo(ref.watch(apiSumberProvider)));

class StatePengumuman {
  const StatePengumuman({
    required this.items,
    required this.pagination,
    required this.search,
    required this.sedangMemuatLanjutan,
  });

  final List<Pengumuman> items;
  final Pagination pagination;
  final String search;
  final bool sedangMemuatLanjutan;

  StatePengumuman copyWith({
    List<Pengumuman>? items,
    Pagination? pagination,
    String? search,
    bool? sedangMemuatLanjutan,
  }) =>
      StatePengumuman(
        items: items ?? this.items,
        pagination: pagination ?? this.pagination,
        search: search ?? this.search,
        sedangMemuatLanjutan: sedangMemuatLanjutan ?? this.sedangMemuatLanjutan,
      );
}

class PengumumanNotifier extends AsyncNotifier<StatePengumuman> {
  @override
  Future<StatePengumuman> build() async {
    final repo = ref.watch(kabarRepoProvider);
    final res = await repo.dapatkanPengumuman(page: 1, pageSize: 10, search: '');
    return StatePengumuman(
      items: res.items,
      pagination: res.pagination,
      search: '',
      sedangMemuatLanjutan: false,
    );
  }

  Future<void> cari(String kataKunci) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(kabarRepoProvider);
      final res = await repo.dapatkanPengumuman(
        page: 1,
        pageSize: 10,
        search: kataKunci,
      );
      return StatePengumuman(
        items: res.items,
        pagination: res.pagination,
        search: kataKunci,
        sedangMemuatLanjutan: false,
      );
    });
  }

  Future<void> muatLanjutan() async {
    final current = state.value;
    if (current == null || current.sedangMemuatLanjutan || !current.pagination.adaLanjutan) {
      return;
    }

    state = AsyncValue.data(current.copyWith(sedangMemuatLanjutan: true));
    try {
      final repo = ref.read(kabarRepoProvider);
      final nextPage = current.pagination.page + 1;
      final res = await repo.dapatkanPengumuman(
        page: nextPage,
        pageSize: 10,
        search: current.search,
      );

      final gabungan = [...current.items, ...res.items];
      state = AsyncValue.data(current.copyWith(
        items: gabungan,
        pagination: res.pagination,
        sedangMemuatLanjutan: false,
      ));
    } catch (_) {
      state = AsyncValue.data(current.copyWith(sedangMemuatLanjutan: false));
    }
  }

  Future<void> segarkan() async {
    final currentSearch = state.value?.search ?? '';
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(kabarRepoProvider);
      final res = await repo.dapatkanPengumuman(
        page: 1,
        pageSize: 10,
        search: currentSearch,
        paksaSegar: true,
      );
      return StatePengumuman(
        items: res.items,
        pagination: res.pagination,
        search: currentSearch,
        sedangMemuatLanjutan: false,
      );
    });
  }
}

final pengumumanProvider = AsyncNotifierProvider<PengumumanNotifier, StatePengumuman>(
  () => PengumumanNotifier(),
);

