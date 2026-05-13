import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/seller_promotions_provider.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../../../models/promotion.dart';

class PromotionsListScreen extends ConsumerWidget {
  const PromotionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(sellerPromotionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Manage Ads', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
      body: promosAsync.when(
        data: (promos) {
          if (promos.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.0.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_outlined, size: 80.r, color: Colors.grey[400]),
                    SizedBox(height: 16.h),
                    Text('No ads yet', style: TextStyle(fontSize: 18.sp, color: Colors.grey)),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/seller/promotions/add'),
                      icon: Icon(Icons.add, color: Colors.white, size: 20.r),
                      label: Text('Create First Ad', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return _buildPromoCard(context, ref, promo);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/seller/promotions/add'),
        backgroundColor: AppTheme.accentColor,
        child: Icon(Icons.add, color: Colors.white, size: 24.r),
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context, WidgetRef ref, Promotion promo) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: promo.imageUrl,
                height: 150.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
              ),
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: promo.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    promo.isActive ? 'Active' : 'Paused',
                    style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promo.title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                if (promo.subtitle != null)
                  Text(promo.subtitle!, style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(promo.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 24.r),
                      onPressed: () {
                        ref.read(sellerPromotionsProvider.notifier).updatePromotion(
                          id: promo.id,
                          isActive: !promo.isActive,
                        );
                      },
                      tooltip: promo.isActive ? 'Pause' : 'Resume',
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 24.r),
                      onPressed: () => context.push('/seller/promotions/add', extra: promo),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red, size: 24.r),
                      onPressed: () => _confirmDelete(context, ref, promo.id),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Ad?', style: TextStyle(fontSize: 18.sp)),
        content: Text('This action cannot be undone.', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(fontSize: 14.sp))),
          TextButton(
            onPressed: () {
              ref.read(sellerPromotionsProvider.notifier).deletePromotion(id);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}
