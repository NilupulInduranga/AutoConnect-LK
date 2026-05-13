import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final orderRepositoryProvider = Provider((ref) => OrderRepository(Supabase.instance.client));

class OrderRepository {
  final SupabaseClient _supabase;

  OrderRepository(this._supabase);

  Future<List<Order>> getOrders({required String userId, required bool isSeller}) async {
    final column = isSeller ? 'seller_id' : 'buyer_id';
    final response = await _supabase.from('orders').select().eq(column, userId).order('created_at', ascending: false);
    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<void> createOrder({required String sellerId, required double amount}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('orders').insert({
      'buyer_id': user.id,
      'seller_id': sellerId,
      'total_amount': amount,
      'status': 'pending',
      'escrow_status': 'held',
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase.from('orders').update({'status': status}).eq('id', orderId);
  }

  Future<void> placeOrder(List<dynamic> cartItems, String address, String city, String phone) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Group items by Seller ID
    final Map<String, List<dynamic>> ordersBySeller = {};
    for (var item in cartItems) {
      final sellerId = item.listing.sellerId;
      if (!ordersBySeller.containsKey(sellerId)) {
        ordersBySeller[sellerId] = [];
      }
      ordersBySeller[sellerId]!.add(item);
    }

    // 2. Create Order for each Seller
    for (var sellerId in ordersBySeller.keys) {
      final items = ordersBySeller[sellerId]!;
      final totalAmount = items.fold<double>(0, (sum, item) => sum + (item.listing.price * item.quantity));

      // Insert Order
      final orderResponse = await _supabase.from('orders').insert({
        'buyer_id': user.id,
        'seller_id': sellerId,
        'total_amount': totalAmount,
        'status': 'pending',
        'escrow_status': 'held',
        'shipping_address': address,
        'shipping_city': city,
        'buyer_phone': phone,
      }).select().single();

      final orderId = orderResponse['id'];

      // Insert Order Items
      final List<Map<String, dynamic>> orderItemsData = items.map((item) => {
        'order_id': orderId,
        'listing_id': item.listing.id,
        'quantity': item.quantity,
        'price': item.listing.price,
      }).toList();

      await _supabase.from('order_items').insert(orderItemsData);
    }
  }
}
