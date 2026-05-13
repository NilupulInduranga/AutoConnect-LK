import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/listing.dart';

class CartItem {
  final Listing listing;
  int quantity;

  CartItem({required this.listing, this.quantity = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Listing listing) {
    // Check if item already exists
    final index = state.indexWhere((item) => item.listing.id == listing.id);
    if (index != -1) {
      // Create a new list with updated quantity
      final newState = [...state];
      newState[index].quantity++;
      state = newState;
    } else {
      state = [...state, CartItem(listing: listing)];
    }
  }

  void removeFromCart(String listingId) {
    state = state.where((item) => item.listing.id != listingId).toList();
  }
  
  void updateQuantity(String listingId, int quantity) {
    if (quantity < 1) return;
     final index = state.indexWhere((item) => item.listing.id == listingId);
    if (index != -1) {
      final newState = [...state];
      newState[index].quantity = quantity;
      state = newState;
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + (item.listing.price * item.quantity));
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
