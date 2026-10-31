import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/format/angka.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/model/kampus.dart';
import '../../kampus/kampus_vm.dart';
import 'grid_ketuk.dart';
import 'peta_painter.dart';

class PetaPenuhLayar extends ConsumerStatefulWidget {
  const PetaPenuhLayar({super.key});

  @override
  ConsumerState<PetaPenuhLayar> createState() => _PetaPenuhLayarState();
}

class _PetaPenuhLayarState extends ConsumerState<PetaPenuhLayar>
    with SingleTickerProviderStateMixin {
  late final TransformationController _kontrol;
  late final AnimationController _animController;
  bool _tampilanAwalDisetel = false;

  @override
  void initState() {
    super.initState();
    _kontrol = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: Duration.zero,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _kontrol.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _aturTampilanAwal(Size size) {
    if (_tampilanAwalDisetel || size.width <= 0 || size.height <= 0) return;
    _tampilanAwalDisetel = true;

    // Pada layar portrait, tampilan awal berskala 2.4 berpusat di Jawa (lintang -7, bujur 110)
    // Section 6.6 DESIGN.md
    const skala = 2.4;
    final pusatJawa = GridKetuk.proyeksikan(-7.0, 110.0);

    // Di painter, koordinat di-scale dengan size.width:
    // Posisi di kanvas = (pusatJawa.x * size.width, pusatJawa.y * size.width)
    final canvasX = pusatJawa.x * size.width;
    final canvasY = pusatJawa.y * size.width;

    // Supaya titik tersebut berada di tengah viewport (size.width / 2, size.height / 2):
    final tx = (size.width / 2) - (canvasX * skala);
    final ty = (size.height / 2) - (canvasY * skala);

    _kontrol.value = Matrix4.translationValues(tx, ty, 0.0)
      ..scaleByDouble(skala, skala, 1.0, 1.0);
  }

  void _tanganiKetuk(TapUpDetails details, Size size, GridKetuk? grid) {
    if (grid == null || size.width <= 0) return;

    // Uji ketuk sesuai Section 6.5 & 13.5
    final inverted = Matrix4.inverted(_kontrol.value);
    final pointInCanvas = MatrixUtils.transformPoint(inverted, details.localPosition);
    final normX = pointInCanvas.dx / size.width;
    final normY = pointInCanvas.dy / size.width;

    final skala = _kontrol.value.getMaxScaleOnAxis();
    const ambangDp = 16.0;
    final radiusNorm = ambangDp / (size.width * skala);

    final kampusDekat = grid.cariKampusDekat(
      normX: normX,
      normY: normY,
      radiusNorm: radiusNorm,
      maks: 8,
    );

    if (kampusDekat.isEmpty) return;

    if (kampusDekat.length == 1) {
      context.push('/kampus/${kampusDekat.first.kode}');
    } else {
      _tampilkanSheetKampusDekat(kampusDekat);
    }
  }

  void _tampilkanSheetKampusDekat(List<Kampus> daftar) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${daftar.length} kampus terdekat dari titik ini',
                    style: Gaya.judulLayar.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 12),
                ...daftar.map((k) {
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/kampus/${k.kode}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Warna.garis, width: 1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.nama, style: Gaya.namaBaris),
                          const SizedBox(height: 2),
                          Text(
                            '${k.kota ?? 'Kota belum diisi'}, ${k.kelompok}',
                            style: Gaya.label,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasil = ref.watch(hasilKampusProvider);
    final pathIndonesiaAsync = ref.watch(petaIndonesiaPathProvider);
    final dataParsed = ref.watch(daftarKampusProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kampus'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _aturTampilanAwal(size));

                  return Stack(
                    children: [
                      // CustomPaint dirender tajam tanpa transformasi raster
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PetaTitikPainter(
                            pathIndonesia: pathIndonesiaAsync.value,
                            redup: hasil.titikRedup,
                            sorot: hasil.titikSorot,
                            kontrol: _kontrol,
                            sapuan: _animController,
                            adaFilter: hasil.adaFilter,
                            cincinTunggal: hasil.cincinTunggal,
                          ),
                        ),
                      ),
                      // InteractiveViewer transparan sebagai penangkap gestur
                      Positioned.fill(
                        child: GestureDetector(
                          onTapUp: (details) => _tanganiKetuk(details, size, dataParsed?.grid),
                          child: InteractiveViewer(
                            transformationController: _kontrol,
                            minScale: 1.0,
                            maxScale: 12.0,
                            panEnabled: true,
                            scaleEnabled: true,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Baris info hitungan & tombol hapus filter di bawah
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Warna.tinta,
                border: Border(top: BorderSide(color: Warna.garis, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${FormatAngka.ribuan(hasil.daftar.length)} dari ${FormatAngka.ribuan(hasil.totalKampus)} kampus',
                      style: Gaya.label,
                    ),
                  ),
                  if (hasil.adaFilter)
                    TextButton(
                      onPressed: () {
                        ref.read(kampusQueryProvider.notifier).hapusSemuaFilter();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Warna.kunyit,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Hapus filter'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
