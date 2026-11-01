import 'package:flutter/material.dart';
import '../../core/format/angka.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/kampus.dart';
import 'indeks_pencarian.dart';
import 'kampus_vm.dart';

typedef HasilFilterKampus = ({
  Set<String> kelompok,
  Set<String> pembina,
  Set<String> kota,
  Set<String> provinsi,
  Set<String> akreditasi,
  Set<String> status,
});

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.queryAwal,
    required this.semuaKampus,
    required this.aliasMap,
  });

  final KampusQuery queryAwal;
  final List<Kampus> semuaKampus;
  final Map<String, String> aliasMap;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> _kelompokTerpilih;
  late Set<String> _provinsiTerpilih;
  late Set<String> _akreditasiTerpilih;
  late Set<String> _statusTerpilih;
  late Set<String> _pembinaTerpilih;
  late Set<String> _kotaTerpilih;

  bool _tampilkanSemuaProvinsi = false;
  String _cariProvinsi = '';

  // Opsi filter standar sesuai UI PDDikti
  static const List<String> _opsiJenis = ['PTN', 'PTS', 'PTKL', 'PTA'];
  static const List<String> _opsiProvinsiUtama = [
    'Aceh',
    'Sumatera Utara',
    'Sumatera Selatan',
    'Sumatera Barat',
    'Bengkulu',
  ];
  static const List<String> _semuaDaftarProvinsi = [
    'Aceh',
    'Sumatera Utara',
    'Sumatera Barat',
    'Riau',
    'Kepulauan Riau',
    'Jambi',
    'Sumatera Selatan',
    'Bangka Belitung',
    'Bengkulu',
    'Lampung',
    'DKI Jakarta',
    'Jawa Barat',
    'Banten',
    'Jawa Tengah',
    'D.I. Yogyakarta',
    'Jawa Timur',
    'Bali',
    'Nusa Tenggara Barat',
    'Nusa Tenggara Timur',
    'Kalimantan Barat',
    'Kalimantan Tengah',
    'Kalimantan Selatan',
    'Kalimantan Timur',
    'Kalimantan Utara',
    'Sulawesi Utara',
    'Gorontalo',
    'Sulawesi Tengah',
    'Sulawesi Barat',
    'Sulawesi Selatan',
    'Sulawesi Tenggara',
    'Maluku',
    'Maluku Utara',
    'Papua',
  ];

  static const List<String> _opsiAkreditasi = [
    'Unggul',
    'Terakreditasi',
    'Tidak Terakreditasi',
  ];

  static const List<String> _opsiStatus = [
    'Aktif',
    'Alih Bentuk',
    'Tutup',
    'Alih Kelola',
    'Pembinaan',
  ];

  @override
  void initState() {
    super.initState();
    _kelompokTerpilih = Set<String>.from(widget.queryAwal.kelompok);
    _provinsiTerpilih = Set<String>.from(widget.queryAwal.provinsi);
    _akreditasiTerpilih = Set<String>.from(widget.queryAwal.akreditasi);
    _statusTerpilih = Set<String>.from(widget.queryAwal.status);
    _pembinaTerpilih = Set<String>.from(widget.queryAwal.pembina);
    _kotaTerpilih = Set<String>.from(widget.queryAwal.kota);
  }

  int _hitungHasil() {
    final qMurni = widget.queryAwal.q.trim();
    final adaQ = qMurni.isNotEmpty;
    final qNorm = normalisasi(qMurni);
    final kataQ = qNorm.isEmpty ? const <String>[] : qNorm.split(' ');

    int cocok = 0;
    for (final k in widget.semuaKampus) {
      if (_kelompokTerpilih.isNotEmpty && !_kelompokTerpilih.contains(k.kelompok)) {
        continue;
      }
      if (_pembinaTerpilih.isNotEmpty && !_pembinaTerpilih.contains(k.pembina)) {
        continue;
      }
      if (_kotaTerpilih.isNotEmpty) {
        if (k.kota == null || !_kotaTerpilih.contains(k.kota)) {
          continue;
        }
      }
      if (_provinsiTerpilih.isNotEmpty) {
        if (k.provinsi == null || !_provinsiTerpilih.contains(k.provinsi)) {
          continue;
        }
      }
      if (_statusTerpilih.isNotEmpty) {
        if (!_statusTerpilih.contains(k.status)) {
          continue;
        }
      }
      if (_akreditasiTerpilih.isNotEmpty) {
        bool cocokAkred = false;
        final akredLower = k.akreditasi.toLowerCase();
        for (final ak in _akreditasiTerpilih) {
          if (ak == 'Unggul' && akredLower.contains('unggul')) cocokAkred = true;
          if (ak == 'Terakreditasi' && (akredLower.isNotEmpty && !akredLower.contains('tidak'))) cocokAkred = true;
          if (ak == 'Tidak Terakreditasi' && (akredLower.isEmpty || akredLower.contains('tidak'))) cocokAkred = true;
        }
        if (!cocokAkred) continue;
      }

      if (!adaQ) {
        cocok++;
      } else {
        final e = EntriIndeks(k);
        final s = hitungSkor(
          e: e,
          q: qNorm,
          kataQ: kataQ,
          aliasMap: widget.aliasMap,
        );
        if (s > 0) cocok++;
      }
    }
    return cocok;
  }

  void _reset() {
    setState(() {
      _kelompokTerpilih.clear();
      _provinsiTerpilih.clear();
      _akreditasiTerpilih.clear();
      _statusTerpilih.clear();
      _pembinaTerpilih.clear();
      _kotaTerpilih.clear();
      _cariProvinsi = '';
    });
  }

  void _terapkan() {
    Navigator.of(context).pop<HasilFilterKampus>((
      kelompok: _kelompokTerpilih,
      pembina: _pembinaTerpilih,
      kota: _kotaTerpilih,
      provinsi: _provinsiTerpilih,
      akreditasi: _akreditasiTerpilih,
      status: _statusTerpilih,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final totalHasil = _hitungHasil();
    final adaPilihan = _kelompokTerpilih.isNotEmpty ||
        _provinsiTerpilih.isNotEmpty ||
        _akreditasiTerpilih.isNotEmpty ||
        _statusTerpilih.isNotEmpty ||
        _pembinaTerpilih.isNotEmpty ||
        _kotaTerpilih.isNotEmpty;

    // Filter daftar provinsi untuk tampilan
    List<String> daftarProvinsiTampil;
    if (_tampilkanSemuaProvinsi) {
      if (_cariProvinsi.isEmpty) {
        daftarProvinsiTampil = _semuaDaftarProvinsi;
      } else {
        daftarProvinsiTampil = _semuaDaftarProvinsi
            .where((p) => p.toLowerCase().contains(_cariProvinsi.toLowerCase()))
            .toList();
      }
    } else {
      daftarProvinsiTampil = _opsiProvinsiUtama;
    }

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        color: Warna.tintaAngkat,
        child: Column(
          children: [
            // Header Sheet sesuai desain resmi PDDikti
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Warna.garis, width: 1)),
              ),
              child: Row(
                children: [
                  const Text(
                    'FILTER',
                    style: TextStyle(
                      color: Warna.kapur,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  if (adaPilihan)
                    TextButton(
                      onPressed: _reset,
                      style: TextButton.styleFrom(foregroundColor: Warna.kunyit),
                      child: const Text('Reset'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Warna.kapurRedup),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Konten Filter (Scrollable)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // 1. Jenis (PTN, PTS, PTKL, PTA)
                  _buildJudulKategori('Jenis'),
                  ..._opsiJenis.map((jenis) {
                    final terpilih = _kelompokTerpilih.contains(jenis);
                    return _buildCheckboxBaris(
                      label: jenis,
                      terpilih: terpilih,
                      onTap: () {
                        setState(() {
                          if (terpilih) {
                            _kelompokTerpilih.remove(jenis);
                          } else {
                            _kelompokTerpilih.add(jenis);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 24),

                  // 2. Provinsi
                  _buildJudulKategori('Provinsi'),
                  if (_tampilkanSemuaProvinsi) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        onChanged: (val) => setState(() => _cariProvinsi = val.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Cari provinsi...',
                          prefixIcon: Icon(Icons.search, size: 18, color: Warna.kapurRedup),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                  ...daftarProvinsiTampil.map((prov) {
                    final terpilih = _provinsiTerpilih.contains(prov);
                    return _buildCheckboxBaris(
                      label: prov,
                      terpilih: terpilih,
                      onTap: () {
                        setState(() {
                          if (terpilih) {
                            _provinsiTerpilih.remove(prov);
                          } else {
                            _provinsiTerpilih.add(prov);
                          }
                        });
                      },
                    );
                  }),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _tampilkanSemuaProvinsi = !_tampilkanSemuaProvinsi;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            _tampilkanSemuaProvinsi ? 'Sembunyikan' : 'Lainnya',
                            style: const TextStyle(
                              color: Warna.kunyit,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _tampilkanSemuaProvinsi
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: Warna.kunyit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Akreditasi
                  _buildJudulKategori('Akreditasi'),
                  ..._opsiAkreditasi.map((akred) {
                    final terpilih = _akreditasiTerpilih.contains(akred);
                    return _buildCheckboxBaris(
                      label: akred,
                      terpilih: terpilih,
                      onTap: () {
                        setState(() {
                          if (terpilih) {
                            _akreditasiTerpilih.remove(akred);
                          } else {
                            _akreditasiTerpilih.add(akred);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 24),

                  // 4. Status
                  _buildJudulKategori('Status'),
                  ..._opsiStatus.map((status) {
                    final terpilih = _statusTerpilih.contains(status);
                    return _buildCheckboxBaris(
                      label: status,
                      terpilih: terpilih,
                      onTap: () {
                        setState(() {
                          if (terpilih) {
                            _statusTerpilih.remove(status);
                          } else {
                            _statusTerpilih.add(status);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Tombol Terapkan di Bawah
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Warna.garis, width: 1)),
                color: Warna.tinta,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _terapkan,
                  child: Text('Terapkan (${FormatAngka.ribuan(totalHasil)} kampus)'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudulKategori(String judul) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        judul,
        style: const TextStyle(
          color: Warna.kapur,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCheckboxBaris({
    required String label,
    required bool terpilih,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: terpilih ? Warna.kunyit : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: terpilih ? Warna.kunyit : Warna.garisTegas,
                  width: 1.5,
                ),
              ),
              child: terpilih
                  ? const Icon(Icons.check, size: 14, color: Warna.tinta)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: terpilih ? Warna.kapur : Warna.kapurRedup,
                  fontSize: 14,
                  fontWeight: terpilih ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
