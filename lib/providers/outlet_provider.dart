// lib/providers/outlet_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/outlet.dart';
import '../data/repositories/outlet_repository.dart';

class OutletProvider with ChangeNotifier {
  final OutletRepository _repository = OutletRepository();
  
  List<Outlet> _outlets = [];
  bool _isLoading = false;
  Outlet? _selectedOutlet;

  // Getters
  List<Outlet> get outlets => _outlets;
  bool get isLoading => _isLoading;
  Outlet? get selectedOutlet => _selectedOutlet;

  // Initialize and load outlets
  Future<void> loadOutlets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _outlets = await _repository.getAllOutlets();
      
      // Auto-select the first outlet if available and none is selected
      if (_outlets.isNotEmpty && _selectedOutlet == null) {
        _selectedOutlet = _outlets.first;
      }
    } catch (e) {
      print('Error loading outlets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select an outlet
  void selectOutlet(int outletId) {
    final outlet = _outlets.firstWhere(
      (outlet) => outlet.id == outletId,
      orElse: () => _outlets.first,
    );
    _selectedOutlet = outlet;
    notifyListeners();
  }

  // Add a new outlet
  Future<bool> addOutlet(Outlet outlet) async {
    try {
      final id = await _repository.insertOutlet(outlet);
      
      // Add the outlet with its new ID to the list
      final newOutlet = Outlet(
        id: id,
        name: outlet.name,
        address: outlet.address,
        phone: outlet.phone,
      );
      
      _outlets.add(newOutlet);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding outlet: $e');
      return false;
    }
  }

  // Update an existing outlet
  Future<bool> updateOutlet(Outlet updatedOutlet) async {
    try {
      await _repository.updateOutlet(updatedOutlet);
      
      // Update the outlet in the list
      final index = _outlets.indexWhere((o) => o.id == updatedOutlet.id);
      if (index != -1) {
        _outlets[index] = updatedOutlet;
        
        // Update selected outlet if needed
        if (_selectedOutlet?.id == updatedOutlet.id) {
          _selectedOutlet = updatedOutlet;
        }
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      print('Error updating outlet: $e');
      return false;
    }
  }

  // Delete an outlet
  Future<bool> deleteOutlet(int id) async {
    try {
      await _repository.deleteOutlet(id);
      
      // Remove the outlet from the list
      _outlets.removeWhere((o) => o.id == id);
      
      // Reset selected outlet if needed
      if (_selectedOutlet?.id == id) {
        _selectedOutlet = _outlets.isNotEmpty ? _outlets.first : null;
      }
      
      notifyListeners();
      
      return true;
    } catch (e) {
      print('Error deleting outlet: $e');
      return false;
    }
  }

  // Get outlet by ID
  Outlet? getOutletById(int id) {
    try {
      return _outlets.firstWhere((outlet) => outlet.id == id);
    } catch (e) {
      return null;
    }
  }
}