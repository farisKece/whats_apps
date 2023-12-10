import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:whats_apps/app/data/models/users_model.dart';
import 'package:whats_apps/app/routes/app_pages.dart';

class AuthController extends GetxController {
  var isSkipIntro = false.obs;
  var isAuth = false.obs;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
      // scopes: [
      //   'email',
      //   'https://www.googleapis.com/auth/contacts.readonly',
      // ],
      );

  GoogleSignInAccount? _currentUser;
  UserCredential? userCredential;

  var user = UsersModel().obs;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> firstInitialized() async {
    await autoLogin().then((value) {
      if (value) {
        //jika nilai kembaliannya true
        isAuth.value = true;
      }
    });

    await skipIntro().then((value) {
      if (value) {
        isSkipIntro.value = true;
        print(isSkipIntro);
      }
    });
  }

  Future<bool> skipIntro() async {
    //skip introduction
    final box = GetStorage();
    if (box.read('skipIntro') != null || box.read('skipIntro') == true) {
      return true;
    }
    return false;
  }

  Future<bool> autoLogin() async {
    // auto login
    try {
      final isSignIn = await _googleSignIn.isSignedIn();
      if (isSignIn) {
        await _googleSignIn
            .signInSilently()
            .then((value) => _currentUser = value);
        final googleAuth = await _currentUser!.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );

        await FirebaseAuth.instance
            .signInWithCredential(credential)
            .then((value) => userCredential = value);

        print("USER CREDENTIAL");
        print(userCredential);

        // masukan data ke firebase...
        CollectionReference users = firestore.collection('users');

        await users.doc(_currentUser!.email).update({
          "lastSignInTime":
              userCredential!.user!.metadata.lastSignInTime!.toIso8601String(),
        });

        final currUser = await users.doc(_currentUser!.email).get();
        final currUserData = currUser.data() as Map<String, dynamic>;

        user(UsersModel.fromJson(currUserData));

        user.refresh();

        final listChats =
            await users.doc(_currentUser!.email).collection("chats").get();

        if (listChats.docs.length != 0) {
          List<ChatsUser> dataListChats = [];
          listChats.docs.forEach((element) {
            var dataDocChat = element.data();
            var dataDocChatId = element.id;
            dataListChats.add(ChatsUser(
              chatId: dataDocChatId,
              connection: dataDocChat["connection"],
              lastTime: dataDocChat["lastTime"],
              totalUnread: dataDocChat["total_unread"],
            ));
          });

          user.update((user) {
            user!.chats = dataListChats;
          });
        } else {
          user.update((user) {
            user!.chats = [];
          });
        }

        user.refresh();

        return true;
      }
      return false;
    } catch (err) {
      print("jancok");
      return false;
    }
  }

  Future<void> login() async {
    try {
      // untuk menghendle kebocoran data user sebelum login
      await _googleSignIn.signOut();

      // ini digunakan untuk mendapatkan google account user
      await _googleSignIn.signIn().then((value) => _currentUser = value);
      //mengecek  status login user
      final isSignIn = await _googleSignIn.isSignedIn();
      if (isSignIn) {
        //login berhasil
        print('SUDAH BERHASIL LOGIN DENGAN AKUN : ');
        print(_currentUser);

        final googleAuth = await _currentUser!.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );

        await FirebaseAuth.instance
            .signInWithCredential(credential)
            .then((value) => userCredential = value);
        print('User Credential');
        print(userCredential);

        //simpan status user sudah pernah login atau belum
        //& tidak akan menampilkan introduction
        final box = GetStorage();
        if (box.read('skipIntro') != null) {
          // karna login gak cuma satu kali, jadi di remove dulu
          box.remove('skipIntro');
        }
        box.write('skipIntro', true);

        //ngelebokno data nang firstore
        CollectionReference users = firestore.collection('users');

        final checkUsers = await users.doc(_currentUser!.email).get();

        if (checkUsers.data() == null) {
          await users.doc(_currentUser!.email).set({
            'uid': userCredential!.user!.uid,
            'name': _currentUser!.displayName,
            'keyName': _currentUser!.displayName!.substring(0, 1).toUpperCase(),
            'email': _currentUser!.email,
            'photoUrl': _currentUser!.photoUrl ?? "Gak ada foto",
            'status': "",
            'creationTime':
                userCredential!.user!.metadata.creationTime!.toIso8601String(),
            'lastSignInTime': userCredential!.user!.metadata.lastSignInTime!
                .toIso8601String(),
            'updateTime': DateTime.now().toIso8601String(),
          });

          await users.doc(_currentUser!.email).collection("chats");
        } else {
          await users.doc(_currentUser!.email).update({
            'lastSignInTime': userCredential!.user!.metadata.lastSignInTime!
                .toIso8601String(),
          });
        }

        final currUser = await users.doc(_currentUser!.email).get();

        final currUserData = currUser.data() as Map<String, dynamic>;

        user(UsersModel.fromJson(currUserData));

        user.refresh();

        final listChats =
            await users.doc(_currentUser!.email).collection("chats").get();

        if (listChats.docs.isNotEmpty) {
          List<ChatsUser> dataListChats = [];

          listChats.docs.forEach((element) {
            var dataDocChat = element.data();
            var dataDocChatId = element.id;

            dataListChats.add(ChatsUser(
              chatId: dataDocChatId,
              connection: dataDocChat["connection"],
              lastTime: dataDocChat["lastTime"],
              totalUnread: dataDocChat["total_unread"],
            ));
          });
          user.update((user) {
            user!.chats = dataListChats;
          });
        } else {
          user.update((user) {
            user!.chats = [];
          });
        }

        user.refresh();

        isAuth.value = true;
        Get.offAllNamed(Routes.HOME);
      } else {
        //login gagal
        print('TIDAK BERHASIL LOGIN WKWKWKWKWKWWKWKWK');
      }
    } catch (error) {
      print(error);
    }
  }

  void logout() async {
    await _googleSignIn.disconnect();
    await _googleSignIn.signOut();
    Get.offAllNamed(Routes.LOGINPAGE);
  }

  // profile
  void changeProfile(String name, String status) {
    String date = DateTime.now().toIso8601String();
    CollectionReference users = firestore.collection('users');
    users.doc(_currentUser!.email).update({
      "name": name,
      "keyName": name.substring(0, 1).toUpperCase(),
      "status": status,
      'lastSignInTime':
          userCredential!.user!.metadata.lastSignInTime!.toIso8601String(),
      "updateTime": date,
    });

    // update model
    user.update((user) {
      user!.name = name;
      user.keyName = name.substring(0, 1).toUpperCase();
      user.status = status;
      user.lastSignInTime =
          userCredential!.user!.metadata.lastSignInTime!.toIso8601String();
      user.updateTime = date;
    });

    user.refresh();
    Get.defaultDialog(title: "Succes", middleText: "Berhasil mengganti");
  }

  void updateStatus(String status) {
    String date = DateTime.now().toIso8601String();
    CollectionReference users = firestore.collection('users');
    users.doc(_currentUser!.email).update({
      "status": status,
      'lastSignInTime':
          userCredential!.user!.metadata.lastSignInTime!.toIso8601String(),
      "updateTime": date,
    });

    // update model
    user.update((user) {
      user!.status = status;
      user.lastSignInTime =
          userCredential!.user!.metadata.lastSignInTime!.toIso8601String();
      user.updateTime = date;
    });

    user.refresh();
    Get.defaultDialog(title: "Succes", middleText: "Update Status Success");
  }

  void updatePhotoUrl(String url) async {
    String date = DateTime.now().toIso8601String();
    CollectionReference users = firestore.collection('users');
    await users.doc(_currentUser!.email).update({
      "photoUrl": url,
      "updateTime": date,
    });

    // update model
    user.update((user) {
      user!.photoUrl = url;
      user.updateTime = date;
    });

    user.refresh();
    Get.defaultDialog(
        title: "Success", middleText: "Ubah photo profile success!");
  }

  // search
  void addNewConnection(String friendEmail) async {
    var chat_Id;
    bool flagNewConnection = false;
    String date = DateTime.now().toIso8601String();
    CollectionReference chats = firestore.collection("chats");
    CollectionReference users = firestore.collection("users");

    final docChats =
        await users.doc(_currentUser!.email).collection("chats").get();

    if (docChats.docs.isNotEmpty) {
      //user udah pernah chat dengan siapapun
      final checkConnection = await users
          .doc(_currentUser!.email)
          .collection("chats")
          .where("connection", isEqualTo: friendEmail)
          .get();

      if (checkConnection.docs.isNotEmpty) {
        //sudah ada chat
        flagNewConnection = false;
        //chat_id dari chats collection
        chat_Id = checkConnection.docs[0].id;
      } else {
        //blm pernah chat dengan siapapun
        //buat koneksi
        flagNewConnection = true;
      }
    } else {
      // blm pernah chat dengan siapapun
      //buat koneksi
      flagNewConnection = true;
    }

    //ngefix
    if (flagNewConnection) {
      // cek dari chat collection => connections == dengan kedua nya
      final chatsDocs = await chats.where(
        "connections",
        whereIn: [
          [
            _currentUser!.email, // ini yang pencari
            friendEmail, // ini yang dicari
          ],
          [
            friendEmail, // ini yang dicari
            _currentUser!.email, // ini yang pencari
          ],
        ],
      ).get();

      if (chatsDocs.docs.isNotEmpty) {
        // ada data chatnya udh ada koneksi
        final chatDataId = chatsDocs.docs[0].id;
        final chatData = chatsDocs.docs[0].data() as Map<String, dynamic>;

        await users
            .doc(_currentUser!.email)
            .collection("chats")
            .doc(chatDataId)
            .set(
          {
            "connection": friendEmail,
            "lastTime": chatData["lastTime"],
            "total_unread": 0,
          },
        );

        final listChats =
            await users.doc(_currentUser!.email).collection("chats").get();

        if (listChats.docs.isNotEmpty) {
          List<ChatsUser> dataListChats = List.empty();

          listChats.docs.forEach((element) {
            var dataDocChat = element.data();
            var dataDocChatId = element.id;

            dataListChats.add(
              ChatsUser(
                chatId: dataDocChatId,
                connection: dataDocChat["connection"],
                lastTime: dataDocChat["lastTime"],
                totalUnread: dataDocChat["total_unread"],
              ),
            );
          });
          user.update((user) {
            user!.chats = dataListChats;
          });
        } else {
          user.update((user) {
            user!.chats = [];
          });
        }

        chat_Id = chatDataId;
        print("WOOOOYYYY LIAT INI COK");
        print(chat_Id);

        user.refresh();
      } else {
        // buat baru, mereka berdua blm ada koneksi
        final newChatDoc = await chats.add({
          "connections": [
            _currentUser!.email,
            friendEmail,
          ],
        });

        await chats.doc(newChatDoc.id).collection("chat");

        await users
            .doc(_currentUser!.email)
            .collection("chats")
            .doc(newChatDoc.id)
            .set({
          "connection": friendEmail,
          "lastTime": date,
          "total_unread": 0,
        });

        final listChats =
            await users.doc(_currentUser!.email).collection("chats").get();

        if (listChats.docs.isNotEmpty) {
          List<ChatsUser> dataListChats = List<ChatsUser>.empty();

          listChats.docs.forEach(
            (element) {
              var dataDocChat = element.data();
              var dataDocChatId = element.id;

              dataListChats.add(
                ChatsUser(
                  chatId: dataDocChatId,
                  connection: dataDocChat["connection"],
                  lastTime: dataDocChat["lastTime"],
                  totalUnread: dataDocChat["total_unread"],
                ),
              );
            },
          );
          user.update((user) {
            user!.chats = dataListChats;
          });
        } else {
          user.update((user) {
            user!.chats = [];
          });
        }

        chat_Id = newChatDoc.id;

        user.refresh();
      }
    }

    final updateStatusChat = await chats
        .doc(chat_Id)
        .collection("chat")
        .where("isRead", isEqualTo: false)
        .where("penerima", isEqualTo: _currentUser!.email)
        .get();

    updateStatusChat.docs.forEach((element) async {
      element.id;
      await chats
          .doc(chat_Id)
          .collection("chat")
          .doc(element.id)
          .update({"isRead": true});
    });

    await users
        .doc(_currentUser!.email)
        .collection("chats")
        .doc(chat_Id)
        .update({
      "total_unread": 0,
    });

    print(chat_Id);
    Get.toNamed(Routes.CHAT_ROOM, arguments: {
      "chat_id": "$chat_Id",
      "friendEmail": friendEmail,
    });
  }
}
