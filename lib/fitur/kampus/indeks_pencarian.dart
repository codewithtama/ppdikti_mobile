import '../../data/model/kampus.dart';

String normalisasi(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class EntriIndeks {
  EntriIndeks(this.kampus)
      : nama = normalisasi(kampus.nama),
        kota = normalisasi(kampus.kota ?? ''),
        kata = normalisasi(kampus.nama).split(' ') {
    inisial = kata
        .where((w) => w.isNotEmpty && !_sambung.contains(w))
        .map((w) => w[0])
        .join();
  }

  final Kampus kampus;
  final String nama, kota;
  final List<String> kata;
  late final String inisial;

  static const _sambung = {'dan', 'di', 'of', 'the', 'untuk'};
}

final _semuaAngka = RegExp(r'^\d+$');

int hitungSkor({
  required EntriIndeks e,
  required String q,
  required List<String> kataQ,
  required Map<String, String> aliasMap,
}) {
  // Cek alias terlebih dahulu (contoh: "unpam" -> "041033")
  final kodeAlias = aliasMap[q];
  if (kodeAlias != null && e.kampus.kode == kodeAlias) {
    return 1000;
  }

  if (e.kampus.kode == q) return 1000;
  if (_semuaAngka.hasMatch(q)) return e.kampus.kode.startsWith(q) ? 900 : 0;
  if (e.nama == q) return 850;
  if (e.nama.startsWith(q)) return 800;
  if (e.inisial == q) return 700;
  if (kataQ.isNotEmpty && kataQ.every((t) => e.kata.any((w) => w.startsWith(t)))) {
    return 600 - e.kata.length;
  }
  if (e.nama.contains(q)) return 400;
  if (e.kota.contains(q)) return 200;
  return 0;
}

