import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/promotion.dart';

final promotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final supabase = Supabase.instance.client;
  
  final data = await supabase
      .from('promotions')
      .select()
      .eq('is_active', true)
      .order('priority', ascending: false);
      
  return (data as List).map((json) => Promotion.fromJson(json)).toList();
});
