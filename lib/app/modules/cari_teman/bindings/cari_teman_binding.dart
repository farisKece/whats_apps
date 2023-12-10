import 'package:get/get.dart';

import '../controllers/cari_teman_controller.dart';

class CariTemanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CariTemanController>(
      () => CariTemanController(),
    );
  }
}
