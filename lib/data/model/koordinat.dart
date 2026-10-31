class Koordinat {
  const Koordinat(this.lintang, this.bujur, {this.dikoreksi = false});
  final double lintang, bujur;
  final bool dikoreksi;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Koordinat &&
          runtimeType == other.runtimeType &&
          lintang == other.lintang &&
          bujur == other.bujur &&
          dikoreksi == other.dikoreksi;

  @override
  int get hashCode => Object.hash(lintang, bujur, dikoreksi);
}

bool _dalamIndonesia(double lintang, double bujur) =>
    lintang >= -11.5 && lintang <= 6.5 && bujur >= 94.5 && bujur <= 141.5;

Koordinat? normalisasiKoordinat(String lintang, String bujur) {
  final a = double.tryParse(lintang.trim());
  final b = double.tryParse(bujur.trim());
  if (a == null || b == null) return null;
  if (_dalamIndonesia(a, b)) return Koordinat(a, b);
  if (_dalamIndonesia(b, a)) return Koordinat(b, a, dikoreksi: true);
  return null;
}

