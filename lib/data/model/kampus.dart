import 'koordinat.dart';

class Kampus {
  const Kampus({
    required this.kode,
    required this.nama,
    required this.kelompok,
    required this.pembina,
    required this.idSp,
    this.kota,
    this.koordinat,
  });

  final String kode; // sudah di-trim, kunci stabil
  final String nama;
  final String kelompok; // "N/A" dipetakan ke "Lainnya"
  final String pembina;
  final String? kota; // null bila kosong atau "Tidak Diisi"
  final String idSp; // token buram, jangan dipakai sebagai kunci
  final Koordinat? koordinat;

  factory Kampus.fromJson(Map<String, dynamic> j) {
    String teks(String k) => ((j[k] as String?) ?? '').trim();
    final kota = teks('kab_kota');
    final kelompok = teks('kelompok');
    return Kampus(
      kode: teks('kode'),
      nama: teks('nama'),
      kelompok: kelompok == 'N/A' ? 'Lainnya' : kelompok,
      pembina: teks('pembina'),
      idSp: (j['id_sp'] as String?) ?? '',
      kota: (kota.isEmpty || kota == 'Tidak Diisi') ? null : kota,
      koordinat: normalisasiKoordinat(teks('lintang'), teks('bujur')),
    );
  }

  Map<String, dynamic> toJson() => {
        'kode': kode,
        'nama': nama,
        'kelompok': kelompok,
        'pembina': pembina,
        'id_sp': idSp,
        'kab_kota': kota ?? 'Tidak Diisi',
        'lintang': koordinat?.lintang.toString() ?? '',
        'bujur': koordinat?.bujur.toString() ?? '',
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kampus &&
          runtimeType == other.runtimeType &&
          kode == other.kode;

  @override
  int get hashCode => kode.hashCode;
}

