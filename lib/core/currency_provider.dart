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

  bool get hasChosenCurrency {
    final uid = _userId;
    if (uid == null) return false;
    final box = Hive.box('settings');
    return box.containsKey('currency_$uid');
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

  double convertToDisplay(double usdPrice) {
    if (state == 'PHP') return usdPrice * 56.0;
    return usdPrice;
  }

  double convertToBase(double displayPrice) {
    if (state == 'PHP') return displayPrice / 56.0;
    return displayPrice;
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});
