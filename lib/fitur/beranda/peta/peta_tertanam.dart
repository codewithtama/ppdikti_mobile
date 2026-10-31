import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../kampus/kampus_vm.dart';
import 'peta_painter.dart';

// Penanda global agar animasi sapuan hanya berjalan sekali per sesi peluncuran aplikasi
bool _animasiSapuanSudahJalan = false;

class PetaTertanamWidget extends ConsumerStatefulWidget {
  const PetaTertanamWidget({super.key});

  @override
  ConsumerState<PetaTertanamWidget> createState() => _PetaTertanamWidgetState();
}

class _PetaTertanamWidgetState extends ConsumerState<PetaTertanamWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _sapuanAnimation;
  final TransformationController _kontrol = TransformationController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sapuanAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    if (_animasiSapuanSudahJalan) {
      _animController.value = 1.0;
    } else {
      _animasiSapuanSudahJalan = true;
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _animController.value = 1.0;
    }

    final hasil = ref.watch(hasilKampusProvider);
    final pathIndonesiaAsync = ref.watch(petaIndonesiaPathProvider);
    final totalTitik = hasil.titikRedup.length ~/ 2 + hasil.titikSorot.length ~/ 2;

    return Semantics(
      label: 'Peta persebaran $totalTitik kampus. Buka tab Kampus untuk mencari.',
      button: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lebar = constraints.maxWidth;
          final tinggi = lebar * 0.383 + 16.0;

          return GestureDetector(
            onTap: () => context.push('/peta'),
            behavior: HitTestBehavior.opaque,
            child: ClipRect(
              child: SizedBox(
                width: lebar,
                height: tinggi,
                child: CustomPaint(
                  painter: PetaTitikPainter(
                    pathIndonesia: pathIndonesiaAsync.value,
                    redup: hasil.titikRedup,
                    sorot: hasil.titikSorot,
                    kontrol: _kontrol,
                    sapuan: _sapuanAnimation,
                    adaFilter: hasil.adaFilter,
                    cincinTunggal: hasil.cincinTunggal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

