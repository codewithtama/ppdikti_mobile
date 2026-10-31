import 'kampus.dart';

class HasilMahasiswa {
  const HasilMahasiswa({
    required this.id,
    required this.nama,
    required this.nim,
    required this.namaPt,
    this.singkatanPt,
    required this.namaProdi,
    this.status = 'Aktif',
    this.jenjang = 'S1',
    this.tahunMasuk,
  });

  final String id;
  final String nama;
  final String nim;
  final String namaPt;
  final String? singkatanPt;
  final String namaProdi;
  final String status;
  final String jenjang;
  final String? tahunMasuk;

  factory HasilMahasiswa.fromJson(Map<String, dynamic> json) {
    return HasilMahasiswa(
      id: (json['id'] ?? json['id_mahasiswa'] ?? '').toString(),
      nama: (json['nama'] ?? json['nama_mahasiswa'] ?? '').toString().trim(),
      nim: (json['nim'] ?? json['nomor_induk'] ?? '').toString().trim(),
      namaPt: (json['nama_pt'] ?? json['pt'] ?? '').toString().trim(),
      singkatanPt: (json['sinkatan_pt'] ?? json['singkatan_pt'])?.toString().trim(),
      namaProdi: (json['prodi'] ?? json['nama_prodi'] ?? '').toString().trim(),
      status: (json['status_saat_ini'] ?? json['status_mahasiswa'] ?? json['status'] ?? 'Aktif').toString().trim(),
      jenjang: (json['jenjang'] ?? 'Sarjana').toString().trim(),
      tahunMasuk: (json['tanggal_masuk'] ?? json['tahun_masuk'] ?? json['angkatan'])?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'nim': nim,
    'nama_pt': namaPt,
    if (singkatanPt != null) 'sinkatan_pt': singkatanPt,
    'nama_prodi': namaProdi,
    'status': status,
    'jenjang': jenjang,
    if (tahunMasuk != null) 'tahun_masuk': tahunMasuk,
  };
}

class RiwayatKuliahSemester {
  const RiwayatKuliahSemester({
    required this.semester,
    required this.status,
    required this.sks,
  });

  final String semester;
  final String status;
  final int sks;

  factory RiwayatKuliahSemester.fromJson(Map<String, dynamic> json) {
    return RiwayatKuliahSemester(
      semester: (json['semester'] ?? json['id_smt'] ?? json['nama_semester'] ?? '').toString(),
      status: (json['status'] ?? json['nm_stat_mhs'] ?? 'Aktif').toString(),
      sks: int.tryParse(json['sks']?.toString() ?? '0') ?? 0,
    );
  }
}

class DetailMahasiswa {
  const DetailMahasiswa({
    required this.ringkasan,
    this.jenisKelamin,
    this.tanggalMasuk,
    this.statusAwal = 'Peserta didik baru',
    this.statusTerakhir,
    this.kodePt,
    this.kodeProdi,
    this.tanggalLahir,
    this.tempatLahir,
    this.riwayatKuliah = const [],
    this.nomorIjazah,
    this.tanggalKeluar,
    this.tahunKeluar,
  });

  final HasilMahasiswa ringkasan;
  final String? jenisKelamin;
  final String? tanggalMasuk;
  final String statusAwal;
  final String? statusTerakhir;
  final String? kodePt;
  final String? kodeProdi;
  final String? tanggalLahir;
  final String? tempatLahir;
  final List<RiwayatKuliahSemester> riwayatKuliah;
  final String? nomorIjazah;
  final String? tanggalKeluar;
  final String? tahunKeluar;

  String get jenisPendaftaran => statusAwal;

  String get jenjangProdi {
    final j = ringkasan.jenjang.trim();
    final p = ringkasan.namaProdi.trim();
    if (j.isNotEmpty && p.isNotEmpty) {
      return '$j - $p';
    }
    return j.isNotEmpty ? j : p;
  }

