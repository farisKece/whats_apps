import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CariTemanController extends GetxController {
  late TextEditingController searchC;

  var queryAwal = [].obs;
  var tempSearch = [].obs;

  FirebaseFirestore fireStore = FirebaseFirestore.instance;

  void searchFriend(String data, String email) async {
    print('Search : $data');

    if (data.isEmpty) {
      queryAwal.value = [];
      tempSearch.value = [];
    } else {
      var capitalized = data.substring(0, 1).toUpperCase() + data.substring(1);
      print(capitalized);

      if (queryAwal.isEmpty && data.length == 1) {
        //fungsi ini dijalankan pas ketikan pertama
        CollectionReference users = fireStore.collection("users");
        final keyNameResult = await users
            .where("keyName", isEqualTo: data.substring(0, 1).toUpperCase()).where("email", isNotEqualTo: email)
            .get();

        print("Total data : ${keyNameResult.docs.length}");
        if (keyNameResult.docs.isNotEmpty) {
          for (int i = 0; i < keyNameResult.docs.length; i++) {
            queryAwal.add(keyNameResult.docs[i].data() as Map<String, dynamic>);
          }
          print("Query Result : ");
          print(queryAwal);
        } else {
          print("TIDAK ADA DATA");
        }
      }

      // String name = "yusuf ganteng";
      // name.startsWith(pattern)

      if (queryAwal.isNotEmpty) {
        tempSearch.value = [];
        try {
          for (var element in queryAwal) {
            if (element["name"]
                .toLowerCase()
                .startsWith(capitalized.toLowerCase())) {
              print("berhasil menambahkan");
              tempSearch.add(element);
            } else {
              print("gagal menambahkan");
            }
          }
        } catch (e) {
          print(e);
        }
        print('temsearch : ');
        print(tempSearch);
        print("query awal");
        print(queryAwal);
      }
    }
    queryAwal.refresh();
    tempSearch.refresh();
  }

  @override
  void onInit() {
    searchC = TextEditingController();
    super.onInit();
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }
}
