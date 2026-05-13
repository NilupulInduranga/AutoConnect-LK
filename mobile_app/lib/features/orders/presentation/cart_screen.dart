import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../data/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red, size: 24.r),
              onPressed: () {
                 ref.read(cartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Padding(
              padding: EdgeInsets.all(24.0.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Container(
                     padding: EdgeInsets.all(30.r),
                     decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                     child: Icon(Icons.shopping_cart_outlined, size: 80.r, color: Colors.grey),
                   ),
                   SizedBox(height: 30.h),
                   Text(
                     'Your cart is empty', 
                     style: Theme.of(context).textTheme.headlineSmall,
                     textAlign: TextAlign.center,
                   ),
                   SizedBox(height: 12.h),
                   Text(
                     'Looks like you haven\'t added anything to your cart yet.', 
                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                     textAlign: TextAlign.center,
                   ),
                   SizedBox(height: 40.h),
                   SizedBox(
                     width: double.infinity,
                     height: 50.h,
                     child: ElevatedButton(
                       onPressed: () => context.go('/home'),
                       child: const Text('Start Shopping'),
                     ),
                   ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.0.h),
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10.r, offset: Offset(0, 5.h))],
                    ),
                    child: Row(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: item.listing.images.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item.listing.images.first, 
                                  width: 80.w, 
                                  height: 80.w, 
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                                  errorWidget: (context, url, error) => Container(
                                    width: 80.w, 
                                    height: 80.w, 
                                    color: Colors.grey[200], 
                                    child: Icon(Icons.broken_image, color: Colors.grey, size: 24.r)
                                  ),
                                )
                              : Container(width: 80.w, height: 80.w, color: Colors.grey[200], child: Icon(Icons.image, size: 24.r)),
                        ),
                        SizedBox(width: 15.w),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.listing.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 4.h),
                              Text('LKR ${item.listing.price}', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                              SizedBox(height: 8.h),
                              // Qty Control
                              Row(
                                children: [
                                  _qtyButton(Icons.remove, () {
                                    if(item.quantity > 1) ref.read(cartProvider.notifier).updateQuantity(item.listing.id, item.quantity - 1);
                                  }),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    child: Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                  ),
                                  _qtyButton(Icons.add, () {
                                     ref.read(cartProvider.notifier).updateQuantity(item.listing.id, item.quantity + 1);
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 22.r),
                          onPressed: () => ref.read(cartProvider.notifier).removeFromCart(item.listing.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isNotEmpty 
        ? Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20.r, offset: Offset(0, -5.h))],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                    Text('LKR $total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp, color: AppTheme.primaryColor)),
                  ],
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () => context.push('/checkout'),
                    child: const Text('Proceed to Checkout'),
                  ),
                ),
              ],
            ),
          )
        : null,
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 16.r),
      ),
    );
  }
}
