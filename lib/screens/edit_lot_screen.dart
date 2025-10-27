// lib/screens/edit_lot_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/parking_lot.dart';

class EditLotScreen extends StatefulWidget {
  final ParkingLot lot;
  final VoidCallback onUpdated;
  const EditLotScreen({super.key, required this.lot, required this.onUpdated});

  @override
  _EditLotScreenState createState() => _EditLotScreenState();
}

class _EditLotScreenState extends State<EditLotScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  late TextEditingController _pinController;
  late TextEditingController _maxSpotsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lot.primeLocationName);
    _priceController = TextEditingController(text: widget.lot.price.toString());
    _addressController = TextEditingController(text: widget.lot.address);
    _pinController = TextEditingController(text: widget.lot.pinCode);
    _maxSpotsController = TextEditingController(
      text: widget.lot.maximumNumberOfSpots.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Parking Lot')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Prime Location Name',
                ),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price per Hour'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(labelText: 'Pin Code'),
              ),
              TextFormField(
                controller: _maxSpotsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Number of Spots',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _updateLot, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateLot() async {
    final data = {
      'primeLocationName': _nameController.text,
      'price': double.parse(_priceController.text),
      'address': _addressController.text,
      'pinCode': _pinController.text,
      'maximumNumberOfSpots': int.parse(_maxSpotsController.text),
    };
    // Fix String? to String conversion for lot.id
    await ApiService.updateParkingLot(widget.lot.id ?? '', data);
    widget.onUpdated();
    Navigator.pop(context);
  }
}
