import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';

// Provider to fetch seller orders
final sellerOrdersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return [];

  final response = await supabase
      .from('orders')
      .select('*, profiles:buyer_id(full_name, email)') // Join buyer profile
      .eq('seller_id', user.id)
      .order('created_at', ascending: false);
      
  return List<Map<String, dynamic>>.from(response);
});

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(child: Text('No orders yet.', style: TextStyle(fontSize: 14.sp, color: Colors.grey)));
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: Padding(
                  padding: EdgeInsets.all(16.0.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${order['id'].toString().substring(0, 8)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                          _buildStatusChip(order['status'] ?? 'pending'),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                             context.push('/seller/order-details', extra: order);
                          },
                          icon: Icon(Icons.visibility, size: 18.r),
                          label: Text('View Details', style: TextStyle(fontSize: 13.sp)),
                        ),
                      ),
                      const Divider(),
                      Text('Buyer: ${order['profiles'] != null ? order['profiles']['full_name'] : 'Unknown User'}', style: TextStyle(fontSize: 13.sp)),
                      Text('Total: LKR ${order['total_amount']}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                      SizedBox(height: 10.h),
                      if (order['status'] == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40.h,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Accept Order
                                    await Supabase.instance.client
                                        .from('orders')
                                        .update({'status': 'accepted'})
                                        .eq('id', order['id']);
                                    ref.refresh(sellerOrdersProvider);
                                  }, 
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                                  child: Text('Accept', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: SizedBox(
                                height: 40.h,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Reject Order
                                    await Supabase.instance.client
                                        .from('orders')
                                        .update({'status': 'rejected'})
                                        .eq('id', order['id']);
                                    ref.refresh(sellerOrdersProvider);
                                  }, 
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                                  child: Text('Reject', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                       if (order['status'] == 'accepted')
                         SizedBox(
                           width: double.infinity,
                           height: 40.h,
                           child: ElevatedButton(
                            onPressed: () async {
                              // Mark as Shipped
                              await Supabase.instance.client
                                  .from('orders')
                                  .update({'status': 'shipped'})
                                  .eq('id', order['id']);
                              ref.refresh(sellerOrdersProvider);
                            }, 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                            child: Text('Mark as Shipped', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          ),
                         ),
                       if (order['status'] == 'shipped')
                         SizedBox(
                           width: double.infinity,
                           height: 40.h,
                           child: ElevatedButton(
                            onPressed: () async {
                              // Mark as Delivered
                              await Supabase.instance.client
                                  .from('orders')
                                  .update({'status': 'delivered'})
                                  .eq('id', order['id']);
                              ref.refresh(sellerOrdersProvider);
                            }, 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                            child: Text('Mark as Delivered', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          ),
                         ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp))),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'accepted': color = Colors.blue; break;
      case 'shipped': color = Colors.indigo; break;
      case 'delivered': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: color)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
    );
  }
}
