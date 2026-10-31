import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataSesiCloudflare {
  const DataSesiCloudflare({
    this.cookieHeader = '',
    this.userAgent = '',
    this.terverifikasi = false,
    this.sedangMemintaVerifikasi = false,
    this.customBaseUrl,
  });

  final String cookieHeader;
  final String userAgent;
  final bool terverifikasi;
  final bool sedangMemintaVerifikasi;
  final String? customBaseUrl;

  bool get adaSesiValid => terverifikasi && cookieHeader.isNotEmpty;

  DataSesiCloudflare copyWith({
    String? cookieHeader,
    String? userAgent,
    bool? terverifikasi,
    bool? sedangMemintaVerifikasi,
    String? customBaseUrl,
  }) =>
      DataSesiCloudflare(
        cookieHeader: cookieHeader ?? this.cookieHeader,
        userAgent: userAgent ?? this.userAgent,
        terverifikasi: terverifikasi ?? this.terverifikasi,
        sedangMemintaVerifikasi: sedangMemintaVerifikasi ?? this.sedangMemintaVerifikasi,
        customBaseUrl: customBaseUrl ?? this.customBaseUrl,
      );
}

class SesiCloudflareNotifier extends StateNotifier<DataSesiCloudflare> {
  SesiCloudflareNotifier() : super(const DataSesiCloudflare());

  // Akses statis cepat untuk Interceptor Dio
  static String? cookiesAktif;
  static String? userAgentAktif;
  static String? baseUrlAktif;

  void simpanSesi({required String cookies, required String userAgent}) {
    cookiesAktif = cookies;
    userAgentAktif = userAgent;

    state = state.copyWith(
      cookieHeader: cookies,
      userAgent: userAgent,
      terverifikasi: true,
      sedangMemintaVerifikasi: false,
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
    state = const DataSesiCloudflare();
  }
}

final sesiCloudflareProvider =
    StateNotifierProvider<SesiCloudflareNotifier, DataSesiCloudflare>((ref) {
  return SesiCloudflareNotifier();
});

