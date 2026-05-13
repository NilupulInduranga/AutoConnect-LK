import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/promotion.dart';

final sellerPromotionsProvider = StateNotifierProvider<SellerPromotionsNotifier, AsyncValue<List<Promotion>>>((ref) {
  return SellerPromotionsNotifier(Supabase.instance.client);
});

class SellerPromotionsNotifier extends StateNotifier<AsyncValue<List<Promotion>>> {
  final SupabaseClient _supabase;
  
  SellerPromotionsNotifier(this._supabase) : super(const AsyncValue.loading()) {
    fetchPromotions();
  }

  Future<void> fetchPromotions() async {
    try {
      state = const AsyncValue.loading();
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final data = await _supabase
          .from('promotions')
          .select()
          .eq('seller_id', userId) // seller_id is same as user_id in our schema
          .order('created_at', ascending: false);
          
      final promos = (data as List).map((json) => Promotion.fromJson(json)).toList();
      state = AsyncValue.data(promos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> uploadImage(dynamic imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final fileExt = 'jpg'; // Assuming jpg for picker
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'promotions/$userId/$fileName';

      await _supabase.storage.from('listings').uploadBinary(
        filePath,
        imageFile,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      return _supabase.storage.from('listings').getPublicUrl(filePath);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPromotion({
    required String title,
    String? subtitle,
    required String imageUrl,
    String? listingId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('promotions').insert({
        'seller_id': userId,
        'listing_id': listingId,
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
      });
      await fetchPromotions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePromotion({
    required String id,
    String? title,
    String? subtitle,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (subtitle != null) updates['subtitle'] = subtitle;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase.from('promotions').update(updates).eq('id', id);
      await fetchPromotions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePromotion(String id) async {
    try {
      await _supabase.from('promotions').delete().eq('id', id);
      await fetchPromotions();
    } catch (e) {
      rethrow;
    }
  }
}
