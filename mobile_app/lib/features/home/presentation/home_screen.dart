import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../buyer/presentation/buyer_dashboard.dart';
import '../../seller/presentation/seller_dashboard.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/responsive_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
       final role = await ref.read(authRepositoryProvider).getUserRole(user.id);
       if (mounted) {
         setState(() {
           _role = role;
           _isLoading = false;
         });
       }
    } else {
       if (mounted) {
         setState(() {
           _isLoading = false;
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_role == 'seller') {
      return const SellerDashboard();
    }
    
    return const BuyerDashboard();
  }
}
