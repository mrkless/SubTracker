import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'auth_provider.dart';

class CurrencyNotifier extends Notifier<String> {
  String? get _userId => ref.watch(userIdProvider);

  @override
  String build() {
    final uid = _userId;
    if (uid == null) return 'USD';
    final box = Hive.box('settings');
    return box.get('currency_$uid', defaultValue: 'USD');
  }

  void setCurrency(String code) {
    final uid = _userId;
    if (uid == null) return;
    state = code;
    final box = Hive.box('settings');
    box.put('currency_$uid', code);
  }

  String get symbol {
    switch (state) {
      case 'PHP':
        return '₱';
      case 'USD':
      default:
        return '\$';
    }
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});
