import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/tokens.dart';
import 'detail_vm.dart';

class SeksiProdiKampus extends ConsumerStatefulWidget {
  const SeksiProdiKampus({
    super.key,
    required this.namaPt,
    this.jumlahProdiTotal,
  });

  final String namaPt;
  final int? jumlahProdiTotal;

  @override
  ConsumerState<SeksiProdiKampus> createState() => _SeksiProdiKampusState();
}

class _SeksiProdiKampusState extends ConsumerState<SeksiProdiKampus> {
  final TextEditingController _pencarianCtrl = TextEditingController();
  String _kataKunci = '';
  String _jenjangTerpilih = 'Semua';

  @override
  void dispose() {
    _pencarianCtrl.dispose();
    super.dispose();
  }

  Color _warnaAkreditasi(String akreditasi) {
    final a = akreditasi.toLowerCase();
    if (a.contains('unggul') || a == 'a') return Warna.kunyit;
    if (a.contains('baik sekali') || a == 'b') return Warna.laut;
    if (a.contains('baik') || a == 'c') return const Color(0xFF60A5FA);
    return Warna.kapurRedup;
  }

  @override
  Widget build(BuildContext context) {
    final prodiAsync = ref.watch(prodiKampusProvider(widget.namaPt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DAFTAR PROGRAM STUDI',
              style: TextStyle(
                color: Warna.kunyit,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.jumlahProdiTotal != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Warna.kunyit.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${widget.jumlahProdiTotal} Total',
                  style: const TextStyle(
                    color: Warna.kunyit,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        prodiAsync.when(
          loading: () => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Warna.tintaAngkat,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Warna.garis, width: 1),
            ),
            child: const Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Warna.kunyit,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Memuat daftar program studi...',
                    style: TextStyle(color: Warna.kapurRedup, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Warna.tintaAngkat,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Warna.garis, width: 1),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.warningCircle, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Daftar program studi belum dapat dimuat.',
                    style: TextStyle(color: Warna.kapurRedup, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(prodiKampusProvider(widget.namaPt)),
                  child: const Text('Coba Lagi', style: TextStyle(color: Warna.kunyit, fontSize: 12)),
                ),
              ],
            ),
          ),
          data: (daftarProdi) {
            if (daftarProdi.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Warna.tintaAngkat,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Warna.garis, width: 1),
                ),
                child: const Center(
                  child: Text(
                    'Data program studi tidak tersedia untuk kampus ini.',
                    style: TextStyle(color: Warna.kapurRedup, fontSize: 13),
                  ),
                ),
              );
            }

            // Kumpulkan seluruh jenjang unik untuk filter chip
            final setJenjang = <String>{'Semua'};
            for (final p in daftarProdi) {
              if (p.jenjang.isNotEmpty) {
                setJenjang.add(p.jenjang.toUpperCase());
              }
            }
            final listJenjang = setJenjang.toList();

            // Filter berdasarkan jenjang & kata kunci pencarian
            final hasilFilter = daftarProdi.where((p) {
              final cocokJenjang = _jenjangTerpilih == 'Semua' ||
                  p.jenjang.toUpperCase() == _jenjangTerpilih;
              final cocokKata = _kataKunci.isEmpty ||
                  p.nama.toLowerCase().contains(_kataKunci.toLowerCase());
              return cocokJenjang && cocokKata;
            }).toList();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Warna.tintaAngkat,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Warna.garis, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Kolom Pencarian Nama Prodi
                  TextField(
                    controller: _pencarianCtrl,
                    onChanged: (val) => setState(() => _kataKunci = val.trim()),
                    style: const TextStyle(color: Warna.kapur, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari nama program studi...',
                      hintStyle: const TextStyle(color: Warna.kapurRedup, fontSize: 13),
                      prefixIcon: const Icon(
                        PhosphorIconsRegular.magnifyingGlass,
                        size: 16,
                        color: Warna.kapurRedup,
                      ),
                      suffixIcon: _kataKunci.isNotEmpty
                          ? IconButton(
                              icon: const Icon(PhosphorIconsRegular.x, size: 16, color: Warna.kapurRedup),
                              onPressed: () {
                                _pencarianCtrl.clear();
                                setState(() => _kataKunci = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Warna.tinta,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Warna.garis),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Warna.garis),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Warna.kunyit),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Filter Chips Jenjang
                  if (listJenjang.length > 2)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: listJenjang.map((jenjang) {
                          final terpilih = _jenjangTerpilih == jenjang;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                jenjang,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: terpilih ? FontWeight.w700 : FontWeight.w500,
                                  color: terpilih ? Warna.tinta : Warna.kapur,
                                ),
                              ),
                              selected: terpilih,
                              selectedColor: Warna.kunyit,
                              backgroundColor: Warna.tinta,
                              checkmarkColor: Warna.tinta,
                              side: BorderSide(
                                color: terpilih ? Warna.kunyit : Warna.garis,
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              onSelected: (_) {
                                setState(() => _jenjangTerpilih = jenjang);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 14),

                  // 3. Header Hasil Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menampilkan ${hasilFilter.length} dari ${daftarProdi.length} prodi',
                        style: const TextStyle(color: Warna.kapurRedup, fontSize: 11.5),
                      ),
                      if (_kataKunci.isNotEmpty || _jenjangTerpilih != 'Semua')
                        GestureDetector(
                          onTap: () {
                            _pencarianCtrl.clear();
                            setState(() {
                              _kataKunci = '';
                              _jenjangTerpilih = 'Semua';
                            });
                          },
                          child: const Text(
                            'Reset Filter',
                            style: TextStyle(
                              color: Warna.laut,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Warna.garis, height: 20),

                  // 4. Daftar Kartu Program Studi
                  if (hasilFilter.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Tidak ada program studi yang cocok dengan filter.',
                          style: TextStyle(color: Warna.kapurRedup, fontSize: 12.5),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hasilFilter.length,
                      separatorBuilder: (_, index) => const Divider(color: Warna.garis, height: 16),
                      itemBuilder: (context, index) {
                        final prodi = hasilFilter[index];
                        final warnaAkred = _warnaAkreditasi(prodi.akreditasi);

                        return InkWell(
                          onTap: () {
                            context.push('/prodi/${prodi.id}', extra: prodi);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge Jenjang
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Warna.kunyit.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Warna.kunyit, width: 0.8),
                                  ),
                                  child: Text(
                                    prodi.jenjang,
                                    style: const TextStyle(
                                      color: Warna.kunyit,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Informasi Nama & Akreditasi
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prodi.nama,
                                        style: const TextStyle(
                                          color: Warna.kapur,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (prodi.akreditasi != '-' && prodi.akreditasi.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: warnaAkred.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                'Akreditasi: ${prodi.akreditasi}',
                                                style: TextStyle(
                                                  color: warnaAkred,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              prodi.status,
                                              style: const TextStyle(
                                                color: Color(0xFF22C55E),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  PhosphorIconsRegular.caretRight,
                                  color: Warna.kapurRedup,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

