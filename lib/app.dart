import 'package:flutter/material.dart';
import 'core/theme/tema.dart';
import 'router.dart';

class PDDiktiApp extends StatefulWidget {
  const PDDiktiApp({super.key, this.sudahSetuju = false});
  final bool sudahSetuju;

  @override
  State<PDDiktiApp> createState() => _PDDiktiAppState();
}

class _PDDiktiAppState extends State<PDDiktiApp> {
  late final _router = buatRouter(sudahSetuju: widget.sudahSetuju);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PDDikti Mobile',
      debugShowCheckedModeBanner: false,
      theme: buatTema(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}

