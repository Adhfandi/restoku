import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'userMenu/riwayatBelanja.dart';
import 'login.dart';
import 'from_pembayaran.dart';
import 'userMenu/callCenterPage.dart';
import 'userMenu/LokasiMapsPage.dart';
import 'userMenu/smsCenterPage.dart';
import 'userMenu/UpdateUserPasswordPage.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = '';
  String userEmail = '';
  double totalJual = 0.0;
  List<Map<String, dynamic>> selectedItems = [];
  // Add a map to track quantities
  Map<String, int> itemQuantities = {};

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  Future<void> getUserName() async {
    if (user != null) {
      // Try to get display name from Firebase Auth first
      if (user!.displayName != null && user!.displayName!.isNotEmpty) {
        setState(() {
          userName = user!.displayName!;
        });
      } else {
        // If no display name in Auth, try to get from Firestore
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            var userData = userDoc.data() as Map<String, dynamic>;
            setState(() {
              // Assuming you have a 'name' field in your Firestore document
              userName = userData['name'] ?? 'User';
            });
          }
        } catch (e) {
          print('Error fetching user data: $e');
          setState(() {
            userName = 'User';
          });
        }
      }
    }
  }

  void handleTap(Map<String, dynamic> item) {
    setState(() {
      String itemId = item['id'].toString();

      if (itemQuantities.containsKey(itemId)) {
        // Increment quantity if item exists
        itemQuantities[itemId] = (itemQuantities[itemId] ?? 0) + 1;
      } else {
        // Add new item and set quantity to 1
        selectedItems.add(item);
        itemQuantities[itemId] = 1;
      }

      // Recalculate total
      calculateTotal();
    });
  }

  void handleDoubleTap(Map<String, dynamic> item) {
    setState(() {
      String itemId = item['id'].toString();

      if (itemQuantities.containsKey(itemId)) {
        if (itemQuantities[itemId]! > 1) {
          // Decrease quantity if more than 1
          itemQuantities[itemId] = itemQuantities[itemId]! - 1;
        } else {
          // Remove item if quantity would become 0
          itemQuantities.remove(itemId);
          selectedItems
              .removeWhere((element) => element['id'].toString() == itemId);
        }
        // Recalculate total
        calculateTotal();
      }
    });
  }

  void calculateTotal() {
    double newTotal = 0.0;
    for (var item in selectedItems) {
      String itemId = item['id'].toString();
      int quantity = itemQuantities[itemId] ?? 0;
      newTotal += (item['harga'] as num).toDouble() * quantity;
    }
    totalJual = newTotal;
  }

  goToLogin(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('User Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B3F35),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'Call Center':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CallCenterPage()),
                  );
                  break;
                case 'SMS Center':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SMSCenterPage()),
                  );
                  break;
                case 'Lokasi/Maps':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LokasiPage()),
                  );
                  break;
                case 'Update User & Password':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UpdateUserPasswordPage()),
                  );
                  break;
                case 'Riawayat Belanja':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RiwayatBelanja()),
                  );
                  break;
                case 'Logout':
                  FirebaseAuth.instance.signOut();
                  goToLogin(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'Call Center',
                  child: Text('Call Center'),
                ),
                PopupMenuItem(
                  value: 'SMS Center',
                  child: Text('SMS Center'),
                ),
                PopupMenuItem(
                  value: 'Lokasi/Maps',
                  child: Text('Lokasi/Maps'),
                ),
                PopupMenuItem(
                  value: 'Update User & Password',
                  child: Text('Update User & Password'),
                ),
                PopupMenuItem(
                  value: 'Riawayat Belanja',
                  child: Text('Riawayat Belanja'),
                ),
                PopupMenuItem(
                  value: 'Logout',
                  child: Text('Logout'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Welcome, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${user?.email ?? "No email"}',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          // ...existing code...
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('barang').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String imagePath = 'assets/${data['gambar']}';

                    return GestureDetector(
                      onTap: () => handleTap(data),
                      onDoubleTap: () => handleDoubleTap(data),
                      child: Card(
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                child: FadeInImage(
                                  placeholder:
                                      AssetImage('assets/bukutulis.jpg'),
                                  image: AssetImage(imagePath),
                                  fit: BoxFit.cover,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) {
                                    return Image.asset('assets/pensil.jpg',
                                        fit: BoxFit.cover);
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(data['nm_brg']),
                                            content: Text(data['deskripsi'] ??
                                                'No description available'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Close'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Text(
                                      data['nm_brg'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${data['harga'].toString()}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Modified bottom section to show items with quantities
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                if (selectedItems.isNotEmpty) ...[
                  Text(
                    'Selected Items:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      itemCount: selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = selectedItems[index];
                        final quantity =
                            itemQuantities[item['id'].toString()] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['nm_brg']} x$quantity',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                'Rp ${(item['harga'] * quantity).toString()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(),
                ],
                Divider(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FromPembayaran(
                          totalJual: totalJual,
                          selectedItems: selectedItems.map((item) {
                            // Tambahkan quantity ke setiap item
                            return {
                              ...item, // Spread operator untuk menyalin semua data item
                              'quantity':
                                  itemQuantities[item['id'].toString()] ??
                                      1, // Ambil quantity dari itemQuantities
                            };
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Jual:',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rp ${totalJual.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
