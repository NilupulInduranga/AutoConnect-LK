import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://owfrgqkpqbgoxmwrtdkv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93ZnJncWtwcWJnb3htd3J0ZGt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNjcwMTAsImV4cCI6MjA4Njk0MzAxMH0.mlB_s-GFvcWS0U2UbdJH9VjuMuSBnT2zxjUmzGMlO5Y',
  );

  runApp(
    const ProviderScope(
      child: AutoConnectApp(),
    ),
  );
}

class AutoConnectApp extends ConsumerWidget {
  const AutoConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X standard size as base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'AutoConnect LK',
          theme: AppTheme.lightTheme,
          routerConfig: router,
        );
      },
    );
  }
}
