import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? outletId;
  final String? outletName;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.outletId,
    this.outletName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      outletId: json['outlet_id'],
      outletName: json['outlet_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'outlet_id': outletId,
      'outlet_name': outletName,
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isManager => role.toLowerCase() == 'manager';
  bool get isCashier => role.toLowerCase() == 'cashier';
}

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  
  // Current active outlet (may be different from user's default outlet)
  int? _activeOutletId;
  String? _activeOutletName;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isManager => _user?.isManager ?? false;
  bool get isCashier => _user?.isCashier ?? false;
  
  int? get activeOutletId => _activeOutletId ?? _user?.outletId;
  String? get activeOutletName => _activeOutletName ?? _user?.outletName;

  // Initialize auth state from storage
  Future<void> initAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString != null) {
        _user = User.fromJson(json.decode(userString));
        _status = AuthStatus.authenticated;
        
        // Get active outlet
        _activeOutletId = prefs.getInt('active_outlet_id') ?? _user?.outletId;
        _activeOutletName = prefs.getString('active_outlet_name') ?? _user?.outletName;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Failed to restore session';
    }
    
    notifyListeners();
  }

  // Login function
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // For local database authentication, this would be a simple check
      // In a real app, you would validate against your database
      
      // Example hardcoded auth for demo:
      if (email == 'admin@kasirku.com' && password == 'admin123') {
        final user = User(
          id: 1,
          name: 'Admin User',
          email: email,
          role: 'Admin',
          outletId: 1, 
          outletName: 'Main Store',
        );
        
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(user.toJson()));
        
        _user = user;
        _status = AuthStatus.authenticated;
        _activeOutletId = user.outletId;
        _activeOutletName = user.outletName;
        
        notifyListeners();
        return true;
      } else if (email == 'cashier@kasirku.com' && password == 'cashier123') {
        final user = User(
          id: 2,
          name: 'Cashier User',
          email: email,
          role: 'Cashier',
          outletId: 1,
          outletName: 'Main Store',
        );
        
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(user.toJson()));
        
        _user = user;
        _status = AuthStatus.authenticated;
        _activeOutletId = user.outletId;
        _activeOutletName = user.outletName;
        
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Invalid email or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Authentication failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('active_outlet_id');
      await prefs.remove('active_outlet_name');
      
      _user = null;
      _status = AuthStatus.unauthenticated;
      _activeOutletId = null;
      _activeOutletName = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to logout: ${e.toString()}';
    }
    
    notifyListeners();
  }

  // Set active outlet
  Future<void> setActiveOutlet(int outletId, String outletName) async {
    _activeOutletId = outletId;
    _activeOutletName = outletName;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_outlet_id', outletId);
      await prefs.setString('active_outlet_name', outletName);
    } catch (e) {
      // Handle error, but don't change the active outlet
      print('Failed to save active outlet: $e');
    }
    
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check permissions
  bool canAccessFeature(String feature) {
    if (_user == null) return false;
    
    // Admin can access everything
    if (_user!.isAdmin) return true;
    
    // Define feature permissions based on roles
    switch (feature) {
      case 'cashier':
        return _user!.isAdmin || _user!.isManager || _user!.isCashier;
      case 'reports':
        return _user!.isAdmin || _user!.isManager;
      case 'manage_products':
      case 'manage_categories':
        return _user!.isAdmin || _user!.isManager;
      case 'manage_employees':
      case 'manage_outlets':
        return _user!.isAdmin;
      default:
        return false;
    }
  }
}