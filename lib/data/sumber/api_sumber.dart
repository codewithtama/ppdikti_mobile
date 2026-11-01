import 'package:dio/dio.dart';
import '../../core/net/dio_klien.dart';
import '../../core/net/galat.dart';
import '../model/beranda.dart';
import '../model/kampus.dart';
import '../model/kelulusan.dart';
import '../model/pencarian_global.dart';
import '../model/pengumuman.dart';
import '../model/publikasi.dart';
import '../model/halaman.dart';

class ApiSumber {
  ApiSumber(this._dio);
  final Dio _dio;

  /// Ekstraksi list aman dari respons Map {'data': [...]} atau List [...]
  List<dynamic> _ambilList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final d = responseData['data'];
      if (d is List) return d;
    } else if (responseData is List) {
      return responseData;
    }
    return [];
  }

  /// Mengambil data statistik beranda dan 10 bidang ilmu
  Future<BerandaData> ambilBeranda() async {
    try {
      final res = await _dio.get<dynamic>(
        '/beranda',
        queryParameters: {'content_limit': '1'},
      );
      if (res.data is! Map<String, dynamic>) {
        throw const FormatTakTerduga('Data beranda kosong atau tidak valid');
      }
      return BerandaData.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw petakanDioError(e);
    }
  }

  /// Mengambil 4.342 data lokasi kampus se-Indonesia (payload ~1,2 MB)
  Future<List<dynamic>> ambilLocationsRaw({
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/pt/locations',
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
        ),
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );
      if (res.data is! Map<String, dynamic>) {
        throw const FormatTakTerduga('Data locations tidak valid');
      }
      final rawList = (res.data as Map<String, dynamic>)['data'] as List<dynamic>?;
      if (rawList == null) throw const FormatTakTerduga('Data locations kosong');
      return rawList;
    } catch (e) {
      throw petakanDioError(e);
    }
  }

  /// Mengambil tingkat kelulusan kampus menurut idSp
  Future<Kelulusan> ambilGraduationRate(String idSp) async {
    try {
      final encodedId = Uri.encodeComponent(idSp);
      final res = await _dio.get<dynamic>('/pt/graduation-rate/$encodedId');
      if (res.data == null || res.data is! Map<String, dynamic>) {
        throw const FormatTakTerduga('Data kelulusan kosong');
      }
      return Kelulusan.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw petakanDioError(e);
    }
  }

  /// Pencarian terpadu langsung ke API PDDikti tanpa perantara
  Future<HasilPencarianGlobal> cariGlobal(String keyword) async {
    final kataKunci = keyword.trim();
    if (kataKunci.isEmpty) return const HasilPencarianGlobal();

    try {
      final encoded = Uri.encodeComponent(kataKunci);

      // Panggil 4 endpoint pencarian secara paralel via Future.wait
      final responses = await Future.wait([
        _dio.get<dynamic>('/pencarian/mhs/$encoded').catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions(), data: <String, dynamic>{'data': <dynamic>[]}),
            ),
        _dio.get<dynamic>('/pencarian/dosen/$encoded').catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions(), data: <String, dynamic>{'data': <dynamic>[]}),
            ),
        _dio.get<dynamic>('/pencarian/prodi/$encoded').catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions(), data: <String, dynamic>{'data': <dynamic>[]}),
            ),
        _dio.get<dynamic>('/pencarian/pt/$encoded').catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions(), data: <String, dynamic>{'data': <dynamic>[]}),
            ),
      ]);

      final rawMhs = _ambilList(responses[0].data);
      final rawDsn = _ambilList(responses[1].data);
      final rawPrd = _ambilList(responses[2].data);
      final rawPt = _ambilList(responses[3].data);

      final mhs = rawMhs.whereType<Map<String, dynamic>>().map(HasilMahasiswa.fromJson).toList();
      final dsn = rawDsn.whereType<Map<String, dynamic>>().map(HasilDosen.fromJson).toList();
      final prd = rawPrd.whereType<Map<String, dynamic>>().map(HasilProdi.fromJson).toList();
      final pt = rawPt.whereType<Map<String, dynamic>>().map(Kampus.fromJson).toList();

      // Enrich status mahasiswa & dosen secara paralel agar status akurat (Aktif, Non-Aktif, Lulus, Cuti, dll)
      final enrichedMhsFuture = Future.wait(
        mhs.map((item) async {
          if (item.status != null && item.status!.isNotEmpty) return item;
          try {
            final encId = Uri.encodeComponent(item.id);
            final dRes = await _dio.get<dynamic>(
              '/detail/mhs/$encId',
              options: Options(receiveTimeout: const Duration(seconds: 3)),
            );
            if (dRes.data is Map<String, dynamic>) {
              final dMap = (dRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
              final st = dMap?['status_saat_ini']?.toString().trim();
              final jg = dMap?['jenjang']?.toString().trim();
              return item.copyWith(
                status: st != null && st.isNotEmpty ? st : null,
                jenjang: jg != null && jg.isNotEmpty ? jg : item.jenjang,
              );
            }
          } catch (_) {}
          return item;
        }),
      );

      final enrichedDsnFuture = Future.wait(
        dsn.map((item) async {
          if (item.status != null && item.status!.isNotEmpty) return item;
          try {
            final encId = Uri.encodeComponent(item.id);
            final dRes = await _dio.get<dynamic>(
              '/dosen/profile/$encId',
              options: Options(receiveTimeout: const Duration(seconds: 3)),
            );
            if (dRes.data is Map<String, dynamic>) {
              final dMap = (dRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
              final st = dMap?['status_aktivitas']?.toString().trim();
              final jb = dMap?['jabatan_akademik']?.toString().trim();
              final pt = dMap?['pendidikan_tertinggi']?.toString().trim();
              return item.copyWith(
                status: st != null && st.isNotEmpty ? st : null,
                jabatanAkademik: jb != null && jb.isNotEmpty ? jb : item.jabatanAkademik,
                pendidikanTertinggi: pt != null && pt.isNotEmpty ? pt : item.pendidikanTertinggi,
              );
            }
          } catch (_) {}
          return item;
        }),
      );

      final enrichedResults = await Future.wait([enrichedMhsFuture, enrichedDsnFuture]);

      return HasilPencarianGlobal(
        mahasiswa: enrichedResults[0] as List<HasilMahasiswa>,
        dosen: enrichedResults[1] as List<HasilDosen>,
        prodi: prd,
        pt: pt,
        dariCache: false,
      );
    } catch (e) {
      throw petakanDioError(e);
    }
  }

  /// Mengambil detail mahasiswa (biodata & riwayat perkuliahan)
  Future<DetailMahasiswa?> ambilDetailMahasiswa(String id, {HasilMahasiswa? ringkasan}) async {
    try {
      final encId = Uri.encodeComponent(id);
      final res = await _dio.get<dynamic>('/detail/mhs/$encId');
      if (res.data is Map<String, dynamic>) {
        final dataMap = res.data as Map<String, dynamic>;
        final innerData = (dataMap['data'] as Map<String, dynamic>?) ?? dataMap;
        return DetailMahasiswa.fromJson(innerData, fallback: ringkasan);
      }
      return ringkasan != null ? DetailMahasiswa(ringkasan: ringkasan) : null;
    } catch (e) {
      if (ringkasan != null) return DetailMahasiswa(ringkasan: ringkasan);
      throw petakanDioError(e);
    }
  }

  /// Mengambil detail dosen (biodata, riwayat pendidikan, riwayat mengajar)
  Future<DetailDosen?> ambilDetailDosen(String id, {HasilDosen? ringkasan}) async {
    try {
      final encId = Uri.encodeComponent(id);
      final results = await Future.wait([
        _dio.get<dynamic>('/dosen/profile/$encId').catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions(), data: <String, dynamic>{'data': <String, dynamic>{}}),
            ),
        _dio.get<dynamic>('/dosen/study-history/$encId').catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions(), data: <String, dynamic>{'data': <dynamic>[]}),
            ),
        _dio.get<dynamic>('/dosen/teaching-history/$encId').catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions(), data: <String, dynamic>{'data': <dynamic>[]}),
            ),
      ]);

      final profileMap = (results[0].data is Map<String, dynamic>)
          ? ((results[0].data as Map<String, dynamic>)['data'] as Map<String, dynamic>?) ?? <String, dynamic>{}
          : <String, dynamic>{};

      final studyList = _ambilList(results[1].data);
      final teachingList = _ambilList(results[2].data);

      final combined = <String, dynamic>{
        ...profileMap,
        'riwayat_pendidikan': studyList,
        'riwayat_mengajar': teachingList,
      };

      return DetailDosen.fromJson(combined, fallback: ringkasan);
    } catch (e) {
      if (ringkasan != null) return DetailDosen(ringkasan: ringkasan);
      throw petakanDioError(e);
    }
  }

  /// Mengambil detail prodi
  Future<HasilProdi?> ambilDetailProdi(String id, {HasilProdi? fallback}) async {
    try {
      final encId = Uri.encodeComponent(id);
      final res = await _dio.get<dynamic>('/prodi/detail/$encId');
      if (res.data is Map<String, dynamic>) {
        final dataMap = res.data as Map<String, dynamic>;
        final innerData = (dataMap['data'] as Map<String, dynamic>?) ?? dataMap;
        return HasilProdi.fromJson(innerData);
      }
      return fallback;
    } catch (e) {
      return fallback;
    }
  }

  /// Mengambil daftar pengumuman dengan pagination dan filter pencarian
  Future<Halaman<Pengumuman>> ambilPengumuman({
    int page = 1,
    int pageSize = 10,
    String search = '',
  }) async {
    try {
      final query = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      if (search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }

      final res = await _dio.get<dynamic>(
        '/content/announcements',
        queryParameters: query,
      );

      final data = res.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw const FormatTakTerduga('Data pengumuman kosong');
      }

      final rawList = (data['data'] as List<dynamic>?) ?? [];
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => Pengumuman.fromJson(e))
          .toList();

      final pagMap = (data['pagination'] as Map<String, dynamic>?) ?? {};
      final pagination = Pagination.fromJson(pagMap);

      return Halaman(items: items, pagination: pagination);
    } catch (e) {
      throw petakanDioError(e);
    }
  }

  /// Mengambil daftar publikasi dengan pagination dan filter pencarian
  Future<Halaman<Publikasi>> ambilPublikasi({
    int page = 1,
    int pageSize = 10,
    String search = '',
  }) async {
    try {
      final query = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      if (search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }

      final res = await _dio.get<dynamic>(
        '/content/publications',
        queryParameters: query,
      );

      final data = res.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw const FormatTakTerduga('Data publikasi kosong');
      }

      final rawList = (data['data'] as List<dynamic>?) ?? [];
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => Publikasi.fromJson(e))
          .toList();

      final pagMap = (data['pagination'] as Map<String, dynamic>?) ?? {};
      final pagination = Pagination.fromJson(pagMap);

      return Halaman(items: items, pagination: pagination);
    } catch (e) {
      throw petakanDioError(e);
    }
  }
}
