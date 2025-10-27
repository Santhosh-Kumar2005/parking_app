// lib/screens/add_lot_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';


class AddLotScreen extends StatefulWidget {
  final VoidCallback? onAdded; // Made optional
  const AddLotScreen({Key? key, this.onAdded}) : super(key: key);

  @override
  _AddLotScreenState createState() => _AddLotScreenState();
}

class _AddLotScreenState extends State<AddLotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinController = TextEditingController();
  final _maxSpotsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('AddLotScreen initState - Building form'); // Debug: Confirm init
  }

  @override
  Widget build(BuildContext context) {
    print('AddLotScreen build - Rendering'); // Debug: Confirm build calls
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade700],
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
                      'Add Parking Lot',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Icon(Icons.add_location_alt, size: 64, color: Colors.blue.shade600),
                            const SizedBox(height: 16),
                            Text(
                              'New Parking Lot',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Prime Location Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade600),
                              ),
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Price per Hour (₹)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.attach_money, color: Colors.green.shade600),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'Required';
                                final num = double.tryParse(v!);
                                if (num == null || num <= 0) return 'Must be positive number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.home, color: Colors.orange.shade600),
                              ),
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pinController,
                              decoration: InputDecoration(
                                labelText: 'Pin Code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.pin_drop, color: Colors.red.shade600),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _maxSpotsController,
                              decoration: InputDecoration(
                                labelText: 'Maximum Number of Spots',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.local_parking, color: Colors.purple.shade600),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'Required';
                                final num = int.tryParse(v!);
                                if (num == null || num <= 0) return 'Must be positive integer';
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _addLot,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white),
                                      )
                                    : const Text(
                                        'Add Lot',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addLot() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = {
          'primeLocationName': _nameController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'address': _addressController.text.trim(),
          'pinCode': _pinController.text.trim(),
          'maximumNumberOfSpots': int.parse(_maxSpotsController.text.trim()),
        };
        print('Sending data to backend: $data');
        final lot = await ApiService.createParkingLot(data);
        print('API Response: $lot'); // Log full response
        if (lot != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lot added successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Call onAdded if provided
          widget.onAdded?.call();
          // Clear form for next add
          _nameController.clear();
          _priceController.clear();
          _addressController.clear();
          _pinController.clear();
          _maxSpotsController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add lot. Check backend.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error adding lot: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _pinController.dispose();
    _maxSpotsController.dispose();
    super.dispose();
  }
}