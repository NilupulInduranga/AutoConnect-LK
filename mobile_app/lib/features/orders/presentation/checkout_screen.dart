import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../data/cart_provider.dart';
import '../data/order_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final cartItems = ref.read(cartProvider);
      
      await ref.read(orderRepositoryProvider).placeOrder(
        cartItems, 
        _addressController.text, 
        _cityController.text, 
        _phoneController.text
      );

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
          showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
              title: Icon(Icons.check_circle, color: Colors.green, size: 60.r),
              content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                   Text('Order Placed!', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                   SizedBox(height: 10.h),
                   Text('Thank you for your purchase. We will contact you shortly.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
              ],
              ),
              actions: [
              TextButton(
                  onPressed: () {
                  context.go('/home'); // Reset to home
                  },
                  child: Text('Back to Home', style: TextStyle(fontSize: 14.sp)),
              ),
              ],
          ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error placing order: $e', style: TextStyle(fontSize: 14.sp))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.read(cartProvider.notifier).totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Text('Shipping Details', style: Theme.of(context).textTheme.titleLarge),
               SizedBox(height: 20.h),
              
              TextFormField(
                controller: _addressController,
                style: TextStyle(fontSize: 14.sp),
                decoration: _inputDecoration('Address'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
               SizedBox(height: 15.h),
              
              TextFormField(
                controller: _cityController,
                style: TextStyle(fontSize: 14.sp),
                decoration: _inputDecoration('City'),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
               SizedBox(height: 15.h),
              
              TextFormField(
                controller: _phoneController,
                style: TextStyle(fontSize: 14.sp),
                decoration: _inputDecoration('Phone Number'),
                keyboardType: TextInputType.phone,
                 validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              
               SizedBox(height: 30.h),
               Text('Payment Method', style: Theme.of(context).textTheme.titleLarge),
               SizedBox(height: 15.h),
              
              Container(
                padding: EdgeInsets.all(15.r),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor),
                  borderRadius: BorderRadius.circular(10.r),
                  color: AppTheme.primaryColor.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                     Icon(Icons.local_shipping, color: AppTheme.primaryColor, size: 24.r),
                     SizedBox(width: 15.w),
                     Text('Cash On Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    const Spacer(),
                    Radio(value: true, groupValue: true, onChanged: (_) {}, activeColor: AppTheme.primaryColor),
                  ],
                ),
              ),

               SizedBox(height: 30.h),
                const Divider(),
                SizedBox(height: 10.h),
               
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text('Total to Pay:', style: TextStyle(fontSize: 18.sp)),
                   Text('LKR $total', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                 ],
               ),
               
                SizedBox(height: 30.h),
               
               SizedBox(
                 width: double.infinity,
                 height: 50.h,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _placeOrder,
                    child: _isLoading 
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirm Order'),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 14.sp),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
    );
  }
}
