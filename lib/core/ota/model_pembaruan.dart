class InfoPembaruan {
  const InfoPembaruan({
    required this.versi,
    required this.nomorBuild,
    required this.tanggalRilis,
    required this.catatanRilis,
    required this.tautanUnduh,
    this.sha256,
    this.pembaruanWajib = false,
    this.ukuranMb,
  });

  final String versi;
  final int nomorBuild;
  final String tanggalRilis;
  final List<String> catatanRilis;
  final String tautanUnduh;
  final String? sha256;
  final bool pembaruanWajib;
  final double? ukuranMb;

  factory InfoPembaruan.fromJson(Map<String, dynamic> json) {
    final rawNotes = json['changelog'];
    final List<String> notes;
    if (rawNotes is List) {
      notes = rawNotes.map((e) => e.toString()).toList();
    } else if (rawNotes is String) {
      notes = [rawNotes];
    } else {
      notes = [];
    }

    return InfoPembaruan(
      versi: (json['version'] ?? json['versi'] ?? '1.0.0').toString(),
      nomorBuild: int.tryParse((json['build_number'] ?? json['nomor_build'] ?? '1').toString()) ?? 1,
      tanggalRilis: (json['release_date'] ?? json['tanggal_rilis'] ?? '').toString(),
      catatanRilis: notes,
      tautanUnduh: (json['download_url'] ?? json['tautan_unduh'] ?? '').toString(),
      sha256: json['sha256']?.toString(),
      pembaruanWajib: json['force_update'] == true || json['wajib'] == true,
      ukuranMb: double.tryParse((json['size_mb'] ?? json['ukuran_mb'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': versi,
    'build_number': nomorBuild,
    'release_date': tanggalRilis,
    'changelog': catatanRilis,
    'download_url': tautanUnduh,
    if (sha256 != null) 'sha256': sha256,
    'force_update': pembaruanWajib,
    if (ukuranMb != null) 'size_mb': ukuranMb,
  };
}

class StatusCekPembaruan {
  const StatusCekPembaruan({
    required this.adaPembaruan,
    this.info,
    this.versiSaatIni = '',
    this.buildSaatIni = 0,
    this.pesan,
  });

  final bool adaPembaruan;
  final InfoPembaruan? info;
  final String versiSaatIni;
  final int buildSaatIni;
  final String? pesan;
}
