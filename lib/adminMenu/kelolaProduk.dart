// kelolaProdukPage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddProductDialog(context); // Tampilkan popup tambah barang
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('barang').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada data produk.'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final String productId = products[index].id; // Ambil ID dokumen
              final String imagePath =
                  'assets/${product['gambar']}'; // Path gambar dari assets

              return ListTile(
                leading: product['gambar'] != null
                    ? Image.asset(
                        imagePath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons
                              .image); // Placeholder jika gambar tidak ditemukan
                        },
                      )
                    : Icon(Icons.image), // Placeholder jika gambar tidak ada
                title: Text(product['nm_brg'] ?? 'Nama Barang Tidak Tersedia'),
                subtitle: Text('Harga: ${product['harga'] ?? 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showEditProductDialog(context, productId,
                            product); // Tampilkan popup edit barang
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _deleteProductDialog(
                            context, productId); // Tampilkan popup hapus barang
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(product: product),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _namaController = TextEditingController();
    final TextEditingController _hargaController = TextEditingController();
    final TextEditingController _hargaBeliController = TextEditingController();
    final TextEditingController _deskripsiController = TextEditingController();
    final TextEditingController _kodeBarangController = TextEditingController();
    final TextEditingController _satuanController = TextEditingController();
    final TextEditingController _stokController = TextEditingController();
    final TextEditingController _stokMinController = TextEditingController();
    final TextEditingController _gambarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Barang Baru'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(labelText: 'Nama Barang'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama barang tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _hargaController,
                    decoration: InputDecoration(labelText: 'Harga'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _hargaBeliController,
                    decoration: InputDecoration(labelText: 'Harga Beli'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga beli tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: InputDecoration(labelText: 'Deskripsi'),
                  ),
                  TextFormField(
                    controller: _kodeBarangController,
                    decoration: InputDecoration(labelText: 'Kode Barang'),
                  ),
                  TextFormField(
                    controller: _satuanController,
                    decoration: InputDecoration(labelText: 'Satuan'),
                  ),
                  TextFormField(
                    controller: _stokController,
                    decoration: InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _stokMinController,
                    decoration: InputDecoration(labelText: 'Stok Minimal'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _gambarController,
                    decoration:
                        InputDecoration(labelText: 'Gambar (nama file)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Menyimpan data ke Firestore
                  FirebaseFirestore.instance.collection('barang').add({
                    'nm_brg': _namaController.text,
                    'harga': double.tryParse(_hargaController.text) ?? 0,
                    'harga_beli':
                        double.tryParse(_hargaBeliController.text) ?? 0,
                    'deskripsi': _deskripsiController.text,
                    'kd_barang': _kodeBarangController.text,
                    'satuan': _satuanController.text,
                    'stok': int.tryParse(_stokController.text) ?? 0,
                    'stok_min': int.tryParse(_stokMinController.text) ?? 0,
                    'gambar': _gambarController.text,
                  }).then((_) {
                    Navigator.of(context)
                        .pop(); // Tutup dialog setelah berhasil
                  }).catchError((error) {
                    // Menangani error jika ada
                    print("Failed to add product: $error");
                  });
                }
              },
              child: Text('Simpan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog tanpa menyimpan
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

// Fungsi untuk menampilkan popup edit barang
  void _showEditProductDialog(
      BuildContext context, String productId, Map<String, dynamic> product) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _namaController =
        TextEditingController(text: product['nm_brg']);
    final TextEditingController _hargaController =
        TextEditingController(text: product['harga'].toString());
    final TextEditingController _hargaBeliController =
        TextEditingController(text: product['harga_beli'].toString());
    final TextEditingController _deskripsiController =
        TextEditingController(text: product['deskripsi']);
    final TextEditingController _kodeBarangController =
        TextEditingController(text: product['kd_barang']);
    final TextEditingController _satuanController =
        TextEditingController(text: product['satuan']);
    final TextEditingController _stokController =
        TextEditingController(text: product['stok'].toString());
    final TextEditingController _stokMinController =
        TextEditingController(text: product['stok_min'].toString());
    final TextEditingController _gambarController =
        TextEditingController(text: product['gambar']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Barang'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(labelText: 'Nama Barang'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama barang tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _hargaController,
                    decoration: InputDecoration(labelText: 'Harga'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _hargaBeliController,
                    decoration: InputDecoration(labelText: 'Harga Beli'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga beli tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: InputDecoration(labelText: 'Deskripsi'),
                  ),
                  TextFormField(
                    controller: _kodeBarangController,
                    decoration: InputDecoration(labelText: 'Kode Barang'),
                  ),
                  TextFormField(
                    controller: _satuanController,
                    decoration: InputDecoration(labelText: 'Satuan'),
                  ),
                  TextFormField(
                    controller: _stokController,
                    decoration: InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _stokMinController,
                    decoration: InputDecoration(labelText: 'Stok Minimal'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _gambarController,
                    decoration:
                        InputDecoration(labelText: 'Gambar (nama file)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Mengupdate data di Firestore
                  FirebaseFirestore.instance
                      .collection('barang')
                      .doc(productId)
                      .update({
                    'nm_brg': _namaController.text,
                    'harga': double.tryParse(_hargaController.text) ?? 0,
                    'harga_beli':
                        double.tryParse(_hargaBeliController.text) ?? 0,
                    'deskripsi': _deskripsiController.text,
                    'kd_barang': _kodeBarangController.text,
                    'satuan': _satuanController.text,
                    'stok': int.tryParse(_stokController.text) ?? 0,
                    'stok_min': int.tryParse(_stokMinController.text) ?? 0,
                    'gambar': _gambarController.text,
                  }).then((_) {
                    Navigator.of(context)
                        .pop(); // Tutup dialog setelah berhasil
                  }).catchError((error) {
                    // Menangani error jika ada
                    print("Failed to update product: $error");
                  });
                }
              },
              child: Text('Simpan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog tanpa menyimpan
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }
}

// Fungsi untuk menampilkan popup hapus barang
void _deleteProductDialog(BuildContext context, String productId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Hapus Barang'),
        content: Text('Apakah Anda yakin ingin menghapus barang ini?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog tanpa menghapus
            },
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Menghapus data dari Firestore
              FirebaseFirestore.instance
                  .collection('barang')
                  .doc(productId)
                  .delete()
                  .then((_) {
                Navigator.of(context).pop(); // Tutup dialog setelah berhasil
              }).catchError((error) {
                // Menangani error jika ada
                print("Failed to delete product: $error");
              });
            },
            child: Text('Hapus'),
          ),
        ],
      );
    },
  );
}

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  ProductDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    final String imagePath =
        'assets/${product['gambar']}'; // Path gambar dari assets

    return Scaffold(
      appBar: AppBar(
        title: Text(product['nm_brg'] ?? 'Detail Produk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['gambar'] != null)
              Image.asset(
                imagePath,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                      Icons.image); // Placeholder jika gambar tidak ditemukan
                },
              ),
            SizedBox(height: 16),
            Text('Deskripsi: ${product['deskripsi'] ?? 'N/A'}'),
            Text('Harga: ${product['harga'] ?? 'N/A'}'),
            Text('Harga Beli: ${product['harga_beli'] ?? 'N/A'}'),
            Text('Kode Barang: ${product['kd_barang'] ?? 'N/A'}'),
            Text('Satuan: ${product['satuan'] ?? 'N/A'}'),
            Text('Stok: ${product['stok'] ?? 'N/A'}'),
            Text('Stok Minimal: ${product['stok_min'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}
