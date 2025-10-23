import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/parking_lot.dart';
import '../models/reservation.dart';
import '../models/parking_spot.dart';

class UserDashboardScreen extends StatefulWidget {
  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ParkingLot> lots = [];
  List<Map<String, dynamic>> spotsWithDetails = [];
  List<Reservation> history = [];
  Reservation? currentReservation;
  Map<String, dynamic> summary = {};
  final _searchController = TextEditingController();
  final _vehicleController = TextEditingController();
  String? selectedLotId;
  String query = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading || !mounted) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final userId = auth.userId ?? '';
    final token = auth.token;

    try {
      final fetchedLots = await ApiService.getParkingLots(query: query, token: token);
      // Sort lots by ID for consistent sequential numbering
      final sortedLots = fetchedLots..sort((a, b) => (a.id ?? '').compareTo(b.id ?? ''));
      // Assign sequential lot numbers
      lots = sortedLots.asMap().entries.map((entry) {
        final lot = entry.value;
        lot.lotNumber = (entry.key + 1).toString(); // 1, 2, 3...
        lot.code = lot.code ?? 'LOT-${lot.id?.substring(0, 4).toUpperCase() ?? 'N/A'}'; // Keep for fallback if needed
        return lot;
      }).toList();

      if (lots.isEmpty) {
        print('No lots loaded. Check API or add sample data.');
      }
      spotsWithDetails = await ApiService.getSpotsWithDetails(token: token);
      if (spotsWithDetails is! List<Map<String, dynamic>>) {
        print('Invalid spots type: ${spotsWithDetails.runtimeType} - defaulting to []');
        spotsWithDetails = [];
      }
      // Format spot codes (1-1 format)
      for (var spot in spotsWithDetails) {
        final lotId = spot['lotId']?.toString() ?? '';
        final matchingLot = lots.firstWhere((lot) => lot.id == lotId, orElse: () => ParkingLot());
        final lotNum = matchingLot.lotNumber ?? 'N/A';
        final spotIndex = spot['spotIndex'] ?? 1;
        spot['spotCode'] = '$lotNum-$spotIndex'; // e.g., "1-1"
      }
      if (spotsWithDetails.isEmpty) {
        print('No spots loaded. Check API or add sample data.');
      }
      final reservationsRaw = await ApiService.getReservations(
        userId: userId,
        token: token,
      );
      history = reservationsRaw
          .where((r) => r is Map<String, dynamic>)
          .map((r) => Reservation.fromJson(r as Map<String, dynamic>))
          .whereType<Reservation>()
          .toList();
      if (history.isEmpty) {
        print('No history loaded. Check API or make reservations.');
      }
      currentReservation = history.firstWhere(
        (r) => r.leavingTimestamp == null,
        orElse: () => Reservation(),
      );
      summary = await ApiService.getSummary(token: token) ?? {};
      print('Summary: $summary');
    } catch (e) {
      print('_loadData error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load failed: $e. Check console for details.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reserveSpot() async {
    if (selectedLotId == null || _vehicleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select lot and enter vehicle number.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = context.read<AuthService>().token;
    final success = await ApiService.reserveSpot(
      selectedLotId!,
      _vehicleController.text,
      token: token,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Spot reserved successfully!')),
      );
      _vehicleController.clear();
      setState(() => selectedLotId = null);
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reserve spot. Check vehicle format.')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _releaseSpot(Reservation res) async {
    if (!mounted || res.id == null) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final token = auth.token;
    final response = await ApiService.releaseReservation(res.id!, token: token);
    if (response != null && response['message'] == 'Released') {
      final cost = (response['cost'] as num?)?.toDouble() ?? 0.0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Spot released! Cost: ₹${cost.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to release spot.'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    auth.logout();
    ApiService.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged out successfully!'), backgroundColor: Colors.green),
    );
  }

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
        child: Column(
          children: [
            // Custom AppBar
            Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                ),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.dashboard, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Welcome to User Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                        onPressed: _isLoading ? null : _loadData,
                        tooltip: 'Refresh Data',
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.logout, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // TabBar
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.blue.shade700,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                tabs: [
                  Tab(text: 'Parking Lots'),
                  Tab(text: 'Recent Parking History'),
                  Tab(text: 'Summary Charts'),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue.shade600),
                          SizedBox(height: 16),
                          Text('Loading data...', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLotsTab(),
                        _buildHistoryTab(),
                        _buildSummaryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotsTab() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Styled Search Bar (unchanged)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Lots...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
                _loadData();
              },
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: lots.length,
              itemBuilder: (context, index) {
                final lot = lots[index];
                final lotNumber = lot.lotNumber ?? (index + 1).toString(); // Sequential 1,2,3...
                final availability = lot.availability ?? '0/0';
                final availSplit = availability.split('/');
                final avail = int.tryParse(availSplit[0] ?? '0') ?? 0;
                final total = int.tryParse(availSplit[1] ?? '0') ?? 0;
                final isFull = avail == 0;
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: isFull
                              ? [Colors.red.shade50, Colors.red.shade100]
                              : [Colors.green.shade50, Colors.green.shade100],
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isFull ? Colors.red.shade200 : Colors.green.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFull ? Icons.warning : Icons.check_circle,
                            color: isFull ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                        title: Text(
                          lot.primeLocationName ?? 'Unknown Lot',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lot : $lotNumber'), // Sequential 1,2,3...
                            Text('${lot.address ?? 'N/A'}, ${lot.pinCode ?? 'N/A'}'),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.currency_rupee, size: 14, color: Colors.grey.shade600),
                                Text('₹${lot.price}/hr', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              availability,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isFull ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              height: 4,
                              child: LinearProgressIndicator(
                                value: avail / total,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isFull ? Colors.red.shade400 : Colors.green.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            selectedLotId = lot.id;
                          });
                          _showReserveDialog(context, lot);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showReserveDialog(BuildContext context, ParkingLot lot) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_parking, size: 60, color: Colors.blue.shade600),
              SizedBox(height: 16),
              Text(
                'Reserve Spot in ${lot.primeLocationName ?? 'Lot'}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _vehicleController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Number',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.blue.shade600),
                    SizedBox(width: 8),
                    Text('Price: ₹${lot.price}/hour', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reserveSpot();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Reserve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.blue.shade600, size: 28),
              SizedBox(width: 12),
              Text(
                'Recent Parking History',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (history.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                    SizedBox(height: 16),
                    Text(
                      'No parking history yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Make a reservation to get started!',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final res = history[index];
                  final isActive = res.leavingTimestamp == null;
                  // Find spot for index
                  final spot = spotsWithDetails.firstWhere(
                    (s) => s['id'] == res.spotId,
                    orElse: () => {'spotIndex': 1},
                  );
                  final spotIndex = spot['spotIndex'] ?? 1;
                  // Find lot number (sequential)
                  final lotId = res.lotId ?? '';
                  final lotIndex = lots.indexWhere((lot) => lot.id == lotId);
                  final lotNumber = lotIndex != -1 ? (lotIndex + 1).toString() : 'N/A';
                  final spotCode = '$lotNumber-$spotIndex'; // e.g., "1-1"
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(
                              color: isActive ? Colors.blue.shade400 : Colors.green.shade400,
                              width: 4,
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.blue.shade100 : Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isActive ? Icons.access_time : Icons.check,
                              color: isActive ? Colors.blue.shade600 : Colors.green.shade600,
                            ),
                          ),
                          title: Text(
                            'Vehicle: ${res.vehicleNumber ?? 'N/A'}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lot : $lotNumber'), // Sequential 1,2,3...
                              Text('Spot Code: $spotCode'), // 1-1 format
                              Text('Parked: ${res.formattedParkingTime}'),
                            ],
                          ),
                          trailing: isActive
                              ? ElevatedButton(
                                  onPressed: () => _releaseSpot(res),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: Text('Release', style: TextStyle(color: Colors.white)),
                                )
                              : Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Cost: ₹${res.parkingCost?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final occupied = (summary['occupiedSpots'] ?? 0).toDouble();
    final available = (summary['availableSpots'] ?? 0).toDouble();
    final total = occupied + available;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple.shade600, size: 28),
              SizedBox(width: 12),
              Text(
                'Parking Spots Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50, Colors.white],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Spots Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: DoughnutChart(
                        occupied: occupied,
                        available: available,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Occupied', occupied.toInt(), Colors.red.shade400, Icons.people),
                        _buildStatCard('Available', available.toInt(), Colors.green.shade400, Icons.local_parking),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      width: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

class DoughnutChart extends StatelessWidget {
  final double occupied;
  final double available;

  const DoughnutChart({
    Key? key,
    required this.occupied,
    required this.available,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: occupied,
            color: Colors.red.shade400,
            title: '${occupied.toInt()}',
            titleStyle: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            radius: 80,
          ),
          PieChartSectionData(
            value: available,
            color: Colors.green.shade400,
            title: '${available.toInt()}',
            titleStyle: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            radius: 80,
          ),
        ],
        centerSpaceRadius: 50,
        sectionsSpace: 4,
        borderData: FlBorderData(show: false),
      ),
    );
  }
}