import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../../../models/listing.dart';
import '../../orders/data/cart_provider.dart';
import '../../chat/data/chat_repository.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final Listing listing;

  const ProductDetailsScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine image to show
    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. App Bar with Hero Image
          SliverAppBar(
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'report') {
                    // Show report dialog
                    final reasonController = TextEditingController();
                    final reportReason = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
                      title: Text('Report Listing', style: TextStyle(fontSize: 18.sp)),
                      content: TextField(
                        controller: reasonController,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: const InputDecoration(hintText: 'Reason for reporting...'),
                        maxLines: 3,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(fontSize: 14.sp))),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, reasonController.text), child: Text('Submit', style: TextStyle(fontSize: 14.sp))),
                      ],
                    ));
                    
                    if (reportReason != null && reportReason.isNotEmpty) {
                      try {
                        final myId = Supabase.instance.client.auth.currentUser?.id;
                        if (myId == null) throw Exception('Must be logged in');
                        await Supabase.instance.client.from('reported_listings').insert({
                          'listing_id': listing.id,
                          'buyer_id': myId,
                          'reason': reportReason,
                        });
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing reported. Thank you.', style: TextStyle(fontSize: 14.sp))));
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: TextStyle(fontSize: 14.sp))));
                      }
                    }
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                   PopupMenuItem<String>(
                    value: 'report',
                    child: Text('Report Listing', style: TextStyle(fontSize: 14.sp)),
                  ),
                ],
              ),
            ],
            expandedHeight: 300.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null 
                ? Hero(
                    tag: listing.id,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl, 
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Icon(Icons.error, size: 24.r),
                    ),
                  )
                : Container(color: Colors.grey[200], child: Icon(Icons.image, size: 80.r, color: Colors.grey)),
            ),
          ),

          // 2. Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Title & Price
                   Text(listing.title, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                   SizedBox(height: 8.h),
                   Text('LKR ${listing.price}', style: TextStyle(fontSize: 20.sp, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                   SizedBox(height: 16.h),
                   
                   // Tags
                   Wrap(
                     spacing: 8.w,
                     runSpacing: 8.h,
                     children: [
                       _buildTag(listing.condition, Colors.blue),
                       _buildTag(listing.category, Colors.orange),
                       _buildTag('${listing.vehicleMake} ${listing.vehicleModel}', Colors.grey),
                     ],
                   ),
                   SizedBox(height: 24.h),

                   // Seller Info Card
                   Container(
                     padding: EdgeInsets.all(12.r),
                     decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey[200]!)),
                     child: Row(
                       children: [
                          CircleAvatar(
                           radius: 20.r,
                           backgroundColor: Colors.blueAccent, 
                           backgroundImage: listing.sellerAvatarUrl != null ? CachedNetworkImageProvider(listing.sellerAvatarUrl!) : null,
                           child: listing.sellerAvatarUrl == null ? Icon(Icons.store, color: Colors.white, size: 20.r) : null
                         ),
                         SizedBox(width: 12.w),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(listing.shopName ?? 'Unknown Seller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
                               if (listing.sellerRating != null) 
                                 Padding(
                                   padding: EdgeInsets.only(top: 2.h, bottom: 2.h),
                                   child: Row(
                                     children: [
                                       Icon(Icons.star, color: Colors.amber, size: 14.r),
                                       SizedBox(width: 4.w),
                                       Text('${listing.sellerRating!.toStringAsFixed(1)} (${listing.sellerRatingCount ?? 0} reviews)', style: TextStyle(fontSize: 11.sp)),
                                     ]
                                   ),
                                 ),
                               Text('Verified Seller', style: TextStyle(color: Colors.green, fontSize: 11.sp)),
                             ],
                           ),
                         ),
                         // Chat Button
                         IconButton(
                           icon: Icon(Icons.message, color: Colors.blue, size: 22.r), 
                           onPressed: () async {
                               final myId = Supabase.instance.client.auth.currentUser?.id;
                               if (myId == listing.sellerId) {
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You cannot chat with yourself', style: TextStyle(fontSize: 14.sp))));
                                 return;
                               }
                               
                               try {
                                 final repo = ref.read(chatRepositoryProvider);
                                 final conversationId = await repo.getOrCreateConversation(listing.sellerId);
                                 
                                 if (context.mounted) {
                                   context.push('/chat', extra: {
                                     'id': conversationId,
                                     'name': listing.shopName ?? 'Seller',
                                     'other_uid': listing.sellerId,
                                   });
                                 }
                               } catch (e) {
                                 if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: TextStyle(fontSize: 14.sp))));
                               }
                           }
                         ),
                         // Phone Button
                         if (listing.sellerPhone != null && listing.sellerPhone!.isNotEmpty)
                           IconButton(
                             icon: Icon(Icons.phone, color: Colors.green, size: 22.r), 
                             onPressed: () async {
                               final Uri launchUri = Uri(
                                 scheme: 'tel',
                                 path: listing.sellerPhone,
                                );
                               if (await canLaunchUrl(launchUri)) {
                                 await launchUrl(launchUri);
                               } else {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch phone', style: TextStyle(fontSize: 14.sp))));
                               }
                             }
                           ),
                       ],
                     ),
                   ),
                   Align(
                     alignment: Alignment.centerRight,
                     child: TextButton.icon(
                       onPressed: () async {
                         // Show rate dialog
                         int rating = 5;
                         final reviewController = TextEditingController();
                         final rateSuccess = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
                           builder: (context, setState) {
                             return AlertDialog(
                               title: Text('Rate ${listing.shopName ?? 'Seller'}', style: TextStyle(fontSize: 18.sp)),
                               content: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: List.generate(5, (index) => IconButton(
                                       icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 28.r),
                                       onPressed: () => setState(() => rating = index + 1),
                                     )),
                                   ),
                                   SizedBox(height: 16.h),
                                   TextField(
                                     controller: reviewController,
                                     style: TextStyle(fontSize: 14.sp),
                                     decoration: InputDecoration(hintText: 'Write a review (optional)...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r))),
                                     maxLines: 3,
                                   ),
                                 ],
                               ),
                               actions: [
                                 TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(fontSize: 14.sp))),
                                 ElevatedButton(
                                   onPressed: () async {
                                     try {
                                       final myId = Supabase.instance.client.auth.currentUser?.id;
                                       if (myId == null) throw Exception('Must be logged in');
                                       if (myId == listing.sellerId) throw Exception('Cannot rate yourself');
                                       
                                       await Supabase.instance.client.from('seller_ratings').upsert({
                                         'buyer_id': myId,
                                         'seller_id': listing.sellerId,
                                         'rating': rating,
                                         'review': reviewController.text,
                                       }, onConflict: 'buyer_id,seller_id');
                                       if (ctx.mounted) Navigator.pop(ctx, true);
                                     } catch (e) {
                                       if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e', style: TextStyle(fontSize: 14.sp))));
                                     }
                                   },
                                   child: Text('Submit', style: TextStyle(fontSize: 14.sp))
                                 ),
                               ],
                             );
                           }
                         ));
                         if (rateSuccess == true && context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rating submitted. Thank you!', style: TextStyle(fontSize: 14.sp))));
                         }
                       },
                       icon: Icon(Icons.star_rate, size: 16.r),
                       label: Text('Rate Seller', style: TextStyle(fontSize: 12.sp)),
                     ),
                   ),
                   SizedBox(height: 24.h),

                   // Description
                   Text('Description', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                   SizedBox(height: 8.h),
                   Text(listing.description, style: TextStyle(fontSize: 15.sp, color: Colors.black87, height: 1.5)),
                   
                   SizedBox(height: 100.h), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        height: 80.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white, 
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10.r, offset: Offset(0, -5.h))
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                   height: 50.h,
                   child: OutlinedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addToCart(listing);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to Cart', style: TextStyle(fontSize: 14.sp))));
                    },
                    style: OutlinedButton.styleFrom(
                       padding: EdgeInsets.zero,
                       side: const BorderSide(color: AppTheme.primaryColor),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                    ),
                    child: Text('Add to Cart', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addToCart(listing);
                      context.push('/cart');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor, 
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                    ),
                    child: Text('Buy Now', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.sp)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    );
  }
}
