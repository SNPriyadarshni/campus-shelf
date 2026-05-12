import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onError;
  final Function(ExternalWalletResponse) onWallet;

  RazorpayService({
    required this.onSuccess,
    required this.onError,
    required this.onWallet,
  }) {
    _razorpay = Razorpay();
    // Attach the listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    onSuccess(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    onError(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    onWallet(response);
  }

  /// Opens the Razorpay checkout modal
  /// [amount] should be the actual amount in Rupees/local currency.
  /// It is automatically converted to paise before passing to Razorpay.
  void openCheckout({
    required double amount,
    required String name,
    required String description,
    required String prefillContact,
    required String prefillEmail,
    String? apiKey,
  }) {
    // Razorpay requires the amount in subunits (e.g., 100 paise = 1 INR)
    int amountInPaise = (amount * 100).toInt();

    var options = {
      // NOTE: Use your live key for production.
      'key': apiKey ?? 'rzp_test_YOUR_KEY_HERE', 
      'amount': amountInPaise,
      'name': name,
      'description': description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': prefillContact,
        'email': prefillEmail,
      },
      'theme': {
        'color': '#3399cc'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Exception while opening Razorpay: $e');
    }
  }

  /// Always call this when the service is no longer needed (e.g., in a StatefulWidget's dispose)
  void dispose() {
    _razorpay.clear();
  }
}
