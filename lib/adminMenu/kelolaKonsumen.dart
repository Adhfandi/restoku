import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KelolaKonsumenPage extends StatefulWidget {
  @override
  _KelolaKonsumenPageState createState() => _KelolaKonsumenPageState();
}

class _KelolaKonsumenPageState extends State<KelolaKonsumenPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchAllTransactions();
  }

  Future<void> _fetchAllTransactions() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('riwayatTransaksi').get();

      setState(() {
        _allTransactions = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _filteredTransactions = _allTransactions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data transaksi.'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error fetching transactions: $e');
    }
  }

  void _searchTransactions(String query) {
    setState(() {
      _filteredTransactions = _allTransactions
          .where((transaction) =>
              transaction['items'].any((item) =>
                  item['nama'].toLowerCase().contains(query.toLowerCase())) ||
              transaction['userId'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Konsumen'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari berdasarkan nama konsumen atau ID',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchTransactions(_searchController.text);
                  },
                ),
              ),
              onChanged: (value) {
                _searchTransactions(value);
              },
            ),
          ),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(child: Text('Tidak ada data transaksi.'))
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      final timestamp = transaction['timestamp'] as Timestamp?;
                      final totalJual =
                          transaction['totalJual'] as double? ?? 0.0;
                      final jumlahPembayaran =
                          transaction['jumlahPembayaran'] as double? ?? 0.0;
                      final kembalian =
                          transaction['kembalian'] as double? ?? 0.0;
                      final items =
                          transaction['items'] as List<dynamic>? ?? [];
                      final userId = transaction['userId'] as String? ?? '';

                      final transactionDate =
                          timestamp?.toDate() ?? DateTime.now();

                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ExpansionTile(
                          title: Text(
                            'Transaksi ${DateFormat('dd/MM/yyyy HH:mm').format(transactionDate)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('ID Konsumen: $userId'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Jual: Rp ${totalJual.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Jumlah Pembayaran: Rp ${jumlahPembayaran.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Kembalian: Rp ${kembalian.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Item yang Dibeli:',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Column(
                                    children: items.map((item) {
                                      return ListTile(
                                        title: Text(
                                            '${item['nama']} (x${item['quantity']})'),
                                        subtitle: Text(
                                            'Rp ${item['harga']} per item'),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
