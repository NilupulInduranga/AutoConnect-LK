class Listing {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String vehicleMake;
  final String vehicleModel;
  final String category; // Added
  final String condition;
  final double price;
  final List<String> images;
  final String status;
  final String? shopName;
  final String? sellerAvatarUrl; 
  final String? sellerPhone; // Added
  final double? sellerRating; // Added
  final int? sellerRatingCount; // Added

  Listing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.category,
    required this.condition,
    required this.price,
    required this.images,
    required this.status,
    this.shopName,
    this.sellerAvatarUrl,
    this.sellerPhone,
    this.sellerRating,
    this.sellerRatingCount,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    // Handle nested response from Supabase joins
    // listings -> sellers -> profiles
    String? avatar;
    if (json['sellers'] != null && json['sellers']['profiles'] != null) {
       avatar = json['sellers']['profiles']['avatar_url'];
    }
    
    // For view-based fetching, fields are flat
    // but for join-based (if we revert), it's nested
    // The view 'listings_full' returns 'seller_avatar_url', 'seller_phone'
    // Let's handle both cases for robustness
    
    final viewAvatar = json['seller_avatar_url'];
    final viewPhone = json['seller_phone'];
    final viewShopName = json['shop_name'];
    
    final joinShopName = json['sellers'] != null ? json['sellers']['shop_name'] : null;
    final joinRating = json['sellers'] != null ? (json['sellers']['rating'] as num?)?.toDouble() : null;
    final joinRatingCount = json['sellers'] != null ? json['sellers']['rating_count'] as int? : null;

    return Listing(
      id: json['id'] ?? (json['listing_id'] ?? ''), // View uses listing_id, table uses id
      sellerId: json['seller_id'] ?? '',
      title: json['title'] ?? 'Untitled Listing',
      description: json['description'] ?? '',
      vehicleMake: json['vehicle_make'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      condition: json['condition'] ?? 'Used',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? 'pending',
      shopName: viewShopName ?? joinShopName,
      sellerAvatarUrl: viewAvatar ?? avatar,
      sellerPhone: viewPhone,
      sellerRating: joinRating,
      sellerRatingCount: joinRatingCount,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'category': category,
      'condition': condition,
      'price': price,
      'images': images,
      'status': status,
    };
  }
}
