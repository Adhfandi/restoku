import 'package:flutter/material.dart';
import 'pilih_ongkir.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FromPembayaran extends StatefulWidget {
  final double totalJual;
  final List<Map<String, dynamic>> selectedItems;

  FromPembayaran({required this.totalJual, required this.selectedItems});

  @override
  _FromPembayaranState createState() => _FromPembayaranState();
}

class _FromPembayaranState extends State<FromPembayaran> {
  final TextEditingController _paymentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double _change = 0.0;

  void _calculateChange() {
    double payment = double.tryParse(_paymentController.text) ?? 0.0;
    setState(() {
      _change = payment - widget.totalJual;
    });
  }

  Future<void> _saveTransactionToFirebase() async {
    try {
      // Get current user ID
      final String? userId = _auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Create transaction data
      final transactionData = {
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'totalJual': widget.totalJual,
        'jumlahPembayaran': double.parse(_paymentController.text),
        'kembalian': _change,
        'items': widget.selectedItems
            .map((item) => {
                  'nama': item['nm_brg'],
                  'quantity': item['quantity'],
                  'harga': item['harga'],
                  'total': item['harga'] * item['quantity'],
                })
            .toList(),
      };

      // Save to Firestore
      await _firestore.collection('riwayatTransaksi').add(transactionData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Gagal menyimpan transaksi'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error saving transaction: $e');
    }
  }

  Future<void> _printReceipt() async {
    final doc = pw.Document();

    // Create PDF content
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'STRUK PEMBAYARAN',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Date and Time
              pw.Text(
                  'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Items
              pw.Text(
                'Detail Pembelian:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // List of items
              ...widget.selectedItems
                  .map((item) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${item['nm_brg']} (x${item['quantity']})'),
                          pw.Text(
                              'Harga: Rp ${item['harga']} x ${item['quantity']} = Rp ${(item['harga'] * item['quantity']).toStringAsFixed(2)}'),
                          pw.SizedBox(height: 5),
                        ],
                      ))
                  .toList(),

              pw.Divider(),
              pw.SizedBox(height: 10),

              // Payment details
              pw.Text(
                'Total Pembayaran:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Total: Rp ${widget.totalJual.toStringAsFixed(2)}'),
              pw.Text('Dibayar: Rp ${_paymentController.text}'),
              pw.Text('Kembalian: Rp ${_change.toStringAsFixed(2)}'),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Terima Kasih Atas Kunjungan Anda',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Print the document
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PilihOngkir(totalJual: widget.totalJual),
                  ),
                );
              },
              child: Text('Pilih Ongkir'),
            ),
            SizedBox(height: 16),
            Text(
              'Total Jual: Rp ${widget.totalJual.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Pembayaran',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _calculateChange(),
            ),
            SizedBox(height: 16),
            Text(
              'Kembalian: Rp ${_change.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Selesai'),
              onPressed: () async {
                // Save to Firebase first
                await _saveTransactionToFirebase();

                // Show transaction details dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Detail Pembayaran'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Total Jual: Rp ${widget.totalJual.toStringAsFixed(2)}'),
                            SizedBox(height: 8),
                            Text(
                                'Jumlah Pembayaran: Rp ${_paymentController.text}'),
                            SizedBox(height: 8),
                            Text('Kembalian: Rp ${_change.toStringAsFixed(2)}'),
                            SizedBox(height: 16),
                            Text(
                              'Item yang Dibeli:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Column(
                              children: widget.selectedItems.map((item) {
                                return ListTile(
                                  title: Text(
                                      '${item['nm_brg']} (x${item['quantity']})'),
                                  subtitle:
                                      Text('Rp ${item['harga']} per item'),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cetak'),
                          onPressed: _printReceipt,
                        ),
                        TextButton(
                          child: Text('Tutup'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
