import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';

// Provider to fetch order items
final orderItemsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, orderId) async {
  final response = await Supabase.instance.client
      .from('order_items')
      .select('*, listings(*)')
      .eq('order_id', orderId);
  return List<Map<String, dynamic>>.from(response);
});

class SellerOrderDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> order;

  const SellerOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(orderItemsProvider(order['id']));

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order['id'].toString().substring(0, 8)}', 
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    order['status'].toString().toUpperCase(),
                    style: TextStyle(color: _getStatusColor(order['status']), fontWeight: FontWeight.bold, fontSize: 11.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Buyer Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              child: Padding(
                padding: EdgeInsets.all(16.0.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buyer Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    const Divider(),
                    SizedBox(height: 10.h),
                    _detailRow(Icons.person, 'Name', order['profiles'] != null ? order['profiles']['full_name'] : 'Unknown'),
                    SizedBox(height: 10.h),
                    _detailRow(Icons.phone, 'Phone', order['buyer_phone'] ?? 'Not provided'),
                    SizedBox(height: 10.h),
                    _detailRow(Icons.location_on, 'Address', order['shipping_address'] ?? 'Not provided'),
                    SizedBox(height: 10.h),
                    _detailRow(Icons.location_city, 'City', order['shipping_city'] ?? 'Not provided'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            Text('Ordered Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
            SizedBox(height: 10.h),

            // Items List
            itemsAsync.when(
              data: (items) => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final listing = item['listings'];
                  return Card(
                    margin: EdgeInsets.only(bottom: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      leading: listing != null && listing['images'] != null && (listing['images'] as List).isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: CachedNetworkImage(
                                imageUrl: listing['images'][0],
                                width: 50.w,
                                height: 50.w,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.image, size: 24.r),
                      title: Text(listing != null ? listing['title'] : 'Unknown Item', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      subtitle: Text('Qty: ${item['quantity']} x LKR ${item['price']}', style: TextStyle(fontSize: 12.sp)),
                      trailing: Text('LKR ${item['quantity'] * item['price']}', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading items: $err', style: TextStyle(fontSize: 14.sp)),
            ),

            SizedBox(height: 20.h),
            // Total
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: LKR ${order['total_amount']}',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.r, color: Colors.grey),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
              Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'shipped': return Colors.indigo;
      case 'delivered': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
