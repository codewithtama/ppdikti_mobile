import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/format/angka.dart';
import '../../core/theme/tokens.dart';
import '../../data/model/beranda.dart';

enum KolomUrutBidangIlmu {
  nama,
  totalMahasiswa,
  persenLulus,
}

class BidangIlmuTabel extends StatefulWidget {
  const BidangIlmuTabel({
    super.key,
    required this.daftar,
    required this.angkaMahasiswaBeranda,
  });

  final List<BidangIlmu> daftar;
  final int angkaMahasiswaBeranda;

  @override
  State<BidangIlmuTabel> createState() => _BidangIlmuTabelState();
}

class _BidangIlmuTabelState extends State<BidangIlmuTabel> {
  KolomUrutBidangIlmu _kolomAktif = KolomUrutBidangIlmu.totalMahasiswa;
  bool _menurun = true;

  void _gantiUrutan(KolomUrutBidangIlmu kolom) {
    setState(() {
      if (_kolomAktif == kolom) {
        _menurun = !_menurun;
      } else {
        _kolomAktif = kolom;
        _menurun = true;
      }
    });
  }

  void _tampilkanInfoSheet(BuildContext context, int totalTabel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tentang data bidang ilmu', style: Gaya.judulLayar.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Text(
                'Jumlah semua baris tabel ini (${FormatAngka.ribuan(totalTabel)}) berbeda dengan angka Mahasiswa di atas (${FormatAngka.ribuan(widget.angkaMahasiswaBeranda)}). PDDikti tidak menjelaskan perbedaannya. Persen lulus mengikuti angka dari PDDikti.',
                style: Gaya.isi,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Mengerti'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.daftar.isEmpty) return const SizedBox.shrink();

    final totalTabel = widget.daftar.fold<int>(0, (prev, e) => prev + e.totalMahasiswa);
    final maksMahasiswa = widget.daftar.map((e) => e.totalMahasiswa).fold<int>(1, math.max);

    final listUrut = List<BidangIlmu>.from(widget.daftar)..sort((a, b) {
        int cmp;
        switch (_kolomAktif) {
          case KolomUrutBidangIlmu.nama:
            cmp = a.nama.compareTo(b.nama);
            break;
          case KolomUrutBidangIlmu.totalMahasiswa:
            cmp = a.totalMahasiswa.compareTo(b.totalMahasiswa);
            break;
          case KolomUrutBidangIlmu.persenLulus:
            cmp = a.persenLulus.compareTo(b.persenLulus);
            break;
        }
        return _menurun ? -cmp : cmp;
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Bidang ilmu', style: Gaya.judulLayar.copyWith(fontSize: 18)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18, color: Warna.kapurRedup),
              tooltip: 'Info bidang ilmu',
              onPressed: () => _tampilkanInfoSheet(context, totalTabel),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Header Tabel
        LayoutBuilder(
          builder: (context, constraints) {
            final sempit = constraints.maxWidth < 360;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Warna.garis, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: () => _gantiUrutan(KolomUrutBidangIlmu.nama),
                      child: Text('Bidang', style: Gaya.label),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: () => _gantiUrutan(KolomUrutBidangIlmu.totalMahasiswa),
                      child: Text(
                        sempit ? 'Total mhs.' : 'Total mahasiswa',
                        style: Gaya.label,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () => _gantiUrutan(KolomUrutBidangIlmu.persenLulus),
                      child: Text(
                        'Persen lulus',
                        style: Gaya.label,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Baris-baris Data
        ...listUrut.map((item) {
          final rasio = (item.totalMahasiswa / maksMahasiswa).clamp(0.0, 1.0);

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Warna.garis, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(item.nama, style: Gaya.isi),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        FormatAngka.ribuan(item.totalMahasiswa),
                        style: Gaya.angka.copyWith(fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${item.persenLulusStr}%',
                        style: Gaya.angka.copyWith(fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Batang laut relatif terhadap bidang terbesar (Radius 0)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth * rasio;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 3,
                        width: barWidth,
                        color: Warna.laut,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

