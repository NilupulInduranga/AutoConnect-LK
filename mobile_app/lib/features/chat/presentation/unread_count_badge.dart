import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_provider.dart';

class UnreadCountBadge extends ConsumerWidget {
  final Widget child;

  const UnreadCountBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return unreadCountAsync.when(
      data: (count) {
        if (count == 0) return child;
        return Badge(
          label: Text('$count'),
          child: child,
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}