  factory DetailMahasiswa.fromJson(Map<String, dynamic> json, {HasilMahasiswa? fallback}) {
    final parsedFromRaw = HasilMahasiswa.fromJson(json);
    final ringkasan = HasilMahasiswa(
      id: parsedFromRaw.id.isNotEmpty ? parsedFromRaw.id : (fallback?.id ?? ''),
      nama: parsedFromRaw.nama.isNotEmpty ? parsedFromRaw.nama : (fallback?.nama ?? ''),
      nim: parsedFromRaw.nim.isNotEmpty ? parsedFromRaw.nim : (fallback?.nim ?? ''),
      namaPt: parsedFromRaw.namaPt.isNotEmpty ? parsedFromRaw.namaPt : (fallback?.namaPt ?? ''),
      singkatanPt: parsedFromRaw.singkatanPt ?? fallback?.singkatanPt,
      namaProdi: parsedFromRaw.namaProdi.isNotEmpty ? parsedFromRaw.namaProdi : (fallback?.namaProdi ?? ''),
      status: (json['status_saat_ini'] ?? json['status_mahasiswa'] ?? json['status'] ?? fallback?.status ?? 'Aktif').toString().trim(),
      jenjang: parsedFromRaw.jenjang.isNotEmpty ? parsedFromRaw.jenjang : (fallback?.jenjang ?? 'Sarjana'),
      tahunMasuk: parsedFromRaw.tahunMasuk ?? fallback?.tahunMasuk,
    );

    final rawRiwayat = (json['riwayat_status_kuliah'] ?? json['riwayat_kuliah']) as List<dynamic>?;
    final listRiwayat = rawRiwayat != null
        ? rawRiwayat.whereType<Map<String, dynamic>>().map(RiwayatKuliahSemester.fromJson).toList()
        : <RiwayatKuliahSemester>[];

    String? jk = json['jenis_kelamin']?.toString().trim();
    if (jk == 'L' || jk == 'Laki-laki' || jk == 'LAKI-LAKI') jk = 'Laki-laki';
    if (jk == 'P' || jk == 'Perempuan' || jk == 'PEREMPUAN') jk = 'Perempuan';

    final tglMasukRaw = (json['tanggal_masuk'] ?? json['tahun_masuk'] ?? json['angkatan'] ?? ringkasan.tahunMasuk)?.toString().trim();

    return DetailMahasiswa(
      ringkasan: ringkasan,
      jenisKelamin: jk,
      tanggalMasuk: tglMasukRaw,
      statusAwal: (json['jenis_daftar'] ?? json['jenis_pendaftaran'] ?? 'Peserta didik baru').toString().trim(),
      statusTerakhir: ringkasan.status,
      kodePt: json['kode_pt']?.toString().trim(),
      kodeProdi: json['kode_prodi']?.toString().trim(),
      tanggalLahir: json['tanggal_lahir']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      riwayatKuliah: listRiwayat,
      nomorIjazah: json['nomor_ijazah']?.toString().trim(),
      tanggalKeluar: (json['tgl_keluar'] ?? json['tanggal_keluar'])?.toString().trim(),
      tahunKeluar: (json['tahun_keluar'] ?? json['thn_keluar'])?.toString().trim(),
    );
  }
}

class HasilDosen {
  const HasilDosen({
    required this.id,
    required this.nama,
    required this.nidn,
    required this.namaPt,
    this.singkatanPt,
    required this.namaProdi,
    this.status = 'Aktif',
    this.jabatanAkademik,
    this.pendidikanTertinggi,
  });

  final String id;
  final String nama;
  final String nidn;
  final String namaPt;
  final String? singkatanPt;
  final String namaProdi;
  final String status;
  final String? jabatanAkademik;
  final String? pendidikanTertinggi;

