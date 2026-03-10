import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// A StateNotifierProvider that exposes the isPro status
final isProProvider = StateNotifierProvider<SubscriptionServiceNotifier, bool>((ref) {
  return SubscriptionServiceNotifier();
});

// An alias for backward compatibility with the rest of the code that read subscriptionServiceProvider
final subscriptionServiceProvider = Provider<SubscriptionServiceNotifier>((ref) {
  return ref.watch(isProProvider.notifier);
});

class SubscriptionServiceNotifier extends StateNotifier<bool> {
  // Apple App Store public key for RevenueCat
  static const _appleApiKey = 'appl_YOUR_APPLE_API_KEY';
  
  // Google Play public key for RevenueCat
  static const _googleApiKey = 'goog_YOUR_GOOGLE_API_KEY';

  SubscriptionServiceNotifier() : super(false);

  bool _isProActive(CustomerInfo info) {
    return info.entitlements.all['pro']?.isActive ?? false;
  }

  Future<void> init() async {
    if (kIsWeb) return; // Skip initialization on Web

    await Purchases.setLogLevel(LogLevel.debug);

    late PurchasesConfiguration configuration;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else {
      return;
    }

    await Purchases.configure(configuration);

    try {
      final initialInfo = await Purchases.getCustomerInfo();
      state = _isProActive(initialInfo);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        state = _isProActive(customerInfo);
      });
    } catch (e) {
      debugPrint('Error getting customer info: $e');
    }
  }

  Future<bool> purchasePro() async {
    if (kIsWeb) {
      debugPrint("Mocking successful purchase on web");
      state = true;
      return true;
    }

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        
        final logInResult = await Purchases.purchasePackage(offerings.current!.availablePackages.first);
        state = _isProActive(logInResult.customerInfo);
        return state;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to purchase: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (kIsWeb) return false;

    try {
      final customerInfo = await Purchases.restorePurchases();
      state = _isProActive(customerInfo);
      return state;
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
      return false;
    }
  }
}
