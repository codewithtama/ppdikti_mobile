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
    this.provinsi,
    this.status = 'Aktif',
    this.akreditasi = '',
  });

  final String kode; // sudah di-trim, kunci stabil
  final String nama;
  final String kelompok; // "N/A" dipetakan ke "Lainnya"
  final String pembina;
  final String? kota; // null bila kosong atau "Tidak Diisi"
  final String idSp; // token buram, jangan dipakai sebagai kunci
  final Koordinat? koordinat;
  final String? provinsi;
  final String status;
  final String akreditasi;

  static String deteksiProvinsi(String? kabKota, String pembina) {
    final k = (kabKota ?? '').toLowerCase();
    final p = pembina.toLowerCase();

    // 1. Deteksi berbasis nama kota / kabupaten
    if (k.contains('aceh')) return 'Aceh';
    if (k.contains('sumatera utara') || k.contains('medan') || k.contains('deli') || k.contains('binjai') || k.contains('asahan') || k.contains('simalungun')) return 'Sumatera Utara';
    if (k.contains('sumatera barat') || k.contains('padang') || k.contains('bukittinggi') || k.contains('payakumbuh') || k.contains('tanah datar')) return 'Sumatera Barat';
    if (k.contains('sumatera selatan') || k.contains('palembang') || k.contains('ogan') || k.contains('prabumulih')) return 'Sumatera Selatan';
    if (k.contains('kepulauan riau') || k.contains('batam') || k.contains('tanjungpinang')) return 'Kepulauan Riau';
    if (k.contains('riau') || k.contains('pekanbaru') || k.contains('dumai') || k.contains('kampar')) return 'Riau';
    if (k.contains('jambi')) return 'Jambi';
    if (k.contains('bengkulu')) return 'Bengkulu';
    if (k.contains('bangka') || k.contains('belitung')) return 'Bangka Belitung';
    if (k.contains('lampung')) return 'Lampung';
    if (k.contains('jakarta')) return 'DKI Jakarta';
    if (k.contains('banten') || k.contains('tangerang') || k.contains('serang') || k.contains('cilegon') || k.contains('lebak') || k.contains('pandeglang')) return 'Banten';
    if (k.contains('jawa barat') || k.contains('bandung') || k.contains('bogor') || k.contains('depok') || k.contains('bekasi') || k.contains('cimahi') || k.contains('tasik') || k.contains('cirebon') || k.contains('sukabumi') || k.contains('garut') || k.contains('karawang') || k.contains('subang')) return 'Jawa Barat';
    if (k.contains('jawa tengah') || k.contains('semarang') || k.contains('surakarta') || k.contains('solo') || k.contains('magelang') || k.contains('salatiga') || k.contains('banyumas') || k.contains('purwokerto') || k.contains('kudus') || k.contains('pekalongan') || k.contains('tegal')) return 'Jawa Tengah';
    if (k.contains('yogyakarta') || k.contains('sleman') || k.contains('bantul') || k.contains('kulon progo') || k.contains('gunungkidul')) return 'D.I. Yogyakarta';
    if (k.contains('jawa timur') || k.contains('surabaya') || k.contains('malang') || k.contains('kediri') || k.contains('jember') || k.contains('madiun') || k.contains('sidoarjo') || k.contains('gresik') || k.contains('banyuwangi') || k.contains('blitar') || k.contains('pasuruan')) return 'Jawa Timur';
    if (k.contains('denpasar') || k.contains('bali') || k.contains('badung') || k.contains('buleleng') || k.contains('gianyar')) return 'Bali';
    if (k.contains('nusa tenggara barat') || k.contains('mataram') || k.contains('lombok') || k.contains('bima') || k.contains('sumbawa')) return 'Nusa Tenggara Barat';
    if (k.contains('nusa tenggara timur') || k.contains('kupang') || k.contains('timor') || k.contains('flores') || k.contains('sumba')) return 'Nusa Tenggara Timur';
    if (k.contains('kalimantan barat') || k.contains('pontianak') || k.contains('singkawang')) return 'Kalimantan Barat';
    if (k.contains('kalimantan tengah') || k.contains('palangka') || k.contains('kotawaringin')) return 'Kalimantan Tengah';
    if (k.contains('kalimantan selatan') || k.contains('banjarmasin') || k.contains('banjarbaru') || k.contains('martapura')) return 'Kalimantan Selatan';
    if (k.contains('kalimantan timur') || k.contains('samarinda') || k.contains('balikpapan') || k.contains('kutai') || k.contains('bontang')) return 'Kalimantan Timur';
    if (k.contains('kalimantan utara') || k.contains('tarakan') || k.contains('bulungan')) return 'Kalimantan Utara';
    if (k.contains('sulawesi utara') || k.contains('manado') || k.contains('tomohon') || k.contains('minahasa')) return 'Sulawesi Utara';
    if (k.contains('gorontalo')) return 'Gorontalo';
    if (k.contains('sulawesi tengah') || k.contains('palu') || k.contains('poso')) return 'Sulawesi Tengah';
    if (k.contains('sulawesi barat') || k.contains('mamuju') || k.contains('polewali')) return 'Sulawesi Barat';
    if (k.contains('sulawesi selatan') || k.contains('makassar') || k.contains('gowa') || k.contains('palopo') || k.contains('parepare')) return 'Sulawesi Selatan';
    if (k.contains('sulawesi tenggara') || k.contains('kendari') || k.contains('baubau')) return 'Sulawesi Tenggara';
    if (k.contains('maluku utara') || k.contains('ternate') || k.contains('tidore')) return 'Maluku Utara';
    if (k.contains('maluku') || k.contains('ambon')) return 'Maluku';
    if (k.contains('papua') || k.contains('jayapura') || k.contains('merauke') || k.contains('sorong') || k.contains('manokwari')) return 'Papua';

    // 2. Deteksi berbasis pembina LLDIKTI
    final matchLldikti = RegExp(r'lldikti\s+([0-9]+|[ivxlc]+)\b', caseSensitive: false).firstMatch(p);
    if (matchLldikti != null) {
      final romawi = matchLldikti.group(1)!.toLowerCase();
      switch (romawi) {
        case '1':
        case 'i':
          return 'Sumatera Utara';
        case '2':
        case 'ii':
          return 'Sumatera Selatan';
        case '3':
        case 'iii':
          return 'DKI Jakarta';
        case '4':
        case 'iv':
          return 'Jawa Barat';
        case '5':
        case 'v':
          return 'D.I. Yogyakarta';
        case '6':
        case 'vi':
          return 'Jawa Tengah';
        case '7':
        case 'vii':
          return 'Jawa Timur';
        case '8':
        case 'viii':
          return 'Bali';
        case '9':
        case 'ix':
          return 'Sulawesi Selatan';
        case '10':
        case 'x':
          return 'Sumatera Barat';
        case '11':
        case 'xi':
          return 'Kalimantan Selatan';
        case '12':
        case 'xii':
          return 'Maluku';
        case '13':
        case 'xiii':
          return 'Aceh';
        case '14':
        case 'xiv':
          return 'Papua';
        case '15':
        case 'xv':
          return 'Nusa Tenggara Timur';
        case '16':
        case 'xvi':
          return 'Sulawesi Utara';
      }
    }

    return 'Lainnya';
  }

  factory Kampus.fromJson(Map<String, dynamic> j) {
    String teks(String k) => ((j[k] as String?) ?? '').trim();
    final kota = teks('kab_kota');
    final kelompok = teks('kelompok');
    final pembina = teks('pembina');
    final status = teks('status_pt').isNotEmpty ? teks('status_pt') : 'Aktif';
    final akreditasi = teks('akreditasi_pt');
    final prov = teks('provinsi_pt').isNotEmpty
        ? teks('provinsi_pt')
        : deteksiProvinsi(kota, pembina);

    return Kampus(
      kode: teks('kode'),
      nama: teks('nama'),
      kelompok: kelompok == 'N/A' ? 'Lainnya' : kelompok,
      pembina: pembina,
      idSp: (j['id_sp'] as String?) ?? '',
      kota: (kota.isEmpty || kota == 'Tidak Diisi') ? null : kota,
      koordinat: normalisasiKoordinat(teks('lintang'), teks('bujur')),
      provinsi: prov,
      status: status,
      akreditasi: akreditasi,
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
        'provinsi': provinsi,
        'status': status,
        'akreditasi': akreditasi,
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
