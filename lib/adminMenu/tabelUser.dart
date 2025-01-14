import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TabelUserPage extends StatefulWidget {
  @override
  _TabelUserPageState createState() => _TabelUserPageState();
}

class _TabelUserPageState extends State<TabelUserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tabel User'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final email = user['email'];
              final name = user['name'];
              final rool = user['rool'];

              return ListTile(
                title: Text(name),
                subtitle: Text(email),
                trailing: DropdownButton<String>(
                  value: rool,
                  items: <String>['admin', 'users']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _firestore.collection('users').doc(user.id).update({
                        'rool': newValue,
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
