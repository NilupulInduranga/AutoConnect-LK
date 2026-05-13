import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sellerStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return {'activeListings': 0, 'totalSales': 0.0};
  }

  // 1. Get Active Listings Count
  final activeListings = await supabase
      .from('listings')
      .count(CountOption.exact)
      .eq('seller_id', user.id)
      .eq('status', 'approved');

  // 2. Get Total Sales
  // We need to sum 'total_amount' of orders where seller_id = user.id and status != 'cancelled'
  // Supabase doesn't have a direct SUM aggregate in standard client easily without RPC/View or extensive fetching.
  // For MVP, if orders are few, we can fetch all and sum. 
  // Better approach: Create a view or RPC. But allow fetch for now.
  
  final ordersResponse = await supabase
      .from('orders')
      .select('total_amount')
      .eq('seller_id', user.id)
      .neq('status', 'cancelled');
      
  double totalSales = 0.0;
  for (var order in ordersResponse) {
    totalSales += (order['total_amount'] as num).toDouble();
  }

  return {
    'activeListings': activeListings,
    'totalSales': totalSales,
  };
});
