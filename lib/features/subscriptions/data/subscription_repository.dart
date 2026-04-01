import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth_provider.dart';
import '../models/subscription_model.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(Supabase.instance.client);
});

class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository(this._client);

  String? get _userId => _client.auth.currentUser?.id;
  final Box _box = Hive.box('subscriptions_box');

  Future<List<Subscription>> getSubscriptions() async {
    final currentUserId = _userId;
    if (currentUserId == null) return [];

    try {
      final data = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', currentUserId)
          .order('next_billing_date', ascending: true);
          
      final subs = (data as List).map((json) => Subscription.fromJson(json)).toList();

      await _cacheSubscriptions(subs, currentUserId);
      return subs;
    } catch (e) {
      print('DEBUG: Remote fetch failed: $e');
      return _getCachedSubscriptions(currentUserId);
    }
  }

  Future<Subscription> addSubscription(Subscription subscription) async {
    final currentUserId = _userId;
    if (currentUserId == null) throw 'User not authenticated';
    
    final Map<String, dynamic> json = subscription.toJson();
    json.remove('id'); 
    json.remove('created_at');
    json['user_id'] = currentUserId; 
    
    final data = await _client
        .from('subscriptions')
        .insert(json)
        .select()
        .single();
    
    final newSub = Subscription.fromJson(data);
    
    // Update Cache
    final cached = _getCachedSubscriptions(currentUserId);
    cached.add(newSub);
    await _cacheSubscriptions(cached, currentUserId);
    return newSub;
  }

  Future<void> updateSubscription(Subscription subscription) async {
    final currentUserId = _userId;
    if (currentUserId == null) throw 'User not authenticated';

    final json = subscription.toJson();
    json.remove('id');
    json.remove('user_id');
    json.remove('created_at');
    
    await _client
        .from('subscriptions')
        .update(json)
        .eq('id', subscription.id)
        .eq('user_id', currentUserId); // Safety check
    
    final cached = _getCachedSubscriptions(currentUserId);
    final idx = cached.indexWhere((s) => s.id == subscription.id);
    if (idx != -1) {
      cached[idx] = subscription;
      await _cacheSubscriptions(cached, currentUserId);
    }
  }

  Future<void> deleteSubscription(String id) async {
    final currentUserId = _userId;
    if (currentUserId == null) throw 'User not authenticated';

    print('DEBUG: Attempting to delete: $id');
    
    await _client
        .from('subscriptions')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId); // Safety check
    
    // Update Local Cache
    final cached = _getCachedSubscriptions(currentUserId);
    cached.removeWhere((s) => s.id == id);
    await _cacheSubscriptions(cached, currentUserId);
  }

  Future<void> _cacheSubscriptions(List<Subscription> subs, String userId) async {
    final list = subs.map((s) => jsonEncode(s.toJson())).toList();
    await _box.put('cache_$userId', list);
  }

  List<Subscription> _getCachedSubscriptions(String? userId) {
    if (userId == null) return [];
    final cachedData = _box.get('cache_$userId');
    if (cachedData == null) return [];
    
    try {
      return (cachedData as List)
          .map((s) => Subscription.fromJson(jsonDecode(s)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

class SubscriptionsNotifier extends AsyncNotifier<List<Subscription>> {
  @override
  Future<List<Subscription>> build() async {
    // Re-run build when auth state changes
    ref.watch(authStateStreamProvider);
    return ref.read(subscriptionRepositoryProvider).getSubscriptions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => 
        ref.read(subscriptionRepositoryProvider).getSubscriptions());
  }

  Future<void> removeSubscription(String id) async {
    await ref.read(subscriptionRepositoryProvider).deleteSubscription(id);
    await refresh();
  }
}

final subscriptionsProvider = AsyncNotifierProvider<SubscriptionsNotifier, List<Subscription>>(() {
  return SubscriptionsNotifier();
});

