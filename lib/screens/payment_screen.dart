// ============================================
// File: lib/screens/payment_screen.dart
// FIXED: Now navigates to Lift Selection after payment
// ============================================

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import 'lift_selection_screen.dart'; // ADD THIS IMPORT
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const PaymentScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isProcessing = false;
  bool paymentSuccess = false;
  String selectedVehicleType = 'CAR';
  int parkingCharges = 50;
  String? transactionId; // Store transaction ID

  @override
  void initState() {
    super.initState();
    _calculateCharges();
  }

  void _calculateCharges() {
    setState(() {
      parkingCharges = selectedVehicleType == 'CAR' ? 50 : 25;
    });
  }

  Future<void> _processPayment() async {
    setState(() => isProcessing = true);

    await Future.delayed(const Duration(seconds: 2));

    try {
      // Generate transaction ID
      transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      final response = await ApiService.updatePaymentStatus(
        bookingId: widget.bookingId,
        paymentStatus: 'paid',
        transactionId: transactionId!,
      );

      if (response['success'] == true) {
        setState(() {
          paymentSuccess = true;
          isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! ✅'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: paymentSuccess ? _buildSuccessScreen() : _buildPaymentScreen(),
    );
  }

  Widget _buildPaymentScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBookingSummaryCard(),
          const SizedBox(height: 16),
          _buildVehicleTypeSelector(),
          const SizedBox(height: 16),
          _buildPricingInfoCard(),
          const SizedBox(height: 24),
          _buildPaymentButton(),
          const SizedBox(height: 16),
          _buildCancelButton(),
        ],
      ),
    );
  }

  // ============================================
  // SUCCESS SCREEN - NOW WITH "SELECT LIFT" BUTTON
  // ============================================
  Widget _buildSuccessScreen() {
    final vehicleNumber = widget.bookingData['vehicleNumber'] ?? 'N/A';
    final blockId = widget.bookingData['blockId'] ?? 'N/A';
    final slotNumber = widget.bookingData['slotNumber'] ?? 'AUTO';

    final qrData =
        '''
Parking Booking
Vehicle: $vehicleNumber
Block: $blockId
Slot: $slotNumber
Type: $selectedVehicleType
Booking ID: ${widget.bookingId}
Transaction: $transactionId
Time: ${DateTime.now().toString()}
''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Success Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Your parking spot has been reserved',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // QR Code Card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Your Parking Pass',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Vehicle', vehicleNumber),
                        const Divider(),
                        _buildInfoRow('Block', blockId),
                        const Divider(),
                        _buildInfoRow('Slot', slotNumber),
                        const Divider(),
                        _buildInfoRow('Type', selectedVehicleType),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ⭐ NEW: Next Step Card
          Card(
            elevation: 4,
            color: Colors.orange.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Next: Select Your Lift',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose which lift to use for reaching your parking slot',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ⭐ CHANGED: "Select Lift" Button (Primary Action)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to Lift Selection Screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiftSelectionScreen(
                      bookingId: widget.bookingId,
                      blockId: blockId,
                      vehicleNumber: vehicleNumber,
                      qrCodeData: qrData,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.elevator, size: 24),
              label: const Text(
                'Select Lift →',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ⭐ CHANGED: "Skip" Button (Secondary Action)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.home, size: 20, color: Colors.grey.shade700),
              label: Text(
                'Skip & Go to Dashboard',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Booking Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow('Block', widget.bookingData['blockId'] ?? 'N/A'),
            _buildSummaryRow(
              'Vehicle Number',
              widget.bookingData['vehicleNumber'] ?? 'N/A',
            ),
            _buildSummaryRow(
              'Slot',
              widget.bookingData['slotNumber'] ?? 'Auto-assigned',
            ),
            _buildSummaryRow(
              'Floor',
              widget.bookingData['floor']?.toString() ?? '2',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Vehicle Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildVehicleTypeOption('CAR', Icons.directions_car),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVehicleTypeOption('BIKE', Icons.two_wheeler),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeOption(String type, IconData icon) {
    bool isSelected = selectedVehicleType == type;
    return InkWell(
      onTap: () {
        setState(() {
          selectedVehicleType = type;
          _calculateCharges();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Pricing Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.green.shade300),
            _buildPricingRow('Base Charge (1 hour)', '₹$parkingCharges'),
            const SizedBox(height: 8),
            Text(
              selectedVehicleType == 'CAR'
                  ? 'Extension: ₹30 per 30 mins'
                  : 'Extension: ₹15 per 30 mins',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            Divider(height: 24, color: Colors.green.shade300),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹$parkingCharges',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.payment, size: 24),
        label: Text(
          isProcessing ? 'Processing...' : 'Pay ₹$parkingCharges',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: isProcessing
          ? null
          : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Booking?'),
                  content: const Text(
                    'Are you sure you want to cancel this booking? The slot will be released.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ApiService.cancelBooking(widget.bookingId);
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: const Text(
                        'Yes, Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
      child: const Text(
        'Cancel Booking',
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
