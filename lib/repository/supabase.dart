import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final response = await _supabaseClient.from('barang').select('nama_barang');
    return response;
  }
}
