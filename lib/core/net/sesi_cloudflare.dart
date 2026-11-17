import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataSesiCloudflare {
  const DataSesiCloudflare({
    this.cookieHeader = '',
    this.userAgent = '',
    this.recaptchaToken = '',
    this.terverifikasi = false,
    this.sedangMemintaVerifikasi = false,
    this.customBaseUrl,
  });

  final String cookieHeader;
  final String userAgent;
  final String recaptchaToken;
  final bool terverifikasi;
  final bool sedangMemintaVerifikasi;
  final String? customBaseUrl;

  bool get adaSesiValid =>
      terverifikasi && (cookieHeader.isNotEmpty || recaptchaToken.isNotEmpty);

  DataSesiCloudflare copyWith({
    String? cookieHeader,
    String? userAgent,
    String? recaptchaToken,
    bool? terverifikasi,
    bool? sedangMemintaVerifikasi,
    String? customBaseUrl,
  }) =>
      DataSesiCloudflare(
        cookieHeader: cookieHeader ?? this.cookieHeader,
        userAgent: userAgent ?? this.userAgent,
        recaptchaToken: recaptchaToken ?? this.recaptchaToken,
        terverifikasi: terverifikasi ?? this.terverifikasi,
        sedangMemintaVerifikasi:
            sedangMemintaVerifikasi ?? this.sedangMemintaVerifikasi,
        customBaseUrl: customBaseUrl ?? this.customBaseUrl,
      );
}

class SesiCloudflareNotifier extends StateNotifier<DataSesiCloudflare> {
  SesiCloudflareNotifier() : super(const DataSesiCloudflare());

  // Akses statis cepat untuk Interceptor Dio
  static String? cookiesAktif;
  static String? userAgentAktif;
  static String? recaptchaTokenAktif;
  static String? baseUrlAktif;

  void simpanSesi({
    required String cookies,
    required String userAgent,
    String? recaptchaToken,
  }) {
    final tokenBersih = recaptchaToken?.trim() ?? '';
    cookiesAktif = cookies.trim().isNotEmpty ? cookies.trim() : null;
    userAgentAktif = userAgent.trim().isNotEmpty ? userAgent.trim() : null;
    if (tokenBersih.isNotEmpty) {
      recaptchaTokenAktif = tokenBersih;
    }

    state = state.copyWith(
      cookieHeader: cookies.trim(),
      userAgent: userAgent.trim(),
      recaptchaToken: tokenBersih.isNotEmpty ? tokenBersih : state.recaptchaToken,
      terverifikasi: true,
      sedangMemintaVerifikasi: false,
    );
  }

  /// Dipanggil saat API kembali menolak 403 (mis. token reCAPTCHA kadaluarsa)
  void tandaiKadaluarsa() {
    recaptchaTokenAktif = null;
    state = state.copyWith(
      recaptchaToken: '',
      terverifikasi: false,
      sedangMemintaVerifikasi: true,
    );
  }

  void butuhVerifikasi() {
    if (!state.sedangMemintaVerifikasi) {
      state = state.copyWith(sedangMemintaVerifikasi: true);
    }
  }

  void selesaiVerifikasi() {
    state = state.copyWith(sedangMemintaVerifikasi: false);
  }

  void aturCustomBaseUrl(String? url) {
    final clean = url?.trim();
    baseUrlAktif = (clean != null && clean.isNotEmpty) ? clean : null;
    state = state.copyWith(customBaseUrl: baseUrlAktif);
  }

  void reset() {
    cookiesAktif = null;
    userAgentAktif = null;
    recaptchaTokenAktif = null;
    state = const DataSesiCloudflare();
  }
}

final sesiCloudflareProvider =
    StateNotifierProvider<SesiCloudflareNotifier, DataSesiCloudflare>((ref) {
  return SesiCloudflareNotifier();
});
