import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/ketentuan/layanan_ketentuan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final sudahSetuju = await LayananKetentuan.sudahSetuju();

  runApp(
    ProviderScope(
      child: PDDiktiApp(sudahSetuju: sudahSetuju),
    ),
  );
}
