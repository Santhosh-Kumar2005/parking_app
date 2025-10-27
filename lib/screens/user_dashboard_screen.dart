// ============================================
// File: lib/screens/user_dashboard_screen.dart - PART 1
// COMPLETE USER DASHBOARD - Copy this entire file
// ============================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/vehicle_validation.dart';
import 'package:http/http.dart' as http;
import 'payment_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  // ============================================
  // STATE VARIABLES
  // ============================================
  int totalSlots = 160;
  int availableSlots = 160;
  int occupiedSlots = 0;

  Map<String, Map<String, dynamic>> blockData = {
    'BLOCK-A': {'available': 40, 'occupied': 0, 'total': 40},
    'BLOCK-B': {'available': 40, 'occupied': 0, 'total': 40},
    'BLOCK-C': {'available': 40, 'occupied': 0, 'total': 40},
    'BLOCK-D': {'available': 40, 'occupied': 0, 'total': 40},
  };

  List<Map<String, dynamic>> userBookings = [];
  bool isLoading = true;
  bool isLoadingBookings = false;
  Timer? _refreshTimer;
  final TextEditingController _vehicleController = TextEditingController();
  int _selectedTabIndex = 0;

  // ============================================
  // LIFECYCLE METHODS
  // ============================================
  @override
  void initState() {
    super.initState();
    _fetchParkingStats();
    _loadUserBookings();

    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchParkingStats();
      if (_selectedTabIndex == 1) {
        _loadUserBookings();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _vehicleController.dispose();
    super.dispose();
  }

  // ============================================
  // FETCH PARKING STATISTICS
  // ============================================
  Future<void> _fetchParkingStats() async {
    try {
      final response = await ApiService.getParkingStats();

      if (response['success'] == true) {
        final stats = response['stats'];

        if (mounted) {
          setState(() {
            totalSlots = stats['total'] ?? 160;
            occupiedSlots = stats['occupied'] ?? 0;
            availableSlots = stats['available'] ?? 160;

            // Reset all blocks to default
            blockData = {
              'BLOCK-A': {'available': 40, 'occupied': 0, 'total': 40},
              'BLOCK-B': {'available': 40, 'occupied': 0, 'total': 40},
              'BLOCK-C': {'available': 40, 'occupied': 0, 'total': 40},
              'BLOCK-D': {'available': 40, 'occupied': 0, 'total': 40},
            };

            // Update with actual data from backend
            if (stats['blocks'] != null) {
              for (var block in stats['blocks']) {
                String blockId = block['_id'] ?? block['blockId'];
                int occupied = block['count'] ?? 0;
                int available = 40 - occupied;

                if (blockData.containsKey(blockId)) {
                  blockData[blockId] = {
                    'available': available,
                    'occupied': occupied,
                    'total': 40,
                  };
                }
              }
            }

            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching stats: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================
  // LOAD USER'S BOOKINGS
  // ============================================
  Future<void> _loadUserBookings() async {
    final auth = context.read<AuthService>();
    final userId = auth.userId;

    if (userId == null) return;

    setState(() => isLoadingBookings = true);

    try {
      final bookings = await ApiService.getUserBookings(userId);

      if (mounted) {
        setState(() {
          userBookings = bookings;
          isLoadingBookings = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      if (mounted) {
        setState(() {
          isLoadingBookings = false;
        });
      }
    }
  }

  // ============================================
  // RESERVE PARKING SPOT
  // ============================================
  Future<void> _reserveSpot(String blockId) async {
    final auth = context.read<AuthService>();
    final userId = auth.userId;

    if (userId == null) {
      _showSnackBar('User ID not found. Please login again.', Colors.red);
      return;
    }

    String vehicleNumber = _vehicleController.text.trim();

    // Validation 1: Check if empty
    if (vehicleNumber.isEmpty) {
      _showSnackBar('Please enter vehicle number', Colors.red);
      return;
    }

    // Validation 2: Check format using utility
    if (!VehicleValidation.isValid(vehicleNumber)) {
      _showDialog(
        'Invalid Vehicle Number',
        VehicleValidation.getErrorMessage(),
        Colors.red,
      );
      return;
    }

    // Validation 3: Check if slots available
    if (blockData[blockId]!['available'] <= 0) {
      _showSnackBar('No slots available in $blockId', Colors.red);
      return;
    }

    // Format vehicle number
    vehicleNumber = VehicleValidation.format(vehicleNumber);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating booking...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Create booking via API
      final response = await ApiService.createBooking(
        userId: userId,
        vehicleNumber: vehicleNumber,
        blockId: blockId,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response['success'] == true) {
        // Immediately refresh stats
        await _fetchParkingStats();

        // Clear vehicle number field
        _vehicleController.clear();

        // Navigate to payment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              bookingId: response['booking']['_id'],
              bookingData: response['booking'],
            ),
          ),
        ).then((_) {
          // Refresh stats and bookings when returning from payment
          _fetchParkingStats();
          _loadUserBookings();
        });
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      _showSnackBar('Booking failed: ${e.toString()}', Colors.red);
    }
  }

  // ============================================
  // SHOW RESERVE DIALOG
  // ============================================
  void _showReserveDialog(String blockId) {
    _vehicleController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.local_parking, color: Colors.blue),
            SizedBox(width: 8),
            Text('Reserve Spot in $blockId'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Available: ${blockData[blockId]!['available']} / 40 slots',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _vehicleController,
              decoration: InputDecoration(
                labelText: 'Vehicle Number',
                hintText: 'TN12AB1234',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.directions_car),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => _vehicleController.clear(),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                // Auto-format as user types
                if (value.length >= 4) {
                  String formatted = VehicleValidation.format(value);
                  if (formatted != value) {
                    _vehicleController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                }
              },
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Format: TN-12-AB-1234',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _reserveSpot(blockId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.payment),
            label: Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UTILITY METHODS
  // ============================================
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: color),
            SizedBox(width: 8),
            Flexible(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // RELEASE/EXIT PARKING SPOT
  // ============================================

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    auth.logout();
    ApiService.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _releaseParking(Map<String, dynamic> booking) async {
    // Show vehicle type selection dialog first
    String? vehicleType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange),
            SizedBox(width: 8),
            Text('Exit Parking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select your vehicle type to calculate final charges',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'CAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.directions_car),
                    label: Text('CAR\n₹50/hr', textAlign: TextAlign.center),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'BIKE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.two_wheeler),
                    label: Text('BIKE\n₹25/hr', textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (vehicleType == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Calculating charges...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Call release API
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/bookings/${booking['_id']}/release'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'vehicleType': vehicleType}),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final cost = data['cost'];
          final duration = data['duration'];

          // Show success dialog with cost
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Exit Successful'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Vehicle:', style: TextStyle(fontSize: 14)),
                            Text(
                              booking['vehicleNumber'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Duration:', style: TextStyle(fontSize: 14)),
                            Text(
                              '$duration hours',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Type:', style: TextStyle(fontSize: 14)),
                            Text(
                              vehicleType,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Cost:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹$cost',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Slot has been released successfully',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchParkingStats();
                    _loadUserBookings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Done'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Release failed');
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);

      _showSnackBar('Release failed: ${e.toString()}', Colors.red);
    }
  }

  // ============================================
  // PART 1 ENDS HERE - Continue to Part 2 for UI
  // ============================================

  // ============================================
  // PART 2 - UI BUILD METHODS (continues from Part 1)
  // Add this after the _logout() method in Part 1
  // ============================================

  // ============================================
  // BUILD UI
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(),

              // Tab Navigation
              _buildTabBar(),

              // Content
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _selectedTabIndex == 0
                    ? _buildDashboardTab()
                    : _buildBookingsTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // CUSTOM APP BAR
  // ============================================
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.local_parking, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parking Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Find & Reserve Parking',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh, color: Colors.white),
            ),
            onPressed: () {
              _fetchParkingStats();
              if (_selectedTabIndex == 1) _loadUserBookings();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout, color: Colors.white),
            ),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  // ============================================
  // TAB BAR
  // ============================================
  Widget _buildTabBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 0
                          ? Colors.blue
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dashboard,
                        color: _selectedTabIndex == 0
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: _selectedTabIndex == 0
                              ? Colors.blue
                              : Colors.grey,
                          fontWeight: _selectedTabIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _selectedTabIndex = 1);
                _loadUserBookings();
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 1
                          ? Colors.blue
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_online,
                        color: _selectedTabIndex == 1
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'My Bookings',
                        style: TextStyle(
                          color: _selectedTabIndex == 1
                              ? Colors.blue
                              : Colors.grey,
                          fontWeight: _selectedTabIndex == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (userBookings.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(left: 4),
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${userBookings.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DASHBOARD TAB
  // ============================================
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _fetchParkingStats,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Summary Card
          _buildSummaryCard(),

          SizedBox(height: 24),

          // Section Header
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Available Parking Blocks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Block Cards
          ...blockData.entries.map((entry) {
            return _buildBlockCard(
              entry.key,
              entry.value['available'],
              entry.value['occupied'],
            );
          }).toList(),
        ],
      ),
    );
  }

  // ============================================
  // BOOKINGS TAB
  // ============================================
  Widget _buildBookingsTab() {
    return RefreshIndicator(
      onRefresh: _loadUserBookings,
      child: isLoadingBookings
          ? Center(child: CircularProgressIndicator())
          : userBookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
                  SizedBox(height: 16),
                  Text(
                    'No Bookings Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reserve a parking spot to see it here',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedTabIndex = 0),
                    icon: Icon(Icons.add),
                    label: Text('Book Parking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: userBookings.length,
              itemBuilder: (context, index) {
                return _buildBookingCard(userBookings[index]);
              },
            ),
    );
  }

  // ============================================
  // SUMMARY CARD
  // ============================================
  Widget _buildSummaryCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.local_parking, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'Parking Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Total',
                  totalSlots.toString(),
                  Colors.white,
                  Icons.grid_on,
                ),
                _buildStatColumn(
                  'Available',
                  availableSlots.toString(),
                  Colors.greenAccent,
                  Icons.check_circle,
                ),
                _buildStatColumn(
                  'Occupied',
                  occupiedSlots.toString(),
                  Colors.orangeAccent,
                  Icons.car_rental,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // STAT COLUMN WIDGET
  // ============================================
  Widget _buildStatColumn(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  // ============================================
  // BLOCK CARD WIDGET
  // ============================================
  Widget _buildBlockCard(String blockId, int available, int occupied) {
    bool hasSlots = available > 0;
    double percentage = (available / 40) * 100;

    Color cardColor = hasSlots ? Colors.green.shade50 : Colors.red.shade50;
    Color iconColor = hasSlots ? Colors.green : Colors.red;
    Color progressColor = percentage > 50
        ? Colors.green
        : percentage > 25
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasSlots ? Colors.green.shade200 : Colors.red.shade200,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_parking,
                      color: iconColor,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blockId,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Available: $available / 40 slots',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: available / 40,
                            backgroundColor: Colors.grey.shade300,
                            color: progressColor,
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasSlots
                      ? () => _showReserveDialog(blockId)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSlots ? Colors.blue : Colors.grey,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: hasSlots ? 4 : 0,
                  ),
                  icon: Icon(
                    hasSlots ? Icons.add_circle : Icons.block,
                    size: 24,
                  ),
                  label: Text(
                    hasSlots ? 'Reserve Spot' : 'Fully Booked',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // BOOKING CARD WIDGET
  // ============================================
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    String status = booking['status'] ?? 'unknown';
    String paymentStatus = booking['paymentStatus'] ?? 'pending';
    String blockId = booking['blockId'] ?? 'N/A';
    String vehicleNumber = booking['vehicleNumber'] ?? 'N/A';
    String bookingTime = booking['bookingTime'] ?? 'N/A';
    bool canRelease = status == 'paid'; // Only paid bookings can be released

    Color statusColor = status == 'paid'
        ? Colors.green
        : status == 'payment_pending'
        ? Colors.orange
        : Colors.red;

    IconData statusIcon = status == 'paid'
        ? Icons.check_circle
        : status == 'payment_pending'
        ? Icons.pending
        : Icons.cancel;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_parking, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      blockId,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildBookingDetailRow(
              'Vehicle',
              vehicleNumber,
              Icons.directions_car,
            ),
            SizedBox(height: 8),
            _buildBookingDetailRow(
              'Booking Time',
              bookingTime,
              Icons.access_time,
            ),
            SizedBox(height: 8),
            _buildBookingDetailRow('Payment', paymentStatus, Icons.payment),

            // RELEASE BUTTON - Only show for paid bookings
            if (canRelease) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _releaseParking(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: Icon(Icons.exit_to_app, size: 20),
                  label: Text(
                    'Exit Parking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}
