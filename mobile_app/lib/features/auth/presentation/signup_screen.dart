import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'buyer'; // default

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _signup() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _fullNameController.text.trim(),
            _selectedRole,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text('Account Created', style: TextStyle(fontSize: 18.sp)),
              content: Text('Please check your email to confirm your account before logging in.', style: TextStyle(fontSize: 14.sp)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Close dialog
                    context.go('/login'); // Go to login
                  },
                  child: Text('OK', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          );
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString(), style: TextStyle(fontSize: 14.sp))),
          );
        },
        loading: () {},
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Custom Header
                Stack(
                  children: [
                    Container(
                      height: 200.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30.r),
                          bottomRight: Radius.circular(30.r),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add, size: 60.r, color: Colors.white),
                            SizedBox(height: 10.h),
                            Text(
                              'Join AutoConnect',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40.h,
                      left: 10.w,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.r),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 30.h),
                
                Padding(
                  padding: EdgeInsets.all(24.0.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name Input
                        _buildInput(
                          controller: _fullNameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        SizedBox(height: 16.h),
                        
                        // Email Input
                        _buildInput(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                        ),
                        SizedBox(height: 16.h),
                        
                        // Password Input
                        _buildInput(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outlined,
                          obscureText: true,
                        ),
                        SizedBox(height: 24.h),
                        
                        Text('I want to be a:', style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(height: 10.h),
                        
                        // Role Selection
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: Text('Buyer', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                                subtitle: Text('I want to find parts', style: TextStyle(fontSize: 14.sp)),
                                secondary: Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 24.r),
                                value: 'buyer',
                                groupValue: _selectedRole,
                                onChanged: (value) => setState(() => _selectedRole = value!),
                                activeColor: AppTheme.primaryColor,
                              ),
                              const Divider(),
                              RadioListTile<String>(
                                title: Text('Seller', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                                subtitle: Text('I want to sell parts', style: TextStyle(fontSize: 14.sp)),
                                secondary: Icon(Icons.store_outlined, color: AppTheme.accentColor, size: 24.r),
                                value: 'seller',
                                groupValue: _selectedRole,
                                onChanged: (value) => setState(() => _selectedRole = value!),
                                activeColor: AppTheme.accentColor,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 32.h),
                        
                        SizedBox(
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _signup,
                            child: isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.h,
                                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('CREATE ACCOUNT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontSize: 16.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14.sp),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22.r),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        ),
        validator: (value) => value!.isEmpty ? 'Enter $label' : null,
      ),
    );
  }
}
