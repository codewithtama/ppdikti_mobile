import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/publikasi.dart';
import '../../data/model/halaman.dart';
import 'pengumuman_vm.dart';

class StatePublikasi {
  const StatePublikasi({
    required this.items,
    required this.pagination,
    required this.search,
    required this.sedangMemuatLanjutan,
  });

  final List<Publikasi> items;
  final Pagination pagination;
  final String search;
  final bool sedangMemuatLanjutan;

  StatePublikasi copyWith({
    List<Publikasi>? items,
    Pagination? pagination,
    String? search,
    bool? sedangMemuatLanjutan,
  }) =>
      StatePublikasi(
        items: items ?? this.items,
        pagination: pagination ?? this.pagination,
        search: search ?? this.search,
        sedangMemuatLanjutan: sedangMemuatLanjutan ?? this.sedangMemuatLanjutan,
      );
}

class PublikasiNotifier extends AsyncNotifier<StatePublikasi> {
  @override
  Future<StatePublikasi> build() async {
    final repo = ref.watch(kabarRepoProvider);
    final res = await repo.dapatkanPublikasi(page: 1, pageSize: 10, search: '');
    return StatePublikasi(
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
      final res = await repo.dapatkanPublikasi(
        page: 1,
        pageSize: 10,
        search: kataKunci,
      );
      return StatePublikasi(
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
      final res = await repo.dapatkanPublikasi(
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
      final res = await repo.dapatkanPublikasi(
        page: 1,
        pageSize: 10,
        search: currentSearch,
        paksaSegar: true,
      );
      return StatePublikasi(
        items: res.items,
        pagination: res.pagination,
        search: currentSearch,
        sedangMemuatLanjutan: false,
      );
    });
  }
}

final publikasiProvider = AsyncNotifierProvider<PublikasiNotifier, StatePublikasi>(
  () => PublikasiNotifier(),
);

