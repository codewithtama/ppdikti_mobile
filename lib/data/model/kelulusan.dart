class Kelulusan {
  const Kelulusan({
    required this.idSp,
    required this.angka,
  });

  final String idSp;
  final double angka;

  bool get adaData => angka > 0.0;

  factory Kelulusan.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as Map<String, dynamic>?) ?? j;
    final id = (data['id_sp'] as String?)?.trim() ?? '';
    final rawRate = data['graduation_rate'];
    double rate = 0.0;
    if (rawRate is num) {
      rate = rawRate.toDouble();
    } else if (rawRate is String) {
      rate = double.tryParse(rawRate.replaceAll(',', '.')) ?? 0.0;
    }

    return Kelulusan(
      idSp: id,
      angka: rate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_sp': idSp,
        'graduation_rate': angka,
      };
}

