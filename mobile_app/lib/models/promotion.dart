class Promotion {
  final String id;
  final String sellerId;
  final String? listingId;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final bool isActive;
  final int priority;

  Promotion({
    required this.id,
    required this.sellerId,
    this.listingId,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.isActive = true,
    this.priority = 0,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      sellerId: json['seller_id'],
      listingId: json['listing_id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] ?? true,
      priority: json['priority'] ?? 0,
    );
  }
}
