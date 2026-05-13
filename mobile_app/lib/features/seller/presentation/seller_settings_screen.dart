import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../data/seller_profile_provider.dart';

class SellerSettingsScreen extends ConsumerWidget {
  const SellerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(sellerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
      body: profileAsync.when(
        data: (profile) {
           final name = profile?.fullName ?? 'Seller';
           final email = profile?.email ?? '';
           final avatarUrl = profile?.avatarUrl;
           
           final displayName = (profile?.shopName != null && profile!.shopName!.isNotEmpty) 
               ? profile.shopName! 
               : name;
           final subtitle = (profile?.shopName != null && profile!.shopName!.isNotEmpty)
               ? name
               : email;

           return ListView(
             children: [
               SizedBox(height: 30.h),
               CircleAvatar(
                 radius: 50.r,
                 backgroundColor: Colors.grey[300],
                 backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                 child: avatarUrl == null ? Icon(Icons.person, size: 50.r, color: Colors.grey) : null,
               ),
               SizedBox(height: 16.h),
               Center(child: Text(displayName, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold))),
               SizedBox(height: 4.h),
               Center(child: Text(subtitle, style: TextStyle(fontSize: 15.sp, color: Colors.grey))),
               SizedBox(height: 32.h),
               
               ListTile(
                 contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                 leading: Icon(Icons.store, size: 24.r),
                 title: Text('Shop Details', style: TextStyle(fontSize: 15.sp)),
                 subtitle: Text(profile?.shopName ?? 'Not set', style: TextStyle(fontSize: 13.sp)),
                 trailing: Icon(Icons.arrow_forward_ios, size: 14.r),
                 onTap: () {
                    context.push('/seller/settings/edit');
                 },
               ),
               const Divider(),
               ListTile(
                 contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                 leading: Icon(Icons.lock, size: 24.r),
                 title: Text('Change Password', style: TextStyle(fontSize: 15.sp)),
                 trailing: Icon(Icons.arrow_forward_ios, size: 14.r),
                 onTap: () {
                    context.push('/seller/settings/password');
                 },
               ),
               const Divider(),
               SizedBox(height: 40.h),
               
               Padding(
                 padding: EdgeInsets.symmetric(horizontal: 24.w),
                 child: SizedBox(
                   height: 50.h,
                   child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: Icon(Icons.logout, size: 20.r),
                    label: Text('LOG OUT', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                 ),
               ),
             ],
           );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp))),
      ),
    );
  }
}
