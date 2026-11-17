import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pddikti_mobile/core/net/dio_klien.dart';
import 'package:pddikti_mobile/core/net/galat.dart';
import 'package:pddikti_mobile/core/net/sesi_cloudflare.dart';
import 'package:pddikti_mobile/data/model/kampus.dart';
import 'package:pddikti_mobile/data/model/pencarian_global.dart';
import 'package:pddikti_mobile/data/repo/kampus_repo.dart';
import 'package:pddikti_mobile/data/repo/pencarian_repo.dart';
import 'package:pddikti_mobile/data/sumber/api_sumber.dart';
import 'package:pddikti_mobile/fitur/pencarian/pencarian_vm.dart';

class _FakeRecaptchaAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{"message":"reCAPTCHA verification required or failed","status":"error"}',
      403,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _StubPencarianRepo extends PencarianRepo {
  _StubPencarianRepo(super.api, super.kampusRepo);

  @override
  Future<HasilPencarianGlobal> cari({
    required String keyword,
    bool forceOffline = false,
  }) async {
    throw const ButuhVerifikasiCloudflare();
  }

  @override
  Future<HasilPencarianGlobal> cariKampusLokal(String keyword) async {
    return const HasilPencarianGlobal(
      pt: [
        Kampus(
          idSp: 'pt-1',
          kode: '001002',
          nama: 'Universitas Indonesia',
          kelompok: 'PTN',
          pembina: 'Kemdiktisaintek',
        ),
      ],
      dariCache: true,
    );
  }
}

void main() {
  tearDown(() {
    SesiCloudflareNotifier.cookiesAktif = null;
    SesiCloudflareNotifier.userAgentAktif = null;
    SesiCloudflareNotifier.recaptchaTokenAktif = null;
    SesiCloudflareNotifier.baseUrlAktif = null;
  });

  test('petakanDioError memetakan 403 reCAPTCHA menjadi ButuhVerifikasiCloudflare', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/pencarian/mhs/budi'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/pencarian/mhs/budi'),
        statusCode: 403,
        data: {
          'message': 'reCAPTCHA verification required or failed',
          'status': 'error',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    expect(petakanDioError(err), isA<ButuhVerifikasiCloudflare>());
  });

  test('petakanDioError tetap memetakan 403 biasa menjadi Ditolak(403)', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/rahasia'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/rahasia'),
        statusCode: 403,
        data: {'message': 'Forbidden'},
      ),
      type: DioExceptionType.badResponse,
    );

    final hasil = petakanDioError(err);
    expect(hasil, isA<Ditolak>());
    expect((hasil as Ditolak).kode, 403);
  });

  test('Dio menyuntikkan Cookie, User-Agent, dan X-Recaptcha-Token dari sesi aktif', () async {
    final notifier = SesiCloudflareNotifier();
    notifier.simpanSesi(
      cookies: 'cf_clearance=abc123',
      userAgent: 'TestAgent/1.0',
      recaptchaToken: 'token-recaptcha-xyz',
    );

    final dio = buatDioKlien();
    final adapter = _FakeRecaptchaAdapter();
    dio.httpClientAdapter = adapter;

    try {
      await dio.get<dynamic>('/pencarian/pt/ui');
    } on DioException {
      // Expected 403 from fake adapter
    }

    expect(adapter.lastOptions?.headers['Cookie'], 'cf_clearance=abc123');
    expect(adapter.lastOptions?.headers['User-Agent'], 'TestAgent/1.0');
    expect(
      adapter.lastOptions?.headers['X-Recaptcha-Token'],
      'token-recaptcha-xyz',
    );
  });

  test('ApiSumber.cariGlobal melempar ButuhVerifikasiCloudflare saat diblokir 403 reCAPTCHA', () async {
    final dio = buatDioKlien();
    dio.httpClientAdapter = _FakeRecaptchaAdapter();
    final api = ApiSumber(dio);

    expect(
      () => api.cariGlobal('budi'),
      throwsA(isA<ButuhVerifikasiCloudflare>()),
    );
  });

  test('PencarianGlobalNotifier tetap memuat kampus lokal & menandai butuhVerifikasi saat 403', () async {
    final dio = buatDioKlien();
    final api = ApiSumber(dio);
    final kampusRepo = KampusRepo(api);
    final stubRepo = _StubPencarianRepo(api, kampusRepo);
    var callbackTerpanggil = false;

    final vm = PencarianGlobalNotifier(
      stubRepo,
      onButuhVerifikasi: () => callbackTerpanggil = true,
    );

    vm.aturQuery('Universitas Indonesia');
    await vm.lakukanPencarian('Universitas Indonesia');

    expect(callbackTerpanggil, isTrue);
    expect(vm.state.butuhVerifikasi, isTrue);
    expect(vm.state.hasil.pt.length, 1);
    expect(vm.state.hasil.pt.first.nama, 'Universitas Indonesia');
    expect(vm.state.hasil.mahasiswa, isEmpty);
  });
}
