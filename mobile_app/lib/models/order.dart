class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final double totalAmount;
  final String status;
  final String escrowStatus;
  final String trackingId;
  final DateTime createdAt;
  final String? shippingAddress;
  final String? shippingCity;
  final String? buyerPhone;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.totalAmount,
    required this.status,
    required this.escrowStatus,
    required this.trackingId,
    required this.createdAt,
    this.shippingAddress,
    this.shippingCity,
    this.buyerPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      escrowStatus: json['escrow_status'] ?? 'held',
      trackingId: json['tracking_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      shippingAddress: json['shipping_address'],
      shippingCity: json['shipping_city'],
      buyerPhone: json['buyer_phone'],
    );
  }
}
