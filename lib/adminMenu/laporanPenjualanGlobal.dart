import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPenjualanGlobalPage extends StatefulWidget {
  @override
  _LaporanPenjualanGlobalPageState createState() =>
      _LaporanPenjualanGlobalPageState();
}

class _LaporanPenjualanGlobalPageState
    extends State<LaporanPenjualanGlobalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _exportToPdf(List<Map<String, dynamic>> transactions) async {
    final pdf = pw.Document();

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Laporan Penjualan Global',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              ...transactions.map((transaction) {
                final timestamp = transaction['timestamp'] as Timestamp?;
                final totalJual = transaction['totalJual'] as double? ?? 0.0;
                final jumlahPembayaran =
                    transaction['jumlahPembayaran'] as double? ?? 0.0;
                final kembalian = transaction['kembalian'] as double? ?? 0.0;
                final items = transaction['items'] as List<dynamic>? ?? [];

                final transactionDate = timestamp?.toDate() ?? DateTime.now();

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Transaksi ${DateFormat('dd/MM/yyyy HH:mm').format(transactionDate)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Total Jual: Rp ${totalJual.toStringAsFixed(2)}'),
                    pw.Text(
                        'Jumlah Pembayaran: Rp ${jumlahPembayaran.toStringAsFixed(2)}'),
                    pw.Text('Kembalian: Rp ${kembalian.toStringAsFixed(2)}'),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Item yang Dibeli:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    ...items.map((item) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${item['nama']} (x${item['quantity']})'),
                          pw.Text('Rp ${item['harga']} per item'),
                          pw.SizedBox(height: 5),
                        ],
                      );
                    }).toList(),
                    pw.Divider(),
                    pw.SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    // Save and open the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Penjualan Global'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              // Fetch transactions from Firestore
              final snapshot =
                  await _firestore.collection('riwayatTransaksi').get();
              final transactions = snapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              // Export to PDF
              await _exportToPdf(transactions);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('riwayatTransaksi').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada data transaksi.'));
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction =
                  transactions[index].data() as Map<String, dynamic>;
              final timestamp = transaction['timestamp'] as Timestamp;
              final totalJual = transaction['totalJual'] as double;
              final jumlahPembayaran =
                  transaction['jumlahPembayaran'] as double;
              final kembalian = transaction['kembalian'] as double;
              final items = transaction['items'] as List<dynamic>;

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(
                    'Transaksi ${DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Column(
                            children: items.map((item) {
                              return ListTile(
                                title: Text(
                                    '${item['nama']} (x${item['quantity']})'),
                                subtitle: Text('Rp ${item['harga']} per item'),
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
          );
        },
      ),
    );
  }
}
