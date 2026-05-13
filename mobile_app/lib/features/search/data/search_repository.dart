import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/models/listing.dart';

final searchRepositoryProvider = Provider((ref) => SearchRepository(Supabase.instance.client));

class SearchRepository {
  final SupabaseClient _supabase;

  SearchRepository(this._supabase);

  Future<List<Listing>> searchListings({String? query, String? category, String? make, String? model}) async {
    // Basic search implementation
    // For advanced search, we'd use text search capabilities of Postgres
    
    // Use the View for full details (including avatar and phone)
    var dbQuery = _supabase.from('listings_full')
      .select()
      .eq('status', 'approved');

    if (query != null && query.isNotEmpty) {
      // Simple text match
      dbQuery = dbQuery.ilike('title', '%$query%');
    }
    
    if (category != null && category.isNotEmpty) {
      dbQuery = dbQuery.eq('category', category);
    }
    
    if (make != null) {
      dbQuery = dbQuery.eq('vehicle_make', make);
    }

    if (model != null) {
      dbQuery = dbQuery.eq('vehicle_model', model);
    }

    final response = await dbQuery;
    return (response as List).map((e) => Listing.fromJson(e)).toList();
  }

  Future<Listing?> getListingById(String id) async {
    final response = await _supabase
        .from('listings_full')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return Listing.fromJson(response);
  }
}
