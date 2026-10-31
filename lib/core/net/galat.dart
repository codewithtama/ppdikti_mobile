sealed class Galat implements Exception {
  const Galat();

  String get pesan;
}

final class TanpaJaringan extends Galat {
  const TanpaJaringan();

  @override
  String get pesan => 'Daftar kampus belum pernah diunduh dan tidak ada sambungan internet.';
}

final class WaktuHabis extends Galat {
  const WaktuHabis();

  @override
  String get pesan => 'Sambungan terlalu lambat. Coba lagi.';
}

final class Server extends Galat {
  const Server(this.kode);
  final int kode;

  @override
  String get pesan => 'PDDikti tidak merespons (kode $kode).';
}

final class Ditolak extends Galat {
  const Ditolak(this.kode);
  final int kode;

  @override
  String get pesan => 'Permintaan ditolak (kode $kode).';
}

final class FormatTakTerduga extends Galat {
  const FormatTakTerduga([this.rincian]);
  final String? rincian;

  @override
  String get pesan => 'Data tidak sesuai format yang diharapkan.';
}

final class ButuhVerifikasiCloudflare extends Galat {
  const ButuhVerifikasiCloudflare();

  @override
  String get pesan => 'Server PDDikti meminta verifikasi keamanan Cloudflare.';
}

