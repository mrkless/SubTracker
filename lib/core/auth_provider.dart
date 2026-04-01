import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the Supabase Auth State stream
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Provider for the current user ID
final userIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  return authState.value?.session?.user?.id ?? Supabase.instance.client.auth.currentUser?.id;
});
