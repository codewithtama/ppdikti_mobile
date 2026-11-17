import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sumber/db_lokal.dart';

final dbLokalProvider = Provider<DbLokal>((ref) {
  final db = DbLokal();
  ref.onDispose(db.tutup);
  return db;
});

class FavoritNotifier extends StateNotifier<List<ItemFavorit>> {
  FavoritNotifier(this._db) : super(const []) {
    muatUlang();
  }

  final DbLokal _db;

  Future<void> muatUlang() async {
    try {
      final daftar = await _db.ambilSemuaFavorit();
      if (mounted) state = daftar;
    } catch (_) {}
  }

  bool apakahFavorit(String id, TipeFavorit tipe) {
    return state.any((item) => item.id == id && item.tipe == tipe);
  }

  Future<bool> toggleFavorit(ItemFavorit item) async {
    final sudahAda = apakahFavorit(item.id, item.tipe);
    if (sudahAda) {
      await _db.hapusFavorit(item.id, item.tipe);
      state = state
          .where((e) => !(e.id == item.id && e.tipe == item.tipe))
          .toList();
      return false;
    } else {
      await _db.simpanFavorit(item);
      state = [
        item,
        ...state.where((e) => !(e.id == item.id && e.tipe == item.tipe)),
      ];
      return true;
    }
  }

  Future<void> hapus(String id, TipeFavorit tipe) async {
    await _db.hapusFavorit(id, tipe);
    state = state.where((e) => !(e.id == id && e.tipe == tipe)).toList();
  }
}

final favoritProvider =
    StateNotifierProvider<FavoritNotifier, List<ItemFavorit>>((ref) {
  return FavoritNotifier(ref.watch(dbLokalProvider));
});

class RiwayatPencarianNotifier extends StateNotifier<List<String>> {
  RiwayatPencarianNotifier(this._db) : super(const []) {
    muatUlang();
  }

  final DbLokal _db;

  Future<void> muatUlang() async {
    try {
      final daftar = await _db.ambilRiwayat();
      if (mounted) state = daftar;
    } catch (_) {}
  }

  Future<void> tambah(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return;
    try {
      await _db.simpanRiwayat(clean);
      await muatUlang();
    } catch (_) {}
  }

  Future<void> hapus(String query) async {
    try {
      await _db.hapusRiwayat(query);
      state = state.where((q) => q != query).toList();
    } catch (_) {}
  }

  Future<void> bersihkanSemua() async {
    try {
      await _db.bersihkanRiwayat();
      state = const [];
    } catch (_) {}
  }
}

final riwayatPencarianProvider =
    StateNotifierProvider<RiwayatPencarianNotifier, List<String>>((ref) {
  return RiwayatPencarianNotifier(ref.watch(dbLokalProvider));
});