  factory HasilDosen.fromJson(Map<String, dynamic> json) {
    return HasilDosen(
      id: (json['id'] ?? json['id_sdm'] ?? '').toString(),
      nama: (json['nama'] ?? json['nama_dosen'] ?? '').toString().trim(),
      nidn: (json['nidn'] ?? json['nidk'] ?? json['nup'] ?? json['nuptk'] ?? '').toString().trim(),
      namaPt: (json['nama_pt'] ?? json['pt'] ?? '').toString().trim(),
      singkatanPt: (json['sinkatan_pt'] ?? json['singkatan_pt'])?.toString().trim(),
      namaProdi: (json['nama_prodi'] ?? json['prodi'] ?? '').toString().trim(),
      status: (json['status_aktivitas'] ?? json['status'] ?? 'Aktif').toString().trim(),
      jabatanAkademik: json['jabatan_akademik']?.toString().trim(),
      pendidikanTertinggi: json['pendidikan_tertinggi']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'nidn': nidn,
    'nama_pt': namaPt,
    if (singkatanPt != null) 'sinkatan_pt': singkatanPt,
    'nama_prodi': namaProdi,
    'status': status,
    if (jabatanAkademik != null) 'jabatan_akademik': jabatanAkademik,
    if (pendidikanTertinggi != null) 'pendidikan_tertinggi': pendidikanTertinggi,
  };
}

class RiwayatPendidikanDosen {
  const RiwayatPendidikanDosen({
    required this.jenjang,
    required this.perguruanTinggi,
    required this.bidangStudi,
    required this.tahunLulus,
  });

  final String jenjang;
  final String perguruanTinggi;
  final String bidangStudi;
  final String tahunLulus;

  factory RiwayatPendidikanDosen.fromJson(Map<String, dynamic> json) {
    return RiwayatPendidikanDosen(
      jenjang: (json['jenjang'] ?? json['nm_thn_lulus'] ?? '').toString(),
      perguruanTinggi: (json['nama_pt'] ?? json['perguruan_tinggi'] ?? '').toString(),
      bidangStudi: (json['bidang_studi'] ?? json['prodi'] ?? '').toString(),
      tahunLulus: (json['tahun_lulus'] ?? json['thn_lulus'] ?? '').toString(),
    );
  }
}

class RiwayatMengajarDosen {
  const RiwayatMengajarDosen({
    required this.semester,
    required this.mataKuliah,
    required this.kelas,
    required this.perguruanTinggi,
  });

  final String semester;
  final String mataKuliah;
  final String kelas;
  final String perguruanTinggi;

  factory RiwayatMengajarDosen.fromJson(Map<String, dynamic> json) {
    return RiwayatMengajarDosen(
      semester: (json['nama_semester'] ?? json['semester'] ?? json['id_smt'] ?? '').toString(),
      mataKuliah: (json['nama_matkul'] ?? json['matkul'] ?? '').toString(),
      kelas: (json['nama_kelas'] ?? json['kelas'] ?? '').toString(),
      perguruanTinggi: (json['nama_pt'] ?? '').toString(),
    );
  }
}

class DetailDosen {
  const DetailDosen({
    required this.ringkasan,
    this.jenisKelamin,
    this.statusIkatanKerja = 'Dosen Tetap',
    this.riwayatPendidikan = const [],
    this.riwayatMengajar = const [],
  });

  final HasilDosen ringkasan;
  final String? jenisKelamin;
  final String statusIkatanKerja;
  final List<RiwayatPendidikanDosen> riwayatPendidikan;
  final List<RiwayatMengajarDosen> riwayatMengajar;

