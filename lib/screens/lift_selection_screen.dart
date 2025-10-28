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
  String errorMessage = '';
  Timer? _refreshTimer;
  int retryCount = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    print('🚀 LiftSelectionScreen initialized');
    print('📦 Booking ID: ${widget.bookingId}');
    print('🏢 Block ID: ${widget.blockId}');
    print('🚗 Vehicle: ${widget.vehicleNumber}');
    _autoAssignLift();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (waitMode && mounted) {
        print('⏰ Auto-refresh triggered');
        _autoAssignLift();
      }
    });
  }

  Future<void> _autoAssignLift() async {
    if (!mounted) return;

    print('🔄 Attempting to assign lift (Retry: $retryCount/$maxRetries)');

    try {
      final result =
          await ApiService.assignLift(
            bookingId: widget.bookingId,
            blockId: widget.blockId,
            vehicleNumber: widget.vehicleNumber,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out after 15 seconds');
            },
          );

      print('📥 API Response received: $result');

      if (!mounted) return;

      if (result == null) {
        throw Exception('No response from server');
      }

      setState(() {
        errorMessage = '';

        if (result['assigned'] == true && result['lift'] != null) {
          print('✅ Lift assignment successful');
          try {
            assignedLift = Lift.fromJson(result['lift']);
            waitMode = false;
            message = result['message'] ?? 'Lift assigned successfully';
            retryCount = 0;
            print(
              '✅ Lift ${assignedLift!.liftNumber} assigned to ${widget.vehicleNumber}',
            );
          } catch (e) {
            print('❌ Error parsing lift data: $e');
            print('🔍 Lift data was: ${result['lift']}');
            errorMessage = 'Error processing lift data: ${e.toString()}';
          }
        } else if (result['waitStatus'] == true) {
          print('⏳ Entering wait mode');
          waitMode = true;
          message = result['message'] ?? 'Both lifts occupied. Please wait...';
        } else {
          print('⚠️ Unexpected response structure');
          errorMessage = result['message'] ?? 'Unexpected response from server';
        }

        isLoading = false;
      });
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      _handleError(
        'Connection timeout. Please check your internet connection.',
      );
    } catch (e) {
      print('❌ Error assigning lift: $e');
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
      errorMessage = error;

      if (retryCount < maxRetries) {
        retryCount++;
        message = 'Retrying... (${retryCount}/$maxRetries)';
        print('🔄 Will retry in 3 seconds');
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => isLoading = true);
            _autoAssignLift();
          }
        });
      } else {
        message =
            'Failed after $maxRetries attempts. Please try again manually.';
        print('❌ Max retries reached');
      }
    });
  }

  Future<void> _manualRetry() async {
    print('🔄 Manual retry triggered');
    setState(() {
      isLoading = true;
      errorMessage = '';
      message = '';
      retryCount = 0;
    });
    await _autoAssignLift();
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
        actions: [
          if (errorMessage.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _manualRetry,
              tooltip: 'Retry',
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Assigning lift...',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  if (retryCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Retry $retryCount/$maxRetries',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : errorMessage.isNotEmpty
          ? _buildErrorScreen()
          : _buildContentScreen(),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _manualRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentScreen() {
    return SingleChildScrollView(
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
                  widget.bookingId.length > 10
                      ? widget.bookingId.substring(0, 10) + '...'
                      : widget.bookingId,
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
                border: Border.all(color: Colors.orange.shade200, width: 2),
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
                border: Border.all(color: Colors.green.shade200, width: 2),
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
                  const Icon(Icons.qr_code_2, size: 100, color: Colors.black),
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
                    'Scan to access Lift ${assignedLift!.liftNumber}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                      Icon(Icons.info_outline, color: Colors.amber.shade700),
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
                  _buildInstruction('2. Show QR code at the gate for entry'),
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
            const SizedBox(height: 24),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check),
                label: const Text(
                  'Done - Return to Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
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
