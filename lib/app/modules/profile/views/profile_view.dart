import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:whats_apps/app/controllers/auth_controller.dart';
import 'package:whats_apps/app/routes/app_pages.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  final authC = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => authC.logout(),
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Column(
            children: [
              Obx(
                () => AvatarGlow(
                  endRadius: 110,
                  glowColor: Colors.black,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    margin: const EdgeInsets.all(15),
                    width: 175,
                    height: 175,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(200),
                      child: authC.user.value.photoUrl! == "Gak ada foto"
                          ? Image.asset(
                              'assets/logo/noimage.png',
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              authC.user.value.photoUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Obx(
                () => Text(
                  '${authC.user.value.name!}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                '${authC.user.value.email!}',
                style: TextStyle(
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                ListTile(
                  onTap: () => Get.toNamed(Routes.UPDATE_STATUS),
                  leading: Icon(Icons.note_add_outlined),
                  title: const Text(
                    'Update Status',
                    style: TextStyle(fontSize: 22),
                  ),
                  trailing: Icon(Icons.arrow_right),
                ),
                ListTile(
                  onTap: () => Get.toNamed(Routes.CHANGE_PROFILE),
                  leading: Icon(Icons.note_add_outlined),
                  title: const Text(
                    'Change Profile',
                    style: TextStyle(fontSize: 22),
                  ),
                  trailing: Icon(Icons.arrow_right),
                ),
                ListTile(
                  leading: Icon(Icons.color_lens),
                  title: Text(
                    'Change Theme',
                    style: TextStyle(fontSize: 22),
                  ),
                  trailing: Text('Light'),
                )
              ],
            ),
          ),
          Container(
            margin:
                EdgeInsets.only(bottom: context.mediaQueryPadding.bottom + 10),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WhatsApps',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'v.1.0',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
