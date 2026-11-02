import '../../data/model/detail_kampus.dart';
import '../../data/model/kampus.dart';
import '../../data/model/pencarian_global.dart';

/// Model representasi data kampus untuk komparasi matriks
class ItemKomparasiKampus {
  const ItemKomparasiKampus({
    required this.kode,
    required this.nama,
    required this.idSp,
    this.kelompok = '',
    this.pembina = '',
    this.kota,
    this.provinsi,
    this.status = 'Aktif',
    this.akreditasi = '',
    this.rasioDosen,
    this.biayaKuliah,
    this.jumlahProdi,
    this.tglBerdiri,
    this.noSkPendirian,
    this.website,
  });

  final String kode;
  final String nama;
  final String idSp;
  final String kelompok;
  final String pembina;
  final String? kota;
  final String? provinsi;
  final String status;
  final String akreditasi;
  final String? rasioDosen;
  final String? biayaKuliah;
  final int? jumlahProdi;
  final String? tglBerdiri;
  final String? noSkPendirian;
  final String? website;

  factory ItemKomparasiKampus.dariKampus(Kampus k, {DetailKampus? detail}) {
    return ItemKomparasiKampus(
      kode: k.kode,
      nama: k.nama,
      idSp: k.idSp,
      kelompok: k.kelompok,
      pembina: k.pembina,
      kota: k.kota,
      provinsi: k.provinsi,
      status: k.status,
      akreditasi: detail?.akreditasi.isNotEmpty == true ? detail!.akreditasi : k.akreditasi,
      rasioDosen: detail?.rasioDosen,
      biayaKuliah: detail?.biayaKuliah.isNotEmpty == true ? detail!.biayaKuliah : null,
      jumlahProdi: detail?.jumlahProdi,
      tglBerdiri: detail?.tglBerdiri,
      noSkPendirian: detail?.noSkPendirian,
      website: detail?.website,
    );
  }

  factory ItemKomparasiKampus.dariDetail(DetailKampus d) {
    return ItemKomparasiKampus(
      kode: d.kode,
      nama: d.nama,
      idSp: d.idSp,
      kelompok: d.kelompok,
      pembina: d.pembina,
      kota: d.kabKota,
      provinsi: d.provinsi,
      status: d.status,
      akreditasi: d.akreditasi,
      rasioDosen: d.rasioDosen,
      biayaKuliah: d.biayaKuliah.isNotEmpty ? d.biayaKuliah : null,
      jumlahProdi: d.jumlahProdi,
      tglBerdiri: d.tglBerdiri,
      noSkPendirian: d.noSkPendirian,
      website: d.website,
    );
  }

  ItemKomparasiKampus salinDenganDetail(DetailKampus d) {
    return ItemKomparasiKampus(
      kode: kode,
      nama: d.nama.isNotEmpty ? d.nama : nama,
      idSp: d.idSp.isNotEmpty ? d.idSp : idSp,
      kelompok: d.kelompok.isNotEmpty ? d.kelompok : kelompok,
      pembina: d.pembina.isNotEmpty ? d.pembina : pembina,
      kota: d.kabKota ?? kota,
      provinsi: d.provinsi ?? provinsi,
      status: d.status.isNotEmpty ? d.status : status,
      akreditasi: d.akreditasi.isNotEmpty ? d.akreditasi : akreditasi,
      rasioDosen: d.rasioDosen ?? rasioDosen,
      biayaKuliah: (d.biayaKuliah.isNotEmpty) ? d.biayaKuliah : biayaKuliah,
      jumlahProdi: d.jumlahProdi ?? jumlahProdi,
      tglBerdiri: d.tglBerdiri ?? tglBerdiri,
      noSkPendirian: d.noSkPendirian ?? noSkPendirian,
      website: d.website ?? website,
    );
  }
}

/// Model representasi data program studi untuk komparasi matriks
class ItemKomparasiProdi {
  const ItemKomparasiProdi({
    required this.id,
    required this.nama,
    required this.jenjang,
    required this.pt,
    this.ptSingkat,
    this.akreditasi = '',
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

  factory ItemKomparasiProdi.dariHasilProdi(HasilProdi p) {
    return ItemKomparasiProdi(
      id: p.id,
      nama: p.nama,
      jenjang: p.jenjang,
      pt: p.pt,
      ptSingkat: p.ptSingkat,
      akreditasi: p.akreditasi,
      status: p.status,
      rasioDosenMahasiswa: p.rasioDosenMahasiswa,
    );
  }
}

/// Status keseluruhan komparasi
class KomparasiState {
  const KomparasiState({
    this.daftarKampus = const [],
    this.daftarProdi = const [],
  });

  final List<ItemKomparasiKampus> daftarKampus;
  final List<ItemKomparasiProdi> daftarProdi;

  static const int maksSlot = 3;

  bool get bisaTambahKampus => daftarKampus.length < maksSlot;
  bool get bisaTambahProdi => daftarProdi.length < maksSlot;
  int get totalSemuaItem => daftarKampus.length + daftarProdi.length;

  bool apakahKampusAda(String kode) =>
      daftarKampus.any((k) => k.kode.trim().toLowerCase() == kode.trim().toLowerCase());

  bool apakahProdiAda(String id) =>
      daftarProdi.any((p) => p.id.trim().toLowerCase() == id.trim().toLowerCase());

  KomparasiState copyWith({
    List<ItemKomparasiKampus>? daftarKampus,
    List<ItemKomparasiProdi>? daftarProdi,
  }) {
    return KomparasiState(
      daftarKampus: daftarKampus ?? this.daftarKampus,
      daftarProdi: daftarProdi ?? this.daftarProdi,
    );
  }
}
