import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../model/halaman.dart';
import '../model/pengumuman.dart';
import '../model/publikasi.dart';
import '../sumber/api_sumber.dart';

class KabarRepo {
  KabarRepo(this._api);
  final ApiSumber _api;

  final Map<String, ({Halaman<Pengumuman> data, DateTime waktu})> _cachePengumuman = {};
  final Map<String, ({Halaman<Publikasi> data, DateTime waktu})> _cachePublikasi = {};

  Future<Halaman<Pengumuman>> dapatkanPengumuman({
    int page = 1,
    int pageSize = 10,
    String search = '',
    bool paksaSegar = false,
  }) async {
    final kunci = '$page-$pageSize-$search';
    if (!paksaSegar && page == 1 && _cachePengumuman.containsKey(kunci)) {
      final entry = _cachePengumuman[kunci]!;
      if (DateTime.now().difference(entry.waktu).inHours < 6) {
        return entry.data;
      }
    }

    try {
      final res = await _api.ambilPengumuman(
        page: page,
        pageSize: pageSize,
        search: search,
      );

      if (page == 1) {
        _cachePengumuman[kunci] = (data: res, waktu: DateTime.now());
      }

      return res;
    } catch (e) {
      if (page == 1 && search.isEmpty) {
        try {
          final bundleStr = await rootBundle.loadString('assets/data/announcements.json');
          final decoded = jsonDecode(bundleStr) as Map<String, dynamic>;
          final rawList = (decoded['data'] as List<dynamic>?) ?? [];
          final items = rawList
              .whereType<Map<String, dynamic>>()
              .map((item) => Pengumuman.fromJson(item))
              .toList();
          final pagMap = (decoded['pagination'] as Map<String, dynamic>?) ?? {};
          final pagination = Pagination.fromJson(pagMap);
          final fallbackRes = Halaman(items: items, pagination: pagination);
          _cachePengumuman[kunci] = (data: fallbackRes, waktu: DateTime.now());
          return fallbackRes;
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<Halaman<Publikasi>> dapatkanPublikasi({
    int page = 1,
    int pageSize = 10,
    String search = '',
    bool paksaSegar = false,
  }) async {
    final kunci = '$page-$pageSize-$search';
    if (!paksaSegar && page == 1 && _cachePublikasi.containsKey(kunci)) {
      final entry = _cachePublikasi[kunci]!;
      if (DateTime.now().difference(entry.waktu).inHours < 6) {
        return entry.data;
      }
    }

    try {
      final res = await _api.ambilPublikasi(
        page: page,
        pageSize: pageSize,
        search: search,
      );

      if (page == 1) {
        _cachePublikasi[kunci] = (data: res, waktu: DateTime.now());
      }

      return res;
    } catch (e) {
      if (page == 1 && search.isEmpty) {
        try {
          final bundleStr = await rootBundle.loadString('assets/data/publications.json');
          final decoded = jsonDecode(bundleStr) as Map<String, dynamic>;
          final rawList = (decoded['data'] as List<dynamic>?) ?? [];
          final items = rawList
              .whereType<Map<String, dynamic>>()
              .map((item) => Publikasi.fromJson(item))
              .toList();
          final pagMap = (decoded['pagination'] as Map<String, dynamic>?) ?? {};
          final pagination = Pagination.fromJson(pagMap);
          final fallbackRes = Halaman(items: items, pagination: pagination);
          _cachePublikasi[kunci] = (data: fallbackRes, waktu: DateTime.now());
          return fallbackRes;
        } catch (_) {}
      }
      rethrow;
    }
  }
}