  factory DetailDosen.fromJson(Map<String, dynamic> json, {HasilDosen? fallback}) {
    final parsedFromRaw = HasilDosen.fromJson(json);
    final ringkasan = HasilDosen(
      id: parsedFromRaw.id.isNotEmpty ? parsedFromRaw.id : (fallback?.id ?? ''),
      nama: parsedFromRaw.nama.isNotEmpty ? parsedFromRaw.nama : (fallback?.nama ?? ''),
      nidn: parsedFromRaw.nidn.isNotEmpty ? parsedFromRaw.nidn : (fallback?.nidn ?? ''),
      namaPt: parsedFromRaw.namaPt.isNotEmpty && parsedFromRaw.namaPt != 'N/A' ? parsedFromRaw.namaPt : (fallback?.namaPt ?? ''),
      singkatanPt: parsedFromRaw.singkatanPt ?? fallback?.singkatanPt,
      namaProdi: parsedFromRaw.namaProdi.isNotEmpty ? parsedFromRaw.namaProdi : (fallback?.namaProdi ?? ''),
      status: parsedFromRaw.status.isNotEmpty ? parsedFromRaw.status : (fallback?.status ?? 'Aktif'),
      jabatanAkademik: parsedFromRaw.jabatanAkademik ?? fallback?.jabatanAkademik,
      pendidikanTertinggi: parsedFromRaw.pendidikanTertinggi ?? fallback?.pendidikanTertinggi,
    );

    final rawPendidikan = (json['riwayat_pendidikan'] ?? json['study_history']) as List<dynamic>?;
    final rawMengajar = (json['riwayat_mengajar'] ?? json['teaching_history']) as List<dynamic>?;

    String? jk = json['jenis_kelamin']?.toString().trim();
    if (jk == 'L' || jk == 'Laki-laki' || jk == 'LAKI-LAKI') jk = 'Laki-laki';
    if (jk == 'P' || jk == 'Perempuan' || jk == 'PEREMPUAN') jk = 'Perempuan';

    return DetailDosen(
      ringkasan: ringkasan,
      jenisKelamin: jk,
      statusIkatanKerja: (json['status_ikatan_kerja'] ?? 'Dosen Tetap').toString(),
      riwayatPendidikan: rawPendidikan != null
          ? rawPendidikan.whereType<Map<String, dynamic>>().map(RiwayatPendidikanDosen.fromJson).toList()
          : <RiwayatPendidikanDosen>[],
      riwayatMengajar: rawMengajar != null
          ? rawMengajar.whereType<Map<String, dynamic>>().map(RiwayatMengajarDosen.fromJson).toList()
          : <RiwayatMengajarDosen>[],
    );
  }
}

class HasilProdi {
  const HasilProdi({
    required this.id,
    required this.nama,
    required this.jenjang,
    required this.pt,
    this.ptSingkat,
    this.akreditasi = 'Unggul',
    this.status = 'Aktif',
    this.rasioDosenMahasiswa,
  });

  final String id;
  final String nama;
  final String jenjang;
  final String pt;
  final String? ptSingkat;
  final String akreditasi;
  final String status;
  final String? rasioDosenMahasiswa;

  factory HasilProdi.fromJson(Map<String, dynamic> json) {
    return HasilProdi(
      id: (json['id'] ?? json['id_prodi'] ?? '').toString(),
      nama: (json['nama'] ?? json['nama_prodi'] ?? '').toString().trim(),
      jenjang: (json['jenjang'] ?? 'S1').toString().trim(),
      pt: (json['pt'] ?? json['nama_pt'] ?? '').toString().trim(),
      ptSingkat: (json['pt_singkat'] ?? json['sinkatan_pt'])?.toString().trim(),
      akreditasi: (json['akreditasi'] ?? '-').toString().trim(),
      status: (json['status_prodi'] ?? json['status'] ?? 'Aktif').toString().trim(),
      rasioDosenMahasiswa: json['rasio_dosen_mahasiswa']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'jenjang': jenjang,
    'pt': pt,
    if (ptSingkat != null) 'pt_singkat': ptSingkat,
    'akreditasi': akreditasi,
    'status': status,
    if (rasioDosenMahasiswa != null) 'rasio_dosen_mahasiswa': rasioDosenMahasiswa,
  };
}

class HasilPencarianGlobal {
  const HasilPencarianGlobal({
    this.mahasiswa = const [],
    this.dosen = const [],
    this.prodi = const [],
    this.pt = const [],
    this.dariCache = false,
  });

  final List<HasilMahasiswa> mahasiswa;
  final List<HasilDosen> dosen;
  final List<HasilProdi> prodi;
  final List<Kampus> pt;
  final bool dariCache;

  int get totalSemua => mahasiswa.length + dosen.length + prodi.length + pt.length;
  bool get kosong => totalSemua == 0;
}
