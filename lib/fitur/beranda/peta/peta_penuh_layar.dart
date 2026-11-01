import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/format/angka.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/model/kampus.dart';
import '../../kampus/kampus_vm.dart';
import 'grid_ketuk.dart';
import 'peta_painter.dart';

enum TipeLapisanPeta {
  osmDark,
  osmStandar,
  vektorLuring,
}

class PetaPenuhLayar extends ConsumerStatefulWidget {
  const PetaPenuhLayar({super.key, this.fokusKode});

  final String? fokusKode;

  @override
  ConsumerState<PetaPenuhLayar> createState() => _PetaPenuhLayarState();
}

class _PetaPenuhLayarState extends ConsumerState<PetaPenuhLayar>
    with TickerProviderStateMixin {
  // Kontroler OpenStreetMap (flutter_map)
  late final MapController _mapController;
  AnimationController? _animMoveController;

  // Kontroler Vektor Kanvas (Luring)
  late final TransformationController _vectorController;
  late final AnimationController _vectorAnimController;
  bool _vektorAwalDisetel = false;

  // State tampilan
  TipeLapisanPeta _tipeLapisan = TipeLapisanPeta.osmDark;
  Kampus? _kampusTerpilih;
  bool _sudahFokusAwal = false;

  // Koordinat default kepulauan Indonesia (Pusat geografis)
  static const LatLng _pusatIndonesia = LatLng(-2.5, 118.0);
  static const double _zoomIndonesia = 5.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _vectorController = TransformationController();
    _vectorAnimController = AnimationController(
      vsync: this,
      duration: Duration.zero,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _animMoveController?.dispose();
    _mapController.dispose();
    _vectorController.dispose();
    _vectorAnimController.dispose();
    super.dispose();
  }

  /// Animasi zoom kamera halus meluncur ke koordinat seperti Google Maps
  void _animasikanKeKoordinat(LatLng target, double zoomTarget) {
    _animMoveController?.dispose();

    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: target.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: target.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: zoomTarget);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animMoveController = controller;

    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.forward();
  }

  void _periksaFokusAwal(List<Kampus> semuaKampus) {
    if (_sudahFokusAwal || widget.fokusKode == null) return;
    _sudahFokusAwal = true;

    final target = semuaKampus.firstWhereOrNull((k) => k.kode == widget.fokusKode);
    if (target != null && target.koordinat != null) {
      final k = target.koordinat!;
      final latLng = LatLng(k.lintang, k.bujur);
      setState(() => _kampusTerpilih = target);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _animasikanKeKoordinat(latLng, 15.5);
      });
    }
  }

  void _pilihKampus(Kampus kampus) {
    setState(() => _kampusTerpilih = kampus);
    final k = kampus.koordinat;
    if (k != null) {
      final target = LatLng(k.lintang, k.bujur);
      _animasikanKeKoordinat(target, 15.5);
    }
  }

  void _aturVektorAwal(Size size) {
    if (_vektorAwalDisetel || size.width <= 0 || size.height <= 0) return;
    _vektorAwalDisetel = true;

    const skala = 2.4;
    final pusatJawa = GridKetuk.proyeksikan(-7.0, 110.0);
    final canvasX = pusatJawa.x * size.width;
    final canvasY = pusatJawa.y * size.width;

    final tx = (size.width / 2) - (canvasX * skala);
    final ty = (size.height / 2) - (canvasY * skala);

    _vectorController.value = Matrix4.translationValues(tx, ty, 0.0)
      ..scaleByDouble(skala, skala, 1.0, 1.0);
  }

  void _tanganiKetukVektor(TapUpDetails details, Size size, GridKetuk? grid) {
    if (grid == null || size.width <= 0) return;

    final inverted = Matrix4.inverted(_vectorController.value);
    final pointInCanvas = MatrixUtils.transformPoint(inverted, details.localPosition);
    final normX = pointInCanvas.dx / size.width;
    final normY = pointInCanvas.dy / size.width;

    final skala = _vectorController.value.getMaxScaleOnAxis();
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
      _pilihKampus(kampusDekat.first);
    } else {
      _tampilkanSheetKampusDekat(kampusDekat);
    }
  }

  void _tampilkanSheetKampusDekat(List<Kampus> daftar) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Warna.tinta,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Warna.garis, width: 1),
      ),
      builder: (ctx) {
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
                    '${daftar.length} kampus di titik ini',
                    style: Gaya.judulLayar.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 12),
                ...daftar.map((k) {
                  return InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pilihKampus(k);
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
                            '${k.kota ?? 'Kota belum diisi'} • ${k.kelompok}',
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
    final dataParsed = ref.watch(daftarKampusProvider).value;
    final pathIndonesiaAsync = ref.watch(petaIndonesiaPathProvider);

    if (dataParsed != null) {
      _periksaFokusAwal(dataParsed.daftarKampus);
    }

    final semuaKampusBerkoordinat = (dataParsed?.daftarKampus ?? const <Kampus>[])
        .where((k) => k.koordinat != null)
        .toList();

    return Scaffold(
      backgroundColor: Warna.tinta,
      appBar: AppBar(
        backgroundColor: Warna.tinta,
        elevation: 0,
        title: Text(
          _kampusTerpilih != null ? _kampusTerpilih!.nama : 'Peta Kampus Indonesia',
          style: Gaya.judulLayar.copyWith(fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Warna.garis, height: 1),
        ),
        actions: [
          // Tombol Pilihan Mode Peta (OSM Dark / OSM Standar / Vektor)
          PopupMenuButton<TipeLapisanPeta>(
            icon: const Icon(PhosphorIconsRegular.stack, color: Warna.kunyit),
            tooltip: 'Ganti Tampilan Peta',
            color: Warna.tintaAngkat,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Warna.garis, width: 1),
            ),
            initialValue: _tipeLapisan,
            onSelected: (mode) => setState(() => _tipeLapisan = mode),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TipeLapisanPeta.osmDark,
                child: Row(
                  children: [
                    Icon(PhosphorIconsFill.moon, color: Warna.kunyit, size: 18),
                    SizedBox(width: 10),
                    Text('OpenStreetMap (Dark)', style: TextStyle(color: Warna.kapur)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TipeLapisanPeta.osmStandar,
                child: Row(
                  children: [
                    Icon(PhosphorIconsFill.sun, color: Warna.kunyit, size: 18),
                    SizedBox(width: 10),
                    Text('OpenStreetMap (Terang)', style: TextStyle(color: Warna.kapur)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TipeLapisanPeta.vektorLuring,
                child: Row(
                  children: [
                    Icon(PhosphorIconsFill.mapTrifold, color: Warna.kunyit, size: 18),
                    SizedBox(width: 10),
                    Text('Vektor Luring (Canvas)', style: TextStyle(color: Warna.kapur)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Lapisan Utama Peta
          if (_tipeLapisan == TipeLapisanPeta.vektorLuring) ...[
            // Mode Kanvas Vektor Luring
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _aturVektorAwal(size));

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PetaTitikPainter(
                            pathIndonesia: pathIndonesiaAsync.value,
                            redup: hasil.titikRedup,
                            sorot: hasil.titikSorot,
                            kontrol: _vectorController,
                            sapuan: _vectorAnimController,
                            adaFilter: hasil.adaFilter,
                            cincinTunggal: hasil.cincinTunggal,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          onTapUp: (details) => _tanganiKetukVektor(details, size, dataParsed?.grid),
                          child: InteractiveViewer(
                            transformationController: _vectorController,
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
          ] else ...[
            // Mode OpenStreetMap (Dark Matter atau Standar OSM)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _pusatIndonesia,
                  initialZoom: _zoomIndonesia,
                  minZoom: 3.5,
                  maxZoom: 18.5,
                ),
                children: [
                  // Lapisan Tile OSM (100% Bebas API Key & Tanpa Watermark)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'id.go.kemdiktisaintek.pddikti_mobile',
                    tileBuilder: _tipeLapisan == TipeLapisanPeta.osmDark
                        ? darkModeTileBuilder
                        : null,
                  ),

                  // Lapisan Titik Kampus (Semua titik koordinat)
                  CircleLayer(
                    circles: semuaKampusBerkoordinat.map((k) {
                      final c = k.koordinat!;
                      final isSelected = _kampusTerpilih?.kode == k.kode;
                      if (isSelected) return null;

                      final isCocokFilter = hasil.adaFilter && hasil.kodeCocok.contains(k.kode);

                      return CircleMarker(
                        point: LatLng(c.lintang, c.bujur),
                        radius: isCocokFilter ? 4.5 : 2.5,
                        color: isCocokFilter
                            ? Warna.kunyit
                            : Warna.kapur.withValues(alpha: 0.40),
                        borderStrokeWidth: isCocokFilter ? 1.0 : 0.0,
                        borderColor: Warna.tinta,
                        useRadiusInMeter: false,
                      );
                    }).whereType<CircleMarker>().toList(),
                  ),

                  // Lapisan Marker Interaktif untuk Kampus Terpilih (Google Maps Beacon Style)
                  if (_kampusTerpilih?.koordinat != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _kampusTerpilih!.koordinat!.lintang,
                            _kampusTerpilih!.koordinat!.bujur,
                          ),
                          width: 48,
                          height: 56,
                          alignment: Alignment.topCenter,
                          child: _bangunPinGoogleMaps(_kampusTerpilih!),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],

          // 2. Tombol Aksi Melayang (Zoom In, Zoom Out, Reset Indonesia)
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                _bangunTombolKontrol(
                  icon: PhosphorIconsRegular.plus,
                  tooltip: 'Perbesar',
                  onTap: () {
                    if (_tipeLapisan == TipeLapisanPeta.vektorLuring) {
                      _vectorController.value = _vectorController.value.clone()..scaleByDouble(1.3, 1.3, 1.0, 1.0);
                    } else {
                      final z = _mapController.camera.zoom + 1.0;
                      _animasikanKeKoordinat(_mapController.camera.center, z.clamp(3.5, 18.5));
                    }
                  },
                ),
                const SizedBox(height: 8),
                _bangunTombolKontrol(
                  icon: PhosphorIconsRegular.minus,
                  tooltip: 'Perkecil',
                  onTap: () {
                    if (_tipeLapisan == TipeLapisanPeta.vektorLuring) {
                      _vectorController.value = _vectorController.value.clone()..scaleByDouble(0.77, 0.77, 1.0, 1.0);
                    } else {
                      final z = _mapController.camera.zoom - 1.0;
                      _animasikanKeKoordinat(_mapController.camera.center, z.clamp(3.5, 18.5));
                    }
                  },
                ),
                const SizedBox(height: 8),
                _bangunTombolKontrol(
                  icon: PhosphorIconsRegular.crosshair,
                  tooltip: 'Lihat Seluruh Indonesia',
                  onTap: () {
                    if (_tipeLapisan == TipeLapisanPeta.vektorLuring) {
                      _vectorController.value = Matrix4.identity();
                    } else {
                      _animasikanKeKoordinat(_pusatIndonesia, _zoomIndonesia);
                    }
                  },
                ),
              ],
            ),
          ),

          // 3. Kartu Preview Kampus Terpilih (Google Maps Style)
          if (_kampusTerpilih != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _bangunKartuPreviewKampus(_kampusTerpilih!),
            ),

          // 4. Bar Info Jumlah Kampus jika tidak ada kampus terpilih
          if (_kampusTerpilih == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Warna.tinta,
                  border: Border(top: BorderSide(color: Warna.garis, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${FormatAngka.ribuan(hasil.daftar.length)} dari ${FormatAngka.ribuan(hasil.totalKampus)} kampus terpetakan',
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
            ),
        ],
      ),
    );
  }

  Widget _bangunPinGoogleMaps(Kampus kampus) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Warna.kunyit,
            shape: BoxShape.circle,
            border: Border.all(color: Warna.tinta, width: 2),
            boxShadow: [
              BoxShadow(
                color: Warna.kunyit.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            PhosphorIconsFill.graduationCap,
            color: Warna.tinta,
            size: 20,
          ),
        ),
        Container(
          width: 3,
          height: 10,
          color: Warna.kunyit,
        ),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: Warna.tinta.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _bangunTombolKontrol({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Warna.tintaAngkat,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Warna.garis, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Warna.kapur, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _bangunKartuPreviewKampus(Kampus kampus) {
    final k = kampus.koordinat;

    return Container(
      decoration: BoxDecoration(
        color: Warna.tintaAngkat,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Warna.kunyit, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kampus.nama,
                      style: Gaya.namaBaris.copyWith(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kode ${kampus.kode} • ${kampus.kelompok} • ${kampus.kota ?? 'Wilayah belum diisi'}',
                      style: Gaya.label.copyWith(color: Warna.kapurRedup),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(PhosphorIconsRegular.x, color: Warna.kapurRedup, size: 20),
                onPressed: () => setState(() => _kampusTerpilih = null),
                tooltip: 'Tutup',
              ),
            ],
          ),
          if (k != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(PhosphorIconsRegular.navigationArrow, color: Warna.laut, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${FormatAngka.koordinat(k.lintang)}, ${FormatAngka.koordinat(k.bujur)}',
                  style: Gaya.catatan.copyWith(color: Warna.laut),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Warna.kunyit,
                    foregroundColor: Warna.tinta,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => context.push('/kampus/${kampus.kode}'),
                  child: const Text(
                    'Lihat Profil Kampus',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
