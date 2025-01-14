import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LokasiPage extends StatelessWidget {
  final String mapsUrl = 'https://www.google.com/maps/place//@-6.9600642,110.4021509,21z?entry=ttu&g_ep=EgoyMDI0MTIxMS4wIKXMDSoASAFQAw%3D%3D';

  Future<void> _openMaps() async {
    if (!await launchUrl(Uri.parse(mapsUrl),
        mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $mapsUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lokasi Maps'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Kunjungi Kami:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Jl.Masjid Gg.Kerja 1',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openMaps,
              icon: Icon(Icons.map),
              label: Text('Buka di Google Maps'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
