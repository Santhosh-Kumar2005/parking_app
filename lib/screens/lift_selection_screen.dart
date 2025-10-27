// ============================================
// File: lib/screens/lift_selection_screen.dart
// LIFT SELECTION AFTER PAYMENT
// ============================================

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/lift.dart';
import '../services/api_service.dart';

class LiftSelectionScreen extends StatefulWidget {
  final String bookingId;
  final String blockId;
  final String vehicleNumber;
  final String qrCodeData;

  const LiftSelectionScreen({
    Key? key,
    required this.bookingId,
    required this.blockId,
    required this.vehicleNumber,
    required this.qrCodeData,
  }) : super(key: key);

  @override
  State<LiftSelectionScreen> createState() => _LiftSelectionScreenState();
}

class _LiftSelectionScreenState extends State<LiftSelectionScreen> {
  List<Lift> lifts = [];
  Lift? assignedLift;
  bool isLoading = true;
  bool waitMode = false;
  String message = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _autoAssignLift();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 5 seconds to check lift availability
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (waitMode && mounted) {
        _autoAssignLift();
      }
    });
  }

  Future<void> _autoAssignLift() async {
    try {
      final result = await ApiService.assignLift(
        bookingId: widget.bookingId,
        blockId: widget.blockId,
        vehicleNumber: widget.vehicleNumber,
      );

      if (result != null && mounted) {
        setState(() {
          if (result['assigned'] == true && result['lift'] != null) {
            assignedLift = result['lift'];
            waitMode = false;
            message = result['message'] ?? 'Lift assigned successfully';
          } else if (result['waitStatus'] == true) {
            waitMode = true;
            message =
                result['message'] ?? 'Both lifts occupied. Please wait...';
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Auto assign error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          message = 'Error assigning lift. Please try again.';
        });
      }
    }
  }

  Future<void> _refreshLifts() async {
    try {
      final blockLifts = await ApiService.getLiftsByBlock(widget.blockId);
      if (mounted) {
        setState(() {
          lifts = blockLifts;
        });
      }
    } catch (e) {
      print('Refresh lifts error: $e');
    }
  }

  Color _getLiftStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'in_transit':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getLiftStatusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle;
      case 'occupied':
        return Icons.cancel;
      case 'in_transit':
        return Icons.sync;
      default:
        return Icons.help;
    }
  }

  Widget _buildRouteMap(int liftNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Route to Lift $liftNumber',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRouteStep(1, 'Enter through Main Gate', Icons.door_front_door),
          _buildRouteArrow(),
          _buildRouteStep(
            2,
            'Turn ${liftNumber == 1 ? "LEFT" : "RIGHT"}',
            liftNumber == 1 ? Icons.turn_left : Icons.turn_right,
          ),
          _buildRouteArrow(),
          _buildRouteStep(
            3,
            'Proceed to Lift $liftNumber Zone',
            Icons.local_parking,
          ),
          _buildRouteArrow(),
          _buildRouteStep(4, 'Show QR Code at Gate', Icons.qr_code_scanner),
          _buildRouteArrow(),
          _buildRouteStep(5, 'Drive onto Lift Platform', Icons.directions_car),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated time: 2 minutes\nLift ${widget.blockId} - Lift $liftNumber',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStep(int step, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteArrow() {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Icon(Icons.arrow_downward, color: Colors.blue.shade300, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lift Selection'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Block', widget.blockId),
                        _buildInfoRow('Vehicle', widget.vehicleNumber),
                        _buildInfoRow(
                          'Booking ID',
                          widget.bookingId.substring(0, 10) + '...',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wait Mode
                  if (waitMode) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 64,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please Wait',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            'Checking availability every 5 seconds...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Assigned Lift
                  if (!waitMode && assignedLift != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Lift Assigned!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lift ${assignedLift!.liftNumber}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            assignedLift!.liftId,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Route Map
                    _buildRouteMap(assignedLift!.liftNumber),
                    const SizedBox(height: 24),

                    // QR Code Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 100,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Show this QR at the gate',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.qrCodeData,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Important Instructions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstruction(
                            '1. Follow the route map to reach your assigned lift',
                          ),
                          _buildInstruction(
                            '2. Show QR code at the gate for entry',
                          ),
                          _buildInstruction(
                            '3. Drive your vehicle onto the lift platform',
                          ),
                          _buildInstruction(
                            '4. Exit your vehicle and step off the lift',
                          ),
                          _buildInstruction(
                            '5. Lift will automatically transport your vehicle',
                          ),
                          _buildInstruction(
                            '6. Collect your vehicle using the same QR code',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
