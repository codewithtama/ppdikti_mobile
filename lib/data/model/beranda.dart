import '../../core/format/angka.dart';

class Statistik {
  const Statistik({
    required this.jumlahKampus,
    required this.jumlahProdi,
    required this.jumlahDosen,
    required this.jumlahMahasiswa,
  });

  final int jumlahKampus;
  final int jumlahProdi;
  final int jumlahDosen;
  final int jumlahMahasiswa;

  factory Statistik.fromJson(Map<String, dynamic> j) {
    int ambilInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val.replaceAll('.', '')) ?? 0;
      return 0;
    }

    final pt = j['pt'] as Map<String, dynamic>?;
    final prodi = j['prodi'] as Map<String, dynamic>?;
    final dosen = j['dosen'] as Map<String, dynamic>?;
    final mhs = j['mahasiswa'] as Map<String, dynamic>?;

    return Statistik(
      jumlahKampus: ambilInt(pt?['jumlah']),
      jumlahProdi: ambilInt(prodi?['jumlah']),
      jumlahDosen: ambilInt(dosen?['jumlah_dosen']),
      jumlahMahasiswa: ambilInt(mhs?['jumlah_mahasiswa']),
    );
  }

  Map<String, dynamic> toJson() => {
        'pt': {'jumlah': jumlahKampus},
        'prodi': {'jumlah': jumlahProdi},
        'dosen': {'jumlah_dosen': jumlahDosen},
        'mahasiswa': {'jumlah_mahasiswa': jumlahMahasiswa},
      };
}

class BidangIlmu {
  const BidangIlmu({
    required this.nama,
    required this.totalMahasiswa,
    required this.persenLulusStr,
    required this.persenLulus,
  });

  final String nama;
  final int totalMahasiswa;
  final String persenLulusStr; // contoh "52,88"
  final double persenLulus;

  factory BidangIlmu.fromJson(Map<String, dynamic> j) {
    final nama = (j['bidang_ilmu'] as String?)?.trim() ?? '';
    final total = j['total_mahasiswa'];
    int totalMhs = 0;
    if (total is int) {
      totalMhs = total;
    } else if (total is num) {
      totalMhs = total.toInt();
    } else if (total is String) {
      totalMhs = int.tryParse(total.replaceAll('.', '')) ?? 0;
    }

    final persenStr = (j['persentase_kelulusan'] as String?)?.trim() ?? '0';
    final persenDouble = FormatAngka.parseDesimalKoma(persenStr) ?? 0.0;

    return BidangIlmu(
      nama: nama,
      totalMahasiswa: totalMhs,
      persenLulusStr: persenStr,
      persenLulus: persenDouble,
    );
  }

  Map<String, dynamic> toJson() => {
        'bidang_ilmu': nama,
        'total_mahasiswa': totalMahasiswa,
        'persentase_kelulusan': persenLulusStr,
      };
}

class BerandaData {
  const BerandaData({
    required this.statistik,
    required this.bidangIlmu,
  });

  final Statistik statistik;
  final List<BidangIlmu> bidangIlmu;

  factory BerandaData.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as Map<String, dynamic>?) ?? j;
    final stat = Statistik.fromJson(data);

    final rawList = data['bidang_ilmu'] as List<dynamic>? ?? [];
    final list = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => BidangIlmu.fromJson(e))
        .toList();

    return BerandaData(
      statistik: stat,
      bidangIlmu: list,
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          ...statistik.toJson(),
          'bidang_ilmu': bidangIlmu.map((e) => e.toJson()).toList(),
        }
      };
}

