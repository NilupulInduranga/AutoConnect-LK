import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../../../models/listing.dart';

// Helper provider to fetch MY listings
final myListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('listings')
      .select()
      .eq('seller_id', user.id)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Listing.fromJson(json)).toList();
});

class ManageInventoryScreen extends ConsumerWidget {
  const ManageInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Manage Inventory', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)), backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.0.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 80.r, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text('No items in inventory', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () => context.push('/seller/add'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                       child: Text('Add First Item', style: TextStyle(fontSize: 14.sp)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(8.r),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  leading: Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                      image: listing.images.isNotEmpty ? DecorationImage(image: NetworkImage(listing.images.first), fit: BoxFit.cover) : null,
                    ),
                    child: listing.images.isEmpty ? Icon(Icons.image, size: 20.r) : null,
                  ),
                  title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  subtitle: Text('${listing.vehicleMake} ${listing.vehicleModel} • LKR ${listing.price}', style: TextStyle(fontSize: 12.sp)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       // Edit Button
                       IconButton(
                         icon: Icon(Icons.edit, color: Colors.blue, size: 20.r), 
                         onPressed: () {
                           context.push('/seller/add', extra: listing);
                         },
                       ),
                       // Delete Button
                       IconButton(
                         icon: Icon(Icons.delete, color: Colors.red, size: 20.r), 
                         onPressed: () => _confirmDelete(context, ref, listing),
                       ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp))),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        mini: false,
        child: Icon(Icons.add, color: Colors.white, size: 24.r),
        onPressed: () => context.push('/seller/add'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Listing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Item', style: TextStyle(fontSize: 18.sp)),
        content: Text('Are you sure you want to delete this listing? This action cannot be undone.', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(fontSize: 14.sp))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14.sp))),
        ],
      ),
    );

    if (confirmed == true) {
      if (listing.images.isNotEmpty) {
        try {
          final List<String> pathsToDelete = [];
          for (final url in listing.images) {
             final uri = Uri.parse(url);
             final segments = uri.pathSegments;
             final bucketIndex = segments.indexOf('listings'); 
             if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
               final path = segments.sublist(bucketIndex + 1).join('/');
               pathsToDelete.add(path);
             }
          }
          if (pathsToDelete.isNotEmpty) {
            await Supabase.instance.client.storage.from('listings').remove(pathsToDelete);
          }
        } catch (e) {
          print('Error deleting images: $e');
        }
      }

      await Supabase.instance.client.from('listings').delete().eq('id', listing.id);
      
      ref.refresh(myListingsProvider); 
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing deleted', style: TextStyle(fontSize: 14.sp))));
      }
    }
  }
}
