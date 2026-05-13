import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/orders/presentation/cart_screen.dart';
import '../features/orders/presentation/checkout_screen.dart';
import '../features/camera/presentation/magic_camera_screen.dart';
import '../features/seller/presentation/add_listing_screen.dart';
import '../features/seller/presentation/manage_inventory_screen.dart';
import '../features/seller/presentation/seller_orders_screen.dart';
import '../features/seller/presentation/seller_order_details_screen.dart';
import '../features/seller/presentation/seller_settings_screen.dart';
import '../features/seller/presentation/edit_seller_profile_screen.dart';
import '../features/seller/presentation/change_password_screen.dart';
import '../features/seller/presentation/promotions_list_screen.dart';
import '../features/seller/presentation/add_promotion_screen.dart';
import '../features/buyer/presentation/product_details_screen.dart';
import '../features/chat/presentation/conversation_list_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../models/listing.dart';
import '../models/promotion.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStream = Supabase.instance.client.auth.onAuthStateChange;
  
  return GoRouter(
    initialLocation: Supabase.instance.client.auth.currentSession != null ? '/home' : '/login',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/signup';

      if (session == null && !isLoggingIn) return '/login';
      if (session != null && isLoggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const MagicCameraScreen(),
      ),
      GoRoute(
        path: '/seller/add',
        builder: (context, state) {
          final listing = state.extra as Listing?;
          return AddListingScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/seller/inventory',
        builder: (context, state) => const ManageInventoryScreen(),
      ),
      GoRoute(
        path: '/product', // Passing object via extra for simplicity, generally ID is better for deep links but this is faster for now
        builder: (context, state) {
           final listing = state.extra as Listing;
           return ProductDetailsScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/seller/orders',
        builder: (context, state) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/seller/order-details',
        builder: (context, state) {
          final order = state.extra as Map<String, dynamic>;
          return SellerOrderDetailsScreen(order: order);
        },
      ),
      GoRoute(
        path: '/seller/settings',
        builder: (context, state) => const SellerSettingsScreen(),
      ),
      GoRoute(
        path: '/seller/settings/edit',
        builder: (context, state) => const EditSellerProfileScreen(),
      ),
      GoRoute(
        path: '/seller/settings/password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const ConversationListScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
           final extra = state.extra as Map<String, dynamic>;
           return ChatScreen(
             conversationId: extra['id'], 
             otherUserName: extra['name'],
             otherUserId: extra['other_uid'],
           );
        },
      ),
      GoRoute(
        path: '/seller/promotions',
        builder: (context, state) => const PromotionsListScreen(),
      ),
      GoRoute(
        path: '/seller/promotions/add',
        builder: (context, state) {
          final promo = state.extra as Promotion?;
          return AddPromotionScreen(promotion: promo);
        },
      ),
    ],
  );
});

// Helper class for converting Stream to Listenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
