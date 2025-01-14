import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPenjualanPeriodikPage extends StatefulWidget {
  @override
  _LaporanPenjualanPeriodikPageState createState() =>
      _LaporanPenjualanPeriodikPageState();
}

class _LaporanPenjualanPeriodikPageState
    extends State<LaporanPenjualanPeriodikPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _filteredTransactions = [];

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _fetchTransactions() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih rentang tanggal terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('riwayatTransaksi')
          .where('timestamp', isGreaterThanOrEqualTo: _startDate)
          .where('timestamp', isLessThanOrEqualTo: _endDate)
          .get();

      setState(() {
        _filteredTransactions = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
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
                  'Laporan Penjualan Periodik',
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
        title: Text('Laporan Penjualan Periodik'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              await _fetchTransactions();
              await _exportToPdf(_filteredTransactions);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectStartDate(context),
                    child: Text(
                      _startDate == null
                          ? 'Pilih Tanggal Awal'
                          : 'Tanggal Awal: ${DateFormat('dd/MM/yyyy').format(_startDate!)}',
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectEndDate(context),
                    child: Text(
                      _endDate == null
                          ? 'Pilih Tanggal Akhir'
                          : 'Tanggal Akhir: ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTransactions,
              child: Text('Tampilkan Laporan'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? Center(child: Text('Tidak ada data transaksi.'))
                  : ListView.builder(
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _filteredTransactions[index];
                        final timestamp =
                            transaction['timestamp'] as Timestamp?;
                        final totalJual =
                            transaction['totalJual'] as double? ?? 0.0;
                        final jumlahPembayaran =
                            transaction['jumlahPembayaran'] as double? ?? 0.0;
                        final kembalian =
                            transaction['kembalian'] as double? ?? 0.0;
                        final items =
                            transaction['items'] as List<dynamic>? ?? [];

                        final transactionDate =
                            timestamp?.toDate() ?? DateTime.now();

                        return Card(
                          margin: EdgeInsets.all(8.0),
                          child: ExpansionTile(
                            title: Text(
                              'Transaksi ${DateFormat('dd/MM/yyyy HH:mm').format(transactionDate)}',
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
      ),
    );
  }
}
