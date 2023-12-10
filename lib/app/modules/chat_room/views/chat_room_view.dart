import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:whats_apps/app/controllers/auth_controller.dart';

import '../controllers/chat_room_controller.dart';

class ChatRoomView extends GetView<ChatRoomController> {
  final authC = Get.find<AuthController>();
  final String chat_id = (Get.arguments as Map<String, dynamic>)["chat_id"];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 5,
              ),
              const Icon(Icons.arrow_back),
              const SizedBox(
                width: 5,
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey,
                child: StreamBuilder<DocumentSnapshot<Object?>>(
                    stream: controller.streamFriendData(
                        (Get.arguments as Map<String, dynamic>)["friendEmail"]),
                    builder: (context, snapFriendUser) {
                      if (snapFriendUser.connectionState ==
                          ConnectionState.active) {
                        var dataFriend =
                            snapFriendUser.data!.data() as Map<String, dynamic>;
                        if (dataFriend["photoUrl"] == "Gak ada foto") {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              'assets/logo/noimage.png',
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              dataFriend["photoUrl"],
                              fit: BoxFit.cover,
                              height: 100,
                              width: 100,
                            ),
                          );
                        }
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/logo/noimage.png',
                          fit: BoxFit.cover,
                        ),
                      );
                    }),
              )
            ],
          ),
        ),
        title: StreamBuilder<DocumentSnapshot<Object?>>(
          stream: controller.streamFriendData(
              (Get.arguments as Map<String, dynamic>)["friendEmail"]),
          builder: (context, snapFriendUser) {
            if (snapFriendUser.connectionState == ConnectionState.active) {
              var dataFriend =
                  snapFriendUser.data!.data() as Map<String, dynamic>;
              return dataFriend["status"] == ""
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dataFriend["name"],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dataFriend["name"],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dataFriend["status"],
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading ..',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Loading ..',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
      ),
      body: WillPopScope(
        onWillPop: () {
          if (controller.isEmojiVisible.isTrue) {
            controller.isEmojiVisible.value = false;
          } else {
            Navigator.pop(context);
          }

          return Future.value(false);
        },
        child: Column(
          children: [
            Expanded(
              child: Container(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: controller.streamChats(chat_id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      var allData = snapshot.data!.docs;
                      Timer(
                        Duration.zero,
                        () => controller.scrollC.jumpTo(
                            controller.scrollC.position.maxScrollExtent),
                      );
                      return ListView.builder(
                        controller: controller.scrollC,
                        itemCount: allData.length,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "${allData[index]["groupTime"]}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                ItemChat(
                                  msg: allData[index]["pesan"],
                                  isSender: allData[index]["pengirim"] ==
                                          authC.user.value.email
                                      ? true
                                      : false,
                                  time: allData[index]["time"],
                                ),
                              ],
                            );
                          } else {
                            if (allData[index]["groupTime"] ==
                                allData[index - 1]["groupTime"]) {
                              return ItemChat(
                                msg: allData[index]["pesan"],
                                isSender: allData[index]["pengirim"] ==
                                        authC.user.value.email
                                    ? true
                                    : false,
                                time: allData[index]["time"],
                              );
                            } else {
                              return Column(
                                children: [
                                  Text(
                                    "${allData[index]["groupTime"]}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  ItemChat(
                                    msg: allData[index]["pesan"],
                                    isSender: allData[index]["pengirim"] ==
                                            authC.user.value.email
                                        ? true
                                        : false,
                                    time: allData[index]["time"],
                                  ),
                                ],
                              );
                            }
                          }
                        },
                      );
                    }
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                  bottom: controller.isEmojiVisible.isTrue
                      ? 5
                      : context.mediaQueryPadding.bottom),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              width: Get.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      child: TextField(
                        autocorrect: false,
                        controller: controller.chatC,
                        focusNode: controller.focusNode,
                        onEditingComplete: () => controller.newChat(
                            authC.user.value.email!,
                            Get.arguments as Map<String, dynamic>,
                            controller.chatC.text),
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            onPressed: () {
                              controller.isEmojiVisible.toggle();
                              controller.focusNode.unfocus();
                              controller.focusNode.canRequestFocus = true;
                            },
                            icon: const Icon(
                              Icons.emoji_emotions_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Material(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(100),
                    child: InkWell(
                      onTap: () => controller.newChat(
                          authC.user.value.email!,
                          Get.arguments as Map<String, dynamic>,
                          controller.chatC.text),
                      borderRadius: BorderRadius.circular(100),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Offstage(
                offstage: !controller.isEmojiVisible.value,
                child: SizedBox(
                  height: Get.height * .35,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      // controller.addEmojiToChat(emoji);
                    },
                    onBackspacePressed: () {
                      // Do something when the user taps the backspace button (optional)
                      // Set it to null to hide the Backspace-Button
                    },
                    textEditingController: controller
                        .chatC, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
                    config: Config(
                      columns: 7,
                      emojiSizeMax: 32 *
                          (Platform.isAndroid
                              ? 0.9
                              : 1.0), // Issue: https://github.com/flutter/flutter/issues/28894
                      verticalSpacing: 0,
                      horizontalSpacing: 0,
                      gridPadding: EdgeInsets.zero,
                      initCategory: Category.RECENT,
                      bgColor: Color(0xFFF2F2F2),
                      indicatorColor: Color(0xFFB71C1C),
                      iconColor: Colors.grey,
                      iconColorSelected: Color(0xFFB71C1C),
                      backspaceColor: Color(0xFFB71C1C),
                      skinToneDialogBgColor: Colors.white,
                      skinToneIndicatorColor: Colors.grey,
                      enableSkinTones: true,
                      recentTabBehavior: RecentTabBehavior.RECENT,
                      recentsLimit: 28,
                      noRecents: const Text(
                        'No Recents',
                        style: TextStyle(fontSize: 20, color: Colors.black26),
                        textAlign: TextAlign.center,
                      ), // Needs to be const Widget
                      loadingIndicator:
                          const SizedBox.shrink(), // Needs to be const Widget
                      tabIndicatorAnimDuration: kTabScrollDuration,
                      categoryIcons: const CategoryIcons(),
                      buttonMode: ButtonMode.MATERIAL,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ItemChat extends StatelessWidget {
  const ItemChat({
    super.key,
    required this.isSender,
    required this.msg,
    required this.time,
  });

  final bool isSender;
  final String msg;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      // atas 15 bawah 15 kiri 20 kanan 20
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            // width: Get.width * .8,
            constraints: BoxConstraints(
              maxWidth: Get.width * 0.8,
            ),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: isSender
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15))
                  : const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15)),
            ),
            child: Text(
              msg,
              style: TextStyle(color: Colors.white),
              // textAlign: ali,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(DateFormat.jm().format(DateTime.parse(time))),
        ],
      ),
    );
  }
}

