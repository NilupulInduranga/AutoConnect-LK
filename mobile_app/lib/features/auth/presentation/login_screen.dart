import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';
import '../data/auth_repository.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password', style: TextStyle(fontSize: 18.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to receive a password reset link.', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 16.h),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(fontSize: 14.sp),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                await ref.read(authControllerProvider.notifier).resetPassword(email);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset link sent! Check your email.', style: TextStyle(fontSize: 14.sp))),
                  );
                }
              }
            },
            child: Text('Send Link', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next is AsyncData) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          context.go('/home');
        }
      }
      next.when(
        data: (data) {},
        error: (error, stack) {
          String message = error.toString();
          if (message.contains('over_email_send_rate_limit')) {
            message = 'Too many requests. Please wait a few minutes and try again.';
          } else if (message.contains('AuthApiException')) {
            message = message.split(':').last.trim().replaceAll(')', '');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message, style: TextStyle(fontSize: 14.sp))),
          );
        },
        loading: () {},
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Custom Header with Curve
                Stack(
                  children: [
                    Container(
                      height: 250.h,
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
                            Icon(Icons.directions_car, size: 80.r, color: Colors.white),
                            SizedBox(height: 10.h),
                            Text(
                              'Ayubowan! Welcome',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28.sp,
                                  ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              'Sri Lanka\'s Premier Auto Parts Marketplace',
                              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 40.h),
                
                Padding(
                  padding: EdgeInsets.all(24.0.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Continue to AutoLK',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                fontSize: 22.sp,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30.h),
                        
                        // Email Input
                        Container(
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
                            controller: _emailController,
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(fontSize: 14.sp),
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryColor, size: 22.r),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                            ),
                            validator: (value) => value!.isEmpty ? 'Enter email' : null,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        
                        // Password Input
                        Container(
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
                            controller: _passwordController,
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(fontSize: 14.sp),
                              prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.primaryColor, size: 22.r),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                            ),
                            obscureText: true,
                            validator: (value) => value!.isEmpty ? 'Enter password' : null,
                          ),
                        ),
                        
                        SizedBox(height: 20.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text('Forgot Password?', style: TextStyle(fontSize: 14.sp)),
                          ),
                        ),
                        
                        SizedBox(height: 20.h),
                        
                        SizedBox(
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 5,
                            ),
                            child: isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.h,
                                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text('LOGIN', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        
                        SizedBox(height: 30.h),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?", style: TextStyle(fontSize: 14.sp)),
                            TextButton(
                              onPressed: () {
                                 context.push('/signup');
                              },
                              child: Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                            ),
                          ],
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
}
