import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

ThemeData buatTema() {
  const skema = ColorScheme(
    brightness: Brightness.dark,
    primary: Warna.kunyit,
    onPrimary: Warna.tinta,
    secondary: Warna.laut,
    onSecondary: Warna.tinta,
    error: Warna.karang,
    onError: Warna.tinta,
    surface: Warna.tinta,
    onSurface: Warna.kapur,
    onSurfaceVariant: Warna.kapurRedup,
    outline: Warna.garisTegas,
    outlineVariant: Warna.garis,
    surfaceContainerLowest: Warna.tinta,
    surfaceContainerLow: Warna.tinta,
    surfaceContainer: Warna.tintaAngkat,
    surfaceContainerHigh: Warna.tintaAngkat,
    surfaceContainerHighest: Warna.tintaAngkat,
  );

  OutlineInputBorder batas(Color warna, double tebal) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: warna, width: tebal),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: Warna.tinta,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Warna.tintaAngkat,
    hoverColor: Colors.transparent,
    fontFamily: 'Archivo',
    appBarTheme: AppBarTheme(
      backgroundColor: Warna.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: Gaya.judulLayar,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Warna.tinta,
      ),
    ),
    dividerTheme: const DividerThemeData(color: Warna.garis, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Warna.tintaAngkat,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: Gaya.isi.copyWith(color: Warna.kapurRedup),
      border: batas(Warna.garisTegas, 1),
      enabledBorder: batas(Warna.garisTegas, 1),
      focusedBorder: batas(Warna.kunyit, 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Warna.tinta,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => Gaya.label.copyWith(
          color: s.contains(WidgetState.selected) ? Warna.kunyit : Warna.kapurRedup,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 22,
          color: s.contains(WidgetState.selected) ? Warna.kunyit : Warna.kapurRedup,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Warna.tintaAngkat,
      modalBarrierColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Warna.kunyit,
        foregroundColor: Warna.tinta,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Gaya.tombol,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Warna.kapur,
        side: const BorderSide(color: Warna.garisTegas),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Gaya.tombol,
      ),
    ),
  );
}

