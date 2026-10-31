import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'core/theme/tokens.dart';
import 'data/model/pencarian_global.dart';
import 'fitur/beranda/beranda_layar.dart';
import 'fitur/beranda/peta/peta_penuh_layar.dart';
import 'fitur/kabar/kabar_layar.dart';
import 'fitur/kampus/detail_layar.dart';
import 'fitur/kampus/kampus_layar.dart';
import 'fitur/pencarian/detail_dosen_layar.dart';
import 'fitur/pencarian/detail_mahasiswa_layar.dart';
import 'fitur/pencarian/detail_prodi_layar.dart';
import 'fitur/tentang/tentang_layar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buatRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/beranda',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ScaffoldDenganNavigasi(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Beranda
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beranda',
                builder: (context, state) => const BerandaLayar(),
              ),
            ],
          ),

          // Tab 2: Pencarian & Direktori Kampus
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kampus',
                builder: (context, state) {
                  final fokus = state.uri.queryParameters['fokus'] == '1';
                  return KampusLayar(autofokus: fokus);
                },
              ),
            ],
          ),

          // Tab 3: Kabar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kabar',
                builder: (context, state) => const KabarLayar(),
              ),
            ],
          ),
        ],
      ),

      // Rute-rute di luar shell navigasi (Layar Penuh / Push)
      GoRoute(
        path: '/peta',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PetaPenuhLayar(),
      ),
      GoRoute(
        path: '/kampus/:kode',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final kode = state.pathParameters['kode'] ?? '';
          return DetailKampusLayar(kode: kode);
        },
      ),
      GoRoute(
        path: '/mahasiswa/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as HasilMahasiswa?;
          return DetailMahasiswaLayar(id: id, ringkasan: extra);
        },
      ),
      GoRoute(
        path: '/dosen/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as HasilDosen?;
          return DetailDosenLayar(id: id, ringkasan: extra);
        },
      ),
      GoRoute(
        path: '/prodi/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as HasilProdi?;
          return DetailProdiLayar(
            id: id,
            prodi: extra ??
                HasilProdi(
                  id: id,
                  nama: 'Program Studi',
                  jenjang: '',
                  pt: '',
                  status: 'Aktif',
                ),
          );
        },
      ),
      GoRoute(
        path: '/tentang',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TentangLayar(),
      ),
    ],
  );
}

class _ScaffoldDenganNavigasi extends StatelessWidget {
  const _ScaffoldDenganNavigasi({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Warna.tinta,
          border: Border(top: BorderSide(color: Warna.garis, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                idx == 0 ? PhosphorIconsFill.house : PhosphorIconsRegular.house,
                color: idx == 0 ? Warna.kunyit : Warna.kapurRedup,
              ),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(
                idx == 1 ? PhosphorIconsFill.magnifyingGlass : PhosphorIconsRegular.magnifyingGlass,
                color: idx == 1 ? Warna.kunyit : Warna.kapurRedup,
              ),
              label: 'Pencarian',
            ),
            NavigationDestination(
              icon: Icon(
                idx == 2 ? PhosphorIconsFill.newspaper : PhosphorIconsRegular.newspaper,
                color: idx == 2 ? Warna.kunyit : Warna.kapurRedup,
              ),
              label: 'Kabar',
            ),
          ],
        ),
      ),
    );
  }
}
