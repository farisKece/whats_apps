Bug yang Anda alami terjadi karena Image.network() memiliki ukuran default yang tidak terbatas. Untuk mengatasinya, Anda perlu mengatur ukuran Image.network() agar sesuai dengan ukuran CircleAvatar(). Anda bisa menggunakan salah satu cara berikut:

Cara pertama adalah dengan menggunakan parameter width dan height pada Image.network(). Misalnya:
leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.black26,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Image.network(
                                          "${data["photoUrl"]}",
                                          fit: BoxFit.cover,
                                          width: 30,
                                          height: 30,
                                        ),
                                      ),
                                    ),
Cara kedua adalah dengan menggunakan parameter constraints pada Image.network(). Misalnya:
leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.black26,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Image.network(
                                          "${data["photoUrl"]}",
                                          fit: BoxFit.cover,
                                          constraints: BoxConstraints.tight(
                                            Size(30, 30),
                                          ),
                                        ),
                                      ),
                                    ),
Dengan menggunakan salah satu cara di atas, foto yang masuk ke Image.network() akan mengikuti ukuran CircleAvatar().

1.7.10 kotlin