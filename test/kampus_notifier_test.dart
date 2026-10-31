import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pddikti_mobile/fitur/kampus/kampus_vm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DaftarKampusNotifier build dan segarkan tidak melempar galat Isolate unsendable', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 1. Verifikasi inisialisasi awal
    final initialData = await container.read(daftarKampusProvider.future);
    expect(initialData, isNotNull);
    expect(initialData.daftarKampus.isNotEmpty, isTrue);

    // 2. Verifikasi refresh/segarkan() yang sebelumnya bermasalah dengan Isolate.run
    final notifier = container.read(daftarKampusProvider.notifier);
    await notifier.segarkan();

    final refreshedData = container.read(daftarKampusProvider).value;
    expect(refreshedData, isNotNull);
    expect(refreshedData!.daftarKampus.isNotEmpty, isTrue);
  });
}

