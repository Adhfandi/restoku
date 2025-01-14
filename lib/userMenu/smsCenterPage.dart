import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SMSCenterPage extends StatelessWidget {
  final String phoneNumber = '081548279798';

  Future<void> _openWhatsApp() async {
    // Format nomor telepon (hilangkan karakter selain angka dan tambahkan kode negara)
    String whatsappUrl =
        "https://wa.me/62${phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}";

    if (!await launchUrl(Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SMS Center'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'WhatsApp Number:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              phoneNumber,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openWhatsApp,
              child: Text('Open WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}
