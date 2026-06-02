import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../data/app_store.dart';

class RazorpayPaymentService {
  final Razorpay _razorpay = Razorpay();

  final FirebaseFunctions functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Completer<Map<String, dynamic>>? _paymentCompleter;
  String? _bookingId;

  RazorpayPaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<Map<String, dynamic>> payForBooking({
    required String bookingId,
    required double amount,
    required String description,
  }) async {
    if (_paymentCompleter != null) {
      throw Exception('payment-in-progress');
    }

    _bookingId = bookingId;
    _paymentCompleter = Completer<Map<String, dynamic>>();
    print("FUNCTION CALL STARTED");
    final orderResponse = await functions
        .httpsCallable('createRazorpayOrder')
        .call({
      'bookingId': bookingId,
      'amount': amount,
    });

    print(orderResponse.data);

    final order = Map<String, dynamic>.from(orderResponse.data as Map);
    final options = {
      'key': order['keyId'],
      'amount': order['amount'],
      'currency': order['currency'] ?? 'INR',
      'name': 'FarmXchange',
      'description': description,
      'order_id': order['orderId'],
      'prefill': {
        'contact': AppStore.currentUserPhone,
        'email': AppStore.currentUserEmail,
        'name': AppStore.currentUserName,
      },
      'notes': {
        'bookingId': bookingId,
      },
    };

    _razorpay.open(options);
    return _paymentCompleter!.future.whenComplete(() {
      _paymentCompleter = null;
      _bookingId = null;
    });
  }

  Future<void> _handleSuccess(PaymentSuccessResponse response) async {
    final bookingId = _bookingId;
    if (bookingId == null || _paymentCompleter == null) return;

    try {
      final verifyResponse = await functions
          .httpsCallable('verifyRazorpayPayment')
          .call({
        'bookingId': bookingId,
        'razorpayPaymentId': response.paymentId,
        'razorpayOrderId': response.orderId,
        'razorpaySignature': response.signature,
      });
      _paymentCompleter?.complete(
        Map<String, dynamic>.from(verifyResponse.data as Map),
      );
    } catch (e) {
      _paymentCompleter?.completeError(e);
    }
  }

  Future<void> _handleError(PaymentFailureResponse response) async {
    final bookingId = _bookingId;
    if (bookingId != null) {
      await functions
          .httpsCallable('markRazorpayPaymentFailed')
          .call({
        'bookingId': bookingId,
        'code': response.code,
        'message': response.message,
      });
    }
    _paymentCompleter?.completeError(
      Exception(response.message ?? 'payment-failed'),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void dispose() {
    _razorpay.clear();
  }
}
