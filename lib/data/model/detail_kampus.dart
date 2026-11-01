class DetailKampus {
  const DetailKampus({
    required this.idSp,
    required this.kode,
    required this.nama,
    this.namaSingkat,
    this.kelompok = '',
    this.pembina = '',
    this.status = 'Aktif',
    this.akreditasi = '',
    this.statusAkreditasi = '',
    this.biayaKuliah = '',
    this.tglBerdiri,
    this.noSkPendirian,
    this.tglSkPendirian,
    this.telepon,
    this.fax,
    this.email,
    this.website,
    this.alamat,
    this.kabKota,
    this.provinsi,
    this.kodePos,
    this.lintang,
    this.bujur,
    this.jumlahProdi,
    this.rasioDosen,
  });

  final String idSp;
  final String kode;
  final String nama;
  final String? namaSingkat;
  final String kelompok;
  final String pembina;
  final String status;
  final String akreditasi;
  final String statusAkreditasi;
  final String biayaKuliah;
  final String? tglBerdiri;
  final String? noSkPendirian;
  final String? tglSkPendirian;
  final String? telepon;
  final String? fax;
  final String? email;
  final String? website;
  final String? alamat;
  final String? kabKota;
  final String? provinsi;
  final String? kodePos;
  final double? lintang;
  final double? bujur;
  final int? jumlahProdi;
  final String? rasioDosen;

  factory DetailKampus.fromJson(
    Map<String, dynamic> j, {
    String? biayaKuliahOverride,
    int? jumlahProdiOverride,
    String? rasioDosenOverride,
  }) {
    String str(String k) => ((j[k] as String?) ?? '').trim();
    double? numVal(String k) {
      final v = j[k];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final rawBiaya = biayaKuliahOverride ?? str('range_biaya_kuliah');

    return DetailKampus(
      idSp: str('id_sp'),
      kode: str('kode_pt').isNotEmpty ? str('kode_pt') : str('kode'),
      nama: str('nama_pt').isNotEmpty ? str('nama_pt') : str('nama'),
      namaSingkat: str('nm_singkat').isNotEmpty ? str('nm_singkat') : null,
      kelompok: str('kelompok'),
      pembina: str('pembina'),
      status: str('status_pt').isNotEmpty ? str('status_pt') : 'Aktif',
      akreditasi: str('akreditasi_pt'),
      statusAkreditasi: str('status_akreditasi'),
      biayaKuliah: rawBiaya,
      tglBerdiri: str('tgl_berdiri_pt'),
      noSkPendirian: str('sk_pendirian_sp'),
      tglSkPendirian: str('tgl_sk_pendirian_sp'),
      telepon: str('no_tel'),
      fax: str('no_fax'),
      email: str('email'),
      website: str('website'),
      alamat: str('alamat'),
      kabKota: str('kab_kota_pt'),
      provinsi: str('provinsi_pt'),
      kodePos: str('kode_pos'),
      lintang: numVal('lintang_pt') ?? numVal('lintang'),
      bujur: numVal('bujur_pt') ?? numVal('bujur'),
      jumlahProdi: jumlahProdiOverride,
      rasioDosen: rasioDosenOverride,
    );
  }

  DetailKampus copyWith({
    String? biayaKuliah,
    int? jumlahProdi,
    String? rasioDosen,
  }) {
    return DetailKampus(
      idSp: idSp,
      kode: kode,
      nama: nama,
      namaSingkat: namaSingkat,
      kelompok: kelompok,
      pembina: pembina,
      status: status,
      akreditasi: akreditasi,
      statusAkreditasi: statusAkreditasi,
      biayaKuliah: biayaKuliah ?? this.biayaKuliah,
      tglBerdiri: tglBerdiri,
      noSkPendirian: noSkPendirian,
      tglSkPendirian: tglSkPendirian,
      telepon: telepon,
      fax: fax,
      email: email,
      website: website,
      alamat: alamat,
      kabKota: kabKota,
      provinsi: provinsi,
      kodePos: kodePos,
      lintang: lintang,
      bujur: bujur,
      jumlahProdi: jumlahProdi ?? this.jumlahProdi,
      rasioDosen: rasioDosen ?? this.rasioDosen,
    );
  }
}
