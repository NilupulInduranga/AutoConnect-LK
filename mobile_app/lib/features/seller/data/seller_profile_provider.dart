import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

// Model for Seller Profile interacting with UI
class SellerProfile {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? shopName;
  final String? shopAddress;

  SellerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.shopName,
    this.shopAddress,
  });

  factory SellerProfile.fromMap(Map<String, dynamic> map) {
    // map contains joined data from profiles and sellers
    // profiles: id, full_name, email, avatar_url
    // sellers: shop_name, shop_address
    
    // Note: When joining, Supabase might return nested objects if not flattened, 
    // or if we fetch separately. 
    // Let's assume we merge manually or fetch smartly.
    
    return SellerProfile(
      id: map['id'],
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatar_url'],
      shopName: map['shop_name'],
      shopAddress: map['shop_address'],
    );
  }
}

final sellerProfileProvider = FutureProvider.autoDispose<SellerProfile?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return null;

  // 1. Fetch Profile
  final profileResponse = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  // 2. Fetch Seller Details
  final sellerResponse = await supabase
      .from('sellers')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  return SellerProfile(
    id: user.id,
    fullName: profileResponse['full_name'] ?? '',
    email: user.email ?? '',
    avatarUrl: profileResponse['avatar_url'],
    shopName: sellerResponse?['shop_name'],
    shopAddress: sellerResponse?['shop_address'],
  );
});

// Controller for updates
class SellerProfileController extends StateNotifier<AsyncValue<void>> {
  SellerProfileController() : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    required String fullName,
    String? shopName,
    String? shopAddress,
    XFile? newAvatarFile, // Changed from File to XFile
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? avatarUrl;

      // 1. Upload Avatar if provided
      if (newAvatarFile != null) {
        final fileExt = newAvatarFile.name.split('.').last;
        final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        // Use uploadBinary for web compatibility (and works on mobile too)
        final bytes = await newAvatarFile.readAsBytes();
        await supabase.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
        
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // 2. Update Profiles Table
      final profileUpdates = {
        'full_name': fullName,
        // Append timestamp to bust cache in case URL is same (though we use unique filenames now)
        if (avatarUrl != null) 'avatar_url': '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
        'updated_at': DateTime.now().toIso8601String(),
      };
      await supabase.from('profiles').update(profileUpdates).eq('id', user.id);

      // 3. Update Sellers Table
      final sellerUpdates = {
        'shop_name': shopName,
        'shop_address': shopAddress,
      };
      
      // Check if seller record exists
      final sellerExists = await supabase.from('sellers').select().eq('id', user.id).maybeSingle();
      
      if (sellerExists != null) {
         await supabase.from('sellers').update(sellerUpdates).eq('id', user.id);
      } else {
         await supabase.from('sellers').insert({'id': user.id, ...sellerUpdates});
      }
    });
  }
}

final sellerProfileControllerProvider = StateNotifierProvider<SellerProfileController, AsyncValue<void>>((ref) {
  return SellerProfileController();
});
