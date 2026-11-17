import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

enum TipeFavorit {
  kampus('Kampus'),
  prodi('Program Studi'),
  mahasiswa('Mahasiswa'),
  dosen('Dosen');

  const TipeFavorit(this.label);
  final String label;

  static TipeFavorit dariString(String value) {
    return TipeFavorit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipeFavorit.kampus,
    );
  }
}

class ItemFavorit {
  const ItemFavorit({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.subjudul,
    required this.metaJson,
    required this.createdAt,
  });

  final String id;
  final TipeFavorit tipe;
  final String judul;
  final String subjudul;
  final Map<String, dynamic> metaJson;
  final DateTime createdAt;

  Map<String, Object?> toRow() => {
        'id': id,
        'tipe': tipe.name,
        'judul': judul,
        'subjudul': subjudul,
        'meta_json': jsonEncode(metaJson),
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ItemFavorit.fromRow(Map<String, Object?> row) {
    Map<String, dynamic> meta = {};
    final rawMeta = row['meta_json']?.toString() ?? '';
    if (rawMeta.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMeta);
        if (decoded is Map<String, dynamic>) meta = decoded;
      } catch (_) {}
    }
    return ItemFavorit(
      id: (row['id'] ?? '').toString(),
      tipe: TipeFavorit.dariString((row['tipe'] ?? '').toString()),
      judul: (row['judul'] ?? '').toString(),
      subjudul: (row['subjudul'] ?? '').toString(),
      metaJson: meta,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int?) ?? 0,
      ),
    );
  }
}

/// Penyimpanan SQLite lokal untuk Bookmark Favorit & Riwayat Pencarian Luring.
class DbLokal {
  DbLokal({this.dbPathOverride});

  final String? dbPathOverride;
  Database? _db;

  Future<Database> _dapatkanDb() async {
    if (_db != null && _db!.isOpen) return _db!;

    final path = dbPathOverride ??
        p.join(await getDatabasesPath(), 'pddikti_lokal.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorit (
            id TEXT NOT NULL,
            tipe TEXT NOT NULL,
            judul TEXT NOT NULL,
            subjudul TEXT NOT NULL,
            meta_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (id, tipe)
          )
        ''');

        await db.execute('''
          CREATE TABLE riwayat_pencarian (
            query TEXT PRIMARY KEY,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> simpanFavorit(ItemFavorit item) async {
    final db = await _dapatkanDb();
    await db.insert(
      'favorit',
      item.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> hapusFavorit(String id, TipeFavorit tipe) async {
    final db = await _dapatkanDb();
    await db.delete(
      'favorit',
      where: 'id = ? AND tipe = ?',
      whereArgs: [id, tipe.name],
    );
  }

  Future<List<ItemFavorit>> ambilSemuaFavorit() async {
    final db = await _dapatkanDb();
    final rows = await db.query(
      'favorit',
      orderBy: 'created_at DESC',
    );
    return rows.map(ItemFavorit.fromRow).toList();
  }

  Future<void> simpanRiwayat(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return;
    final db = await _dapatkanDb();
    await db.insert(
      'riwayat_pencarian',
      {
        'query': clean,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Pertahankan maksimal 12 riwayat terbaru
    final semua = await db.query(
      'riwayat_pencarian',
      orderBy: 'updated_at DESC',
    );
    if (semua.length > 12) {
      final batas = semua.sublist(12);
      for (final row in batas) {
        await db.delete(
          'riwayat_pencarian',
          where: 'query = ?',
          whereArgs: [row['query']],
        );
      }
    }
  }

  Future<List<String>> ambilRiwayat({int batas = 10}) async {
    final db = await _dapatkanDb();
    final rows = await db.query(
      'riwayat_pencarian',
      orderBy: 'updated_at DESC',
      limit: batas,
    );
    return rows
        .map((r) => (r['query'] ?? '').toString())
        .where((q) => q.isNotEmpty)
        .toList();
  }

  Future<void> hapusRiwayat(String query) async {
    final db = await _dapatkanDb();
    await db.delete(
      'riwayat_pencarian',
      where: 'query = ?',
      whereArgs: [query],
    );
  }

  Future<void> bersihkanRiwayat() async {
    final db = await _dapatkanDb();
    await db.delete('riwayat_pencarian');
  }

  Future<void> tutup() async {
    await _db?.close();
    _db = null;
  }
}
