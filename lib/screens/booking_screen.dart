// ...existing code...
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // When user clicks "Book Now" button
  Future<void> _startPayment(double amountInRupees, String bookingId) async {
    const backendUrl = 'https://YOUR_BACKEND_URL'; // <-- set your backend URL
    const createOrderPath = '/api/payment/create-order';
    final url = Uri.parse('$backendUrl$createOrderPath');

    try {
      // amount in paise (Razorpay expects integer paise)
      final int amountPaise = (amountInRupees * 100).round();

      final response = await http.post(
        url,
        body: convert.jsonEncode({
          'bookingId': bookingId,
          'amount': amountPaise,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final msg = 'Failed to create order: ${response.statusCode}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final orderData =
          convert.jsonDecode(response.body) as Map<String, dynamic>;

      // Ensure you use the key your backend returns for order id. Many backends return 'id'.
      final orderId =
          orderData['id'] ?? orderData['orderId'] ?? orderData['order_id'];
      final orderAmount = orderData['amount'] ?? amountPaise;

      if (orderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid order from server')),
        );
        return;
      }

      var options = {
        'key': 'YOUR_RAZORPAY_KEY_ID', // <-- set your Razorpay key id
        'amount': orderAmount,
        'order_id': orderId,
        'name': 'Your App Name',
        'description': 'Parking Booking Payment',
        'prefill': {'contact': '', 'email': ''},
      };

      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment start failed: $e')));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment successful — verify server-side
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment Failed!')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('External Wallet selected')));
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Replace with real amount and bookingId
            _startPayment(100.0, 'booking123');
          },
          child: const Text('Book Now'),
        ),
      ),
    );
  }
}
// ...existing code...