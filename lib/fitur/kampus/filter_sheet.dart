import 'package:flutter/material.dart';
import '../../core/format/angka.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/kampus.dart';
import 'indeks_pencarian.dart';
import 'kampus_vm.dart';

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
  late Set<String> _pembinaTerpilih;
  late Set<String> _kotaTerpilih;

  String _cariPembina = '';
  String _cariKota = '';

  late final List<String> _daftarKelompok;
  late final Map<String, List<String>> _pembinaPerKelompok;
  late final List<String> _daftarKota;

  @override
  void initState() {
    super.initState();
    _kelompokTerpilih = Set<String>.from(widget.queryAwal.kelompok);
    _pembinaTerpilih = Set<String>.from(widget.queryAwal.pembina);
    _kotaTerpilih = Set<String>.from(widget.queryAwal.kota);

    // Kumpulkan nilai unik dari data nyata kampus
    final setKelompok = <String>{};
    final mapPembina = <String, Set<String>>{};
    final setKota = <String>{};

    for (final k in widget.semuaKampus) {
      setKelompok.add(k.kelompok);
      (mapPembina[k.kelompok] ??= <String>{}).add(k.pembina);
      if (k.kota != null && k.kota!.isNotEmpty && k.kota != 'Tidak Diisi') {
        setKota.add(k.kota!);
      }
    }

    _daftarKelompok = setKelompok.toList()..sort();
    _pembinaPerKelompok = mapPembina.map((k, v) => MapEntry(k, v.toList()..sort()));
    _daftarKota = setKota.toList()..sort();
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

  @override
  Widget build(BuildContext context) {
    final totalHasil = _hitungHasil();

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        color: Warna.tintaAngkat,
        child: Column(
          children: [
            // Header Sheet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Warna.garis, width: 1)),
              ),
              child: Row(
                children: [
                  Text('Filter Kampus', style: Gaya.judulLayar.copyWith(fontSize: 18)),
                  const Spacer(),
                  if (_kelompokTerpilih.isNotEmpty ||
                      _pembinaTerpilih.isNotEmpty ||
                      _kotaTerpilih.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _kelompokTerpilih.clear();
                          _pembinaTerpilih.clear();
                          _kotaTerpilih.clear();
                        });
                      },
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
                  // 1. Kelompok
                  Text('Kelompok', style: Gaya.judulLayar.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _daftarKelompok.map((kel) {
                      final terpilih = _kelompokTerpilih.contains(kel);
                      return FilterChip(
                        label: Text(kel),
                        selected: terpilih,
                        showCheckmark: false,
                        backgroundColor: Warna.tinta,
                        selectedColor: Warna.kunyit,
                        labelStyle: Gaya.label.copyWith(
                          color: terpilih ? Warna.tinta : Warna.kapur,
                          fontWeight: terpilih ? FontWeight.w600 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: terpilih ? Warna.kunyit : Warna.garisTegas,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _kelompokTerpilih.add(kel);
                            } else {
                              _kelompokTerpilih.remove(kel);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 2. Pembina
                  Text('Pembina', style: Gaya.judulLayar.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (val) => setState(() => _cariPembina = val.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Cari pembina atau LLDIKTI',
                      prefixIcon: Icon(Icons.search, size: 20, color: Warna.kapurRedup),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._pembinaPerKelompok.entries.map((entry) {
                    final kelNama = entry.key;
                    final listPem = entry.value.where((p) {
                      if (_cariPembina.isEmpty) return true;
                      return p.toLowerCase().contains(_cariPembina);
                    }).toList();

                    if (listPem.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            kelNama,
                            style: Gaya.label.copyWith(
                              color: Warna.kunyit,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...listPem.map((pem) {
                          final terpilih = _pembinaTerpilih.contains(pem);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (terpilih) {
                                  _pembinaTerpilih.remove(pem);
                                } else {
                                  _pembinaTerpilih.add(pem);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Warna.garis, width: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    terpilih ? Icons.check_box : Icons.check_box_outline_blank,
                                    size: 20,
                                    color: terpilih ? Warna.kunyit : Warna.garisTegas,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(pem, style: Gaya.isi.copyWith(fontSize: 14)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),

                  // 3. Kota atau Kabupaten
                  Text('Kota atau kabupaten', style: Gaya.judulLayar.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (val) => setState(() => _cariKota = val.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Cari kota atau kabupaten',
                      prefixIcon: Icon(Icons.search, size: 20, color: Warna.kapurRedup),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._daftarKota
                      .where((k) => _cariKota.isEmpty || k.toLowerCase().contains(_cariKota))
                      .map((kota) {
                    final terpilih = _kotaTerpilih.contains(kota);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (terpilih) {
                            _kotaTerpilih.remove(kota);
                          } else {
                            _kotaTerpilih.add(kota);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Warna.garis, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              terpilih ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 20,
                              color: terpilih ? Warna.kunyit : Warna.garisTegas,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(kota, style: Gaya.isi.copyWith(fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Tombol Terapkan Utama di bagian bawah (Section 5.3)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Warna.garis, width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop((
                      kelompok: _kelompokTerpilih,
                      pembina: _pembinaTerpilih,
                      kota: _kotaTerpilih,
                    ));
                  },
                  child: Text('Tampilkan ${FormatAngka.ribuan(totalHasil)} kampus'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

