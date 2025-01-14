import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RiwayatBelanja extends StatefulWidget {
  @override
  _RiwayatBelanjaState createState() => _RiwayatBelanjaState();
}

class _RiwayatBelanjaState extends State<RiwayatBelanja> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Belanja'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Simplified query to avoid composite index requirement
        stream: _firestore
            .collection('riwayatTransaksi')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('Tidak ada riwayat transaksi'),
            );
          }

          // Sort documents in memory instead of in query
          var docs = snapshot.data!.docs;
          docs.sort((a, b) {
            var aTimestamp =
                (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            var bTimestamp =
                (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            return bTimestamp.compareTo(aTimestamp); // Descending order
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var transaction = docs[index];
              var data = transaction.data() as Map<String, dynamic>;
              var timestamp = data['timestamp'] as Timestamp;
              var date = timestamp.toDate();
              var items = List<Map<String, dynamic>>.from(data['items']);

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(
                    'Transaksi ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Total: Rp ${data['totalJual'].toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.green),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Pembelian:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...items.map((item) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['nama']} (x${item['quantity']})',
                                      ),
                                    ),
                                    Text(
                                      'Rp ${(item['total']).toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                              )),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Pembayaran:'),
                              Text(
                                'Rp ${data['jumlahPembayaran'].toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Kembalian:'),
                              Text(
                                'Rp ${data['kembalian'].toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
