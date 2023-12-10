// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:intl/intl.dart';

class ChatRoomController extends GetxController {
  late TextEditingController chatC;
  int total_unread = 0;
  late FocusNode focusNode;
  late ScrollController scrollC;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamChats(String chat_id) {
    CollectionReference chats = firestore.collection("chats");

    return chats
        .doc(chat_id)
        .collection("chat")
        .orderBy("time")
        .snapshots(); // snapshot itu untuk memantau apa yang terjadi di lokasi/path
  }

  Stream<DocumentSnapshot<Object?>> streamFriendData(String friendEmail) {
    CollectionReference users = firestore.collection("users");

    return users.doc(friendEmail).snapshots();
  }

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  var isEmojiVisible = false.obs;

  void newChat(String email, Map<String, dynamic> argument, String chat) async {
    if (chat != "") {
      CollectionReference chats = firestore.collection("chats");
      CollectionReference users = firestore.collection("users");
      String date = DateTime.now().toIso8601String();

      await chats.doc(argument["chat_id"]).collection("chat").add({
        "pengirim": email,
        "penerima": argument["friendEmail"],
        "pesan": chat,
        "time": date,
        "isRead": false,
        "groupTime": DateFormat.yMMMd("en_Us").format(DateTime.parse(date))
      });

      Timer(Duration.zero, () {
        scrollC.jumpTo(scrollC.position.maxScrollExtent);
      });

      chatC.clear();

      await users
          .doc(email)
          .collection("chats")
          .doc(argument["chat_id"])
          .update({
        "lastTime": date,
      });

      final checkChatsFriend = await users
          .doc(argument["friendEmail"])
          .collection("chats")
          .doc(argument["chat_id"])
          .get();

      if (checkChatsFriend.exists) {
        // exist on firend database

        // cek total unread pertama
        final checkTotalUnread = await chats
            .doc(argument["chat_id"])
            .collection("chat")
            .where("isRead", isEqualTo: false)
            .where("pengirim", isEqualTo: email)
            .get();

        // total unread for friend
        total_unread = checkTotalUnread.docs.length;

        await users
            .doc(argument["friendEmail"])
            .collection("chats")
            .doc(argument["chat_id"])
            .update({
          "lastTime": date,
          "total_unread": total_unread,
        });
      } else {
        // not exist on friend database
        await users
            .doc(argument["friendEmail"])
            .collection("chats")
            .doc(argument["chat_id"])
            .set({
          "connection": email,
          "lastTime": date,
          "total_unread": 1,
        });
      }
    }
    //---------- ini artefak unread ya jangan di hapus --------
    // if (checkChatsFriend.exists) {
    //   await users
    //       .doc(argument["friendEmail"])
    //       .collection("chats")
    //       .doc(argument["chat_id"])
    //       .get()
    //       .then((value) => total_unread = value.data()!["total_unread"] as int);
    //   // update for friend database
    //   await users
    //       .doc(argument["friendEmail"])
    //       .collection("chats")
    //       .doc(argument["chat_id"])
    //       .update({
    //     "lastTime": date,
    //     "total_unread": total_unread + 1,
    //   });
    // } else {
    //   // new for friend database
    //   await users
    //       .doc(argument["friendEmail"])
    //       .collection("chats")
    //       .doc(argument["chat_id"])
    //       .set({
    //     "connection": email,
    //     "lastTime": date,
    //     "total_unread": total_unread + 1,
    //   });
    // }
  }

  @override
  void onInit() {
    chatC = TextEditingController();
    scrollC = ScrollController();
    focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        isEmojiVisible.value = false;
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    chatC.dispose();
    scrollC.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
