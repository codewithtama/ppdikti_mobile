import '../model/kelulusan.dart';
import '../sumber/api_sumber.dart';
import '../sumber/cache_berkas.dart';

class KelulusanRepo {
  KelulusanRepo(this._api);
  final ApiSumber _api;

  Future<Kelulusan> dapatkanKelulusan(String kode, String idSp) async {
    final cachedRate = await CacheBerkas.bacaKelulusan(kode);
    if (cachedRate != null) {
      return Kelulusan(idSp: idSp, angka: cachedRate);
    }

    final dariApi = await _api.ambilGraduationRate(idSp);
    await CacheBerkas.simpanKelulusan(kode, dariApi.angka);
    return dariApi;
  }
}