// Modifikasi yang dilakukan adalah menambahkan atribut constraints: BoxConstraints(maxWidth: Get.width * 0.6) pada widget Container. Atribut ini akan membatasi lebar maksimum pesan menjadi 60% dari lebar layar. Jika pesan melebihi lebar tersebut, maka pesan akan dipotong secara otomatis.

// Berikut adalah penjelasan kode tersebut dalam bahasa Indonesia:

// Kode ini mendefinisikan kelas ItemChat yang merupakan widget untuk menampilkan pesan obrolan.
// Constructor kelas ItemChat memiliki parameter isSender yang menentukan apakah pesan tersebut dikirim atau diterima.
// Metode build dari kelas ItemChat mengembalikan widget Container yang berisi widget Column.
// Widget Column berisi widget Container untuk menampilkan pesan dan widget Text untuk menampilkan waktu pengiriman pesan.
// Widget Container untuk menampilkan pesan memiliki atribut constraints: BoxConstraints(maxWidth: Get.width * 0.6) yang membatasi lebar maksimum pesan menjadi 60% dari lebar layar.
// Atribut decoration dari widget Container untuk menampilkan pesan digunakan untuk mengatur warna latar belakang dan bentuk pesan.
// Widget Text untuk menampilkan pesan memiliki atribut style yang digunakan untuk mengatur warna teks pesan.
// Atribut alignment dari widget Container untuk menampilkan pesan digunakan untuk mengatur posisi pesan di layar.
// Semoga penjelasan ini bermanfaat.

//sizedbox(
//hight: Get.height * .35)