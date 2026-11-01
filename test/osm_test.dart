import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pddikti_mobile/fitur/beranda/peta/peta_penuh_layar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('1. FlutterMap dan LatLng terkompilasi dan dapat diinisialisasi', (tester) async {
    final controller = MapController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            mapController: controller,
            options: const MapOptions(
              initialCenter: LatLng(-0.7893, 113.9213),
              initialZoom: 5.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pddikti.pddikti_mobile',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('2. PetaPenuhLayar dapat dirender dalam ProviderScope dengan fokusKode', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PetaPenuhLayar(fokusKode: '041033'),
        ),
      ),
    );

    await tester.pump();

    // Verifikasi keberadaan widget AppBar dan peta
    expect(find.textContaining('Peta Kampus'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
