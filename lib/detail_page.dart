import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'from_pembayaran.dart'; // Import halaman FromPembayaran

class DetailPage extends StatefulWidget {
  final String? kota_asal;
  final String? kota_tujuan;
  final String? berat;
  final String? kurir;
  final double totalJual; // Tambahkan totalJual untuk dikirim ke FromPembayaran

  const DetailPage({
    super.key,
    this.kota_asal,
    this.kota_tujuan,
    this.berat,
    this.kurir,
    required this.totalJual,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List listData = [];
  var strKey = '8ed728cc9b50af50c4d21ef57d844277';
  int? selectedIndex; // Menyimpan index yang dipilih oleh user

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future getData() async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://api.rajaongkir.com/starter/cost",
        ),
        body: {
          "key": strKey,
          "origin": widget.kota_asal,
          "destination": widget.kota_tujuan,
          "weight": widget.berat,
          "courier": widget.kurir
        },
      ).then((value) {
        var data = jsonDecode(value.body);
        setState(() {
          listData = data['rajaongkir']['results'][0]['costs'];
        });
      });
    } catch (e) {
      print(e);
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Detail Ongkos Kirim ${widget.kurir.toString().toUpperCase()}"),
      ),
      body: FutureBuilder(
        future: getData(),
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData && snapshot.data == "Loading") {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: listData.length,
                    itemBuilder: (_, index) {
                      return GestureDetector(
                        onTap: () => _onItemSelected(index),
                        child: Card(
                          margin: const EdgeInsets.all(10),
                          clipBehavior: Clip.antiAlias,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          color: selectedIndex == index
                              ? Colors.blue[50]
                              : Colors.white,
                          child: ListTile(
                            title: Text("${listData[index]['service']}"),
                            subtitle: Text("${listData[index]['description']}"),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Rp ${listData[index]['cost'][0]['value']}",
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.red),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                    "${listData[index]['cost'][0]['etd']} Days")
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (selectedIndex != null) // Tampilkan tombol jika ada pilihan
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "Anda memilih: ${listData[selectedIndex!]['service']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Ambil cost dari item yang dipilih
                            var selectedCost =
                                listData[selectedIndex!]['cost'][0]['value'];
                            // Navigasi ke FromPembayaran dengan totalJual dan cost
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FromPembayaran(
                                  totalJual: widget.totalJual + selectedCost,
                                  selectedItems: [], // Ganti dengan item yang dipilih jika ada
                                ),
                              ),
                            );
                          },
                          child: const Text("Pilih"),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}
