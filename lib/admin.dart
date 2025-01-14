import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // Pastikan import ini ditambahkan
import 'adminMenu/kelolaKonsumen.dart';
import 'adminMenu/kelolaProduk.dart';
import 'adminMenu/tabelUser.dart';
import 'adminMenu/laporanPenjualanPeriodik.dart';
import 'adminMenu/laporanPenjualanGlobal.dart';

class Admin extends StatefulWidget {
  const Admin({Key? key}) : super(key: key);

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = '';

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
              userName = userData['name'] ?? 'User  ';
            });
          }
        } catch (e) {
          print('Error fetching user data: $e');
          setState(() {
            userName = 'User  ';
          });
        }
      }
    }
  }

  goToLogin(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B3F35),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              goToLogin(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
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
              'Email: ${user?.email ?? "No email"}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            // Add the vertical boxes here
            Expanded(
              child: ListView(
                children: [
                  _buildBox('Tabel User', Icons.login, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TabelUserPage()),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildBox('Kelola Produk', Icons.shopping_cart, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductListScreen()),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildBox('Kelola Konsumen', Icons.people, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => KelolaKonsumenPage()),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildBox('Laporan Penjualan Global', Icons.bar_chart, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LaporanPenjualanGlobalPage()),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildBox('Laporan Penjualan Periodik', Icons.timeline, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LaporanPenjualanPeriodikPage()),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // Mengubah lebar menjadi penuh
        height: 80, // Mengatur tinggi box
        decoration: BoxDecoration(
          color: Color(0xFFF6F2E6),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3), // mengubah posisi bayangan
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(icon, size: 40, color: Colors.black),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
