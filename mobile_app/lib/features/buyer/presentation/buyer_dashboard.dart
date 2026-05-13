import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../search/presentation/search_controller.dart';
import '../../chat/presentation/unread_count_badge.dart';
import '../../buyer/data/promotions_provider.dart';
import '../../search/data/search_repository.dart';
import '../../../models/promotion.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';

class BuyerDashboard extends ConsumerStatefulWidget {
  const BuyerDashboard({super.key});

  @override
  ConsumerState<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends ConsumerState<BuyerDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _promoController = PageController();
  Timer? _promoTimer;
  int _currentPromoIndex = 0;

  @override
  void initState() {
    super.initState();
    _startPromoTimer();
  }

  void _startPromoTimer() {
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_promoController.hasClients) {
        _currentPromoIndex++;
        _promoController.animateToPage(
          _currentPromoIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _promoController.dispose();
    _promoTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCameraAndSearch() async {
    final result = await context.push<String>('/camera');
    if (result != null && result.isNotEmpty) {
      _searchController.text = result;
      ref.read(searchControllerProvider.notifier).search(query: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(searchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // 1. App Bar with Search
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 220.h,
            backgroundColor: AppTheme.primaryColor,
             flexibleSpace: FlexibleSpaceBar(
               background: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.3, 1.0],
                    ),
                  ),
                  padding: EdgeInsets.only(top: 80.h, left: 20.w, right: 20.w, bottom: 20.h),
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       Text(
                        'Find Your Vehicle Parts',
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                       Text(
                        'Serving the Sri Lankan Automotive Community',
                        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                      ),
                      const Spacer(),
                      // Search Bar
                      Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.r),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10.r, offset: Offset(0, 5.h))
                          ],
                        ),
                        child: TextField(
                           controller: _searchController,
                           style: TextStyle(fontSize: 14.sp),
                           decoration: InputDecoration(
                             hintText: 'Search parts (e.g. headlight)...',
                             prefixIcon: Icon(Icons.search, color: Colors.grey, size: 22.r),
                             suffixIcon: IconButton(
                                icon: Icon(Icons.camera_alt, color: AppTheme.accentColor, size: 22.r),
                                onPressed: _openCameraAndSearch,
                             ),
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                           ),
                           onChanged: (query) {
                              ref.read(searchControllerProvider.notifier).search(query: query);
                           },
                           onSubmitted: (query) {
                              ref.read(searchControllerProvider.notifier).search(query: query);
                           },
                         ),
                      ),
                    ],
                  ),
               ),
             ),
             title: Text('AutoLK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24.sp)),
             centerTitle: false,
            actions: [
              UnreadCountBadge(
                child: IconButton(
                  icon: Icon(Icons.mail_outline, color: Colors.white, size: 24.r),
                  onPressed: () => context.push('/inbox'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white, size: 24.r),
                onPressed: () => context.push('/cart'),
              ),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white, size: 24.r),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),

           // 1.5 Banners (Dynamic)
           SliverToBoxAdapter(
             child: ref.watch(promotionsProvider).when(
               data: (promos) {
                 if (promos.isEmpty) return const SizedBox.shrink();
                 return Container(
                   height: 160.h,
                   margin: EdgeInsets.only(top: 20.h),
                   child: PageView.builder(
                     controller: _promoController,
                     onPageChanged: (index) => _currentPromoIndex = index,
                     itemBuilder: (context, index) {
                       final promo = promos[index % promos.length];
                       return _buildBanner(promo);
                     },
                   ),
                 );
               },
               loading: () => Container(
                 height: 160.h, 
                 margin: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                 decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15.r)),
                 child: const Center(child: CircularProgressIndicator()),
               ),
                          error: (err, stack) => const SizedBox.shrink(),
             ),
           ),
           // 1.6 Sri Lankan Tip Card

           SliverToBoxAdapter(
             child: Container(
               margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
               padding: EdgeInsets.all(16.r),
               decoration: BoxDecoration(
                 color: AppTheme.secondaryColor.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(15.r),
                 border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
               ),
               child: Row(
                 children: [
                   Icon(Icons.lightbulb_outline, color: AppTheme.secondaryColor, size: 30.r),
                   SizedBox(width: 15.w),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Pro Tip for SL Drivers', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor, fontSize: 14.sp)),
                         Text('Always check your brake pads before the monsoon season starts in May!', style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
                       ],
                     ),
                   ),
                 ],
               ),
             ),
           ),

          // 2. Categories
           SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categories', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 90.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryItem(ref, Icons.build, 'Engine', Colors.orange),
                        _buildCategoryItem(ref, Icons.electrical_services, 'Electrical', Colors.blue),
                         _buildCategoryItem(ref, Icons.directions_car, 'Body', Colors.red),
                        _buildCategoryItem(ref, Icons.settings, 'Suspension', Colors.grey),
                        _buildCategoryItem(ref, Icons.music_note, 'Audio', Colors.purple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. Listings Grid
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return SliverToBoxAdapter(child: Center(child: Text('No listings found', style: TextStyle(color: Colors.grey, fontSize: 14.sp))));
                }
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 10.h,
                    crossAxisSpacing: 10.w,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = listings[index];
                       return InkWell(
                         onTap: () => context.push('/product', extra: listing),
                         child: Container(
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(15.r),
                             boxShadow: [
                               BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5.r, spreadRadius: 1.r),
                             ],
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               // Image
                               Expanded(
                                 child: Hero(
                                   tag: listing.id,
                                   child: Container(
                                     decoration: BoxDecoration(
                                       borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                                     ),
                                     clipBehavior: Clip.antiAlias,
                                     child: listing.images.isNotEmpty
                                         ? CachedNetworkImage(
                                             imageUrl: listing.images.first,
                                             fit: BoxFit.cover,
                                             width: double.infinity,
                                             placeholder: (context, url) => Container(color: Colors.grey[200]),
                                             errorWidget: (context, url, error) => Icon(Icons.error, size: 24.r),
                                           )
                                         : Container(
                                             color: Colors.grey[200],
                                             child: Center(child: Icon(Icons.image, color: Colors.grey, size: 30.r)),
                                           ),
                                   ),
                                 ),
                               ),
                               // Info
                               Padding(
                                 padding: EdgeInsets.all(10.0.r),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                     SizedBox(height: 4.h),
                                      Text('LKR ${listing.price}', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                                      SizedBox(height: 4.h),
                                      Row(children: [
                                        Icon(Icons.star, size: 12.r, color: Colors.amber),
                                        Text(' 4.5', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                                      ]),
                                   ],
                                 ),
                                ),
                             ],
                           ),
                         ),
                       );
                    },
                    childCount: listings.length,
                  ),
                );
              },
              error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp)))),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            ),
          ),
          
          SliverPadding(padding: EdgeInsets.only(bottom: 20.h)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(WidgetRef ref, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => ref.read(searchControllerProvider.notifier).selectCategory(label),
      child: Container(
        width: 70.w,
        margin: EdgeInsets.only(right: 15.w),
        child: Column(
          children: [
            Container(
              height: 50.w,
              width: 50.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15.r),
              ),
               child: Icon(icon, color: color, size: 24.r),
            ),
            SizedBox(height: 5.h),
            Text(
              label, 
              style: TextStyle(fontSize: 11.sp), 
              textAlign: TextAlign.center, 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(Promotion promo) {
    return GestureDetector(
      onTap: () async {
        if (promo.listingId != null) {
          try {
            final repository = ref.read(searchRepositoryProvider);
            final listing = await repository.getListingById(promo.listingId!);
            if (listing != null && mounted) {
              context.push('/product', extra: listing);
            }
          } catch (e) {
            // Silently fail
          }
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10.r, offset: Offset(0, 4.h)),
          ],
          image: DecorationImage(
            image: CachedNetworkImageProvider(promo.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(promo.title, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
              if (promo.subtitle != null)
                Text(promo.subtitle!, style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
            ],
          ),
        ),
      ),
    );
  }
}
