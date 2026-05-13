import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/order_repository.dart';
import '../../../models/order.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';

// Simple provider to fetch orders
final ordersProvider = FutureProvider.family<List<Order>, bool>((ref, isSeller) async {
  final repository = ref.watch(orderRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser!.id;
  return repository.getOrders(userId: userId, isSeller: isSeller);
});

class OrderListScreen extends ConsumerWidget {
  final bool isSeller;
  const OrderListScreen({super.key, required this.isSeller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider(isSeller));

    return Scaffold(
      appBar: AppBar(title: Text(isSeller ? 'My Sales' : 'My Orders', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold))),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(child: Text('No orders yet', style: TextStyle(fontSize: 14.sp, color: Colors.grey)));
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  title: Text('Order #${order.id.substring(0, 8)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.h),
                      Text('Status: ${order.status.toUpperCase()}', style: TextStyle(fontSize: 12.sp)),
                      Text('Amount: LKR ${order.totalAmount}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500)),
                      if (order.escrowStatus == 'held')
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text('Funds in Escrow', style: TextStyle(color: AppTheme.accentColor, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14.r),
                  onTap: () {
                    // Navigate to details (Logic for buyer side could be added here)
                  },
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp))),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
