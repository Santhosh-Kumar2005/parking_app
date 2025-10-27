// lib/screens/spot_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SpotDetailsScreen extends StatefulWidget {
  final String spotId;
  const SpotDetailsScreen({Key? key, required this.spotId}) : super(key: key);

  @override
  _SpotDetailsScreenState createState() => _SpotDetailsScreenState();
}

class _SpotDetailsScreenState extends State<SpotDetailsScreen> {
  Map<String, dynamic>? spotData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpotDetails();
  }

  Future<void> _loadSpotDetails() async {
    try {
      final response = await ApiService.getSpotDetails(widget.spotId);
      print(
        'Spot details response: ${response.statusCode} - ${response.body}',
      ); // Debug log
      if (response.statusCode == 200) {
        setState(() {
          spotData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load spot details: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading spot details: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade300, Colors.teal.shade600],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Spot Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : spotData == null || spotData!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No spot data available',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSpotDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(color: Colors.teal.shade600),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.teal.shade600,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Spot Information',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildDetailRow(
                                  'Spot ID',
                                  spotData!['id'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Lot ID',
                                  spotData!['lotId'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Status',
                                  spotData!['status'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Label',
                                  spotData!['label'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Lot Name',
                                  spotData!['lotName'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Price',
                                  '₹${spotData!['price'] ?? 'N/A'}',
                                ),
                                _buildDetailRow(
                                  'User ID',
                                  spotData!['userId'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Username',
                                  spotData!['username'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Vehicle Number',
                                  spotData!['vehicleNumber'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Parking Time',
                                  spotData!['parkingTimestamp'] ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Leaving Time',
                                  spotData!['leavingTimestamp'] ??
                                      'Still Parked',
                                ),
                                _buildDetailRow(
                                  'Cost',
                                  '₹${spotData!['parkingCost'] ?? '0.00'}',
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade600,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Back',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
