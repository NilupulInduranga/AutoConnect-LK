import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/responsive_utils.dart';
import '../../chat/presentation/unread_count_badge.dart';
import '../data/seller_stats_provider.dart';

class SellerDashboard extends ConsumerWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sellerStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('AutoConnect Seller', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentColor, // Red for seller
        foregroundColor: Colors.white,
        actions: [
          UnreadCountBadge(
            child: IconButton(
              icon: Icon(Icons.mail_outline, size: 24.r),
              onPressed: () => context.push('/inbox'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 24.r),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Stats Row
            statsAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(child: _buildStatCard('Active Listings', stats['activeListings'].toString(), Icons.inventory, Colors.blue)),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildStatCard('Total Sales', 'LKR ${stats['totalSales'].toStringAsFixed(0)}', Icons.monetization_on, Colors.green)),
                ],
              ),
              loading: () => SizedBox(
                height: 100.h,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text('Error loading stats: $err', style: TextStyle(fontSize: 14.sp)),
            ),
            
            SizedBox(height: 24.h),
            
            Text('Quick Actions', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              children: [
                 _buildActionCard(context, 'Add New Listing', Icons.add_circle, Colors.orange, () {
                    context.push('/seller/add');
                 }),
                 _buildActionCard(context, 'Manage Inventory', Icons.list, Colors.blueGrey, () {
                    context.push('/seller/inventory');
                 }),
                 _buildActionCard(context, 'Orders', Icons.shopping_bag, Colors.purple, () {
                    context.push('/seller/orders'); 
                 }),
                 _buildActionCard(context, 'Settings', Icons.settings, Colors.grey, () {
                    context.push('/seller/settings');
                 }),
              ],
            ),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/seller/promotions');
        },
        label: Text('Manage Ads', style: TextStyle(fontSize: 14.sp)),
        icon: Icon(Icons.campaign, size: 24.r),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10.r, offset: Offset(0, 5.h))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30.r),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(title, style: TextStyle(fontSize: 11.sp, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             CircleAvatar(
               backgroundColor: color.withOpacity(0.1),
               radius: 30.r,
               child: Icon(icon, color: color, size: 30.r),
             ),
             SizedBox(height: 16.h),
             Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp), textAlign: TextAlign.center),
           ],
        ),
      ),
    );
  }
}
