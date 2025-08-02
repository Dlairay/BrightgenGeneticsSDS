import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../core/utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _accessToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Child? _selectedChild; // Track currently selected child
  
  // Getters
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Child> get children => _currentUser?.children ?? [];
  Child? get selectedChild => _selectedChild;
  
  // Initialize auth state from storage
  Future<void> initializeAuth() async {
    try {
      // For testing: Always clear auth to show login screen first
      await _clearStoredAuth();
      AppLogger.info('Auth cleared - showing login screen');
      
      // TODO: Uncomment to restore stored tokens later
      /*
      final storedToken = await StorageService.getSecureData(StorageService.keyAuthToken);
      final storedEmail = await StorageService.getSecureData(StorageService.keyUserEmail);
      
      if (storedToken != null && storedEmail != null) {
        _accessToken = storedToken;
        _currentUser = User(
          id: 'user_stored',
          name: storedEmail.split('@').first,
          email: storedEmail,
          children: [],
        );
        _isAuthenticated = true;
        AppLogger.info('Auth initialized from stored credentials');
      } else {
        AppLogger.info('No stored credentials - showing login screen');
      }
      */
    } catch (e) {
      AppLogger.error('Failed to initialize auth', error: e);
      await _clearStoredAuth();
    }
    
    // No loading state needed - this is instant
    notifyListeners();
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      AppLogger.info('Attempting login for: $email');
      
      final loginRequest = LoginRequest(email: email, password: password);
      final response = await ApiService.login(loginRequest.toJson());
      final authResponse = AuthResponse.fromJson(response);
      
      // SIMPLE: Just store token and create basic user (like frontend.html)
      _accessToken = authResponse.accessToken;
      await StorageService.saveSecureData(StorageService.keyAuthToken, _accessToken!);
      await StorageService.saveSecureData(StorageService.keyUserEmail, email);
      
      // Now load children from API (like frontend.html does)
      try {
        final childrenData = await ApiService.getChildren();
        _currentUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@').first,
          email: email,
          children: childrenData.map((child) => Child.fromJson(child)).toList(),
        );
        AppLogger.info('Loaded ${childrenData.length} children for user');
        
        // Auto-select first child if available
        if (_currentUser!.children.isNotEmpty) {
          _selectedChild = _currentUser!.children.first;
          AppLogger.info('Auto-selected first child: ${_selectedChild!.name}');
        }
      } catch (e) {
        // If children loading fails, still proceed with empty children list
        _currentUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@').first,
          email: email,
          children: [],
        );
        AppLogger.warning('Failed to load children: ${e.toString()}');
      }
      
      await StorageService.saveSecureData(StorageService.keyUserId, _currentUser!.id);
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      
      AppLogger.info('Login successful for user: ${_currentUser!.name}');
      return true;
      
    } catch (e) {
      _errorMessage = _formatErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      AppLogger.error('Login failed', error: e);
      return false;
    }
  }
  
  // Register
  Future<bool> register(String name, String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      AppLogger.info('Attempting registration for: $email');
      
      final registerRequest = RegisterRequest(name: name, email: email, password: password);
      final response = await ApiService.register(registerRequest.toJson());
      final authResponse = AuthResponse.fromJson(response);
      
      // Store just the token and email initially
      _accessToken = authResponse.accessToken;
      await StorageService.saveSecureData(StorageService.keyAuthToken, _accessToken!);
      await StorageService.saveSecureData(StorageService.keyUserEmail, email);
      
      // Create user with the provided name
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        children: [],
      );
      
      await StorageService.saveSecureData(StorageService.keyUserId, _currentUser!.id);
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      
      AppLogger.info('Registration successful for user: ${_currentUser!.name}');
      return true;
      
    } catch (e) {
      _errorMessage = _formatErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      AppLogger.error('Registration failed', error: e);
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      AppLogger.info('Logging out user: ${_currentUser?.name}');
      
      // Clear stored data
      await _clearStoredAuth();
      
      // Reset state
      _currentUser = null;
      _accessToken = null;
      _isAuthenticated = false;
      _errorMessage = null;
      
      notifyListeners();
      
      AppLogger.info('Logout completed');
    } catch (e) {
      AppLogger.error('Error during logout', error: e);
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Get child by ID
  Child? getChildById(String childId) {
    return children.where((child) => child.id == childId).firstOrNull;
  }
  
  // Select a specific child
  void selectChild(Child child) {
    _selectedChild = child;
    AppLogger.info('Selected child: ${child.name}');
    notifyListeners();
  }
  
  // Select child by ID
  void selectChildById(String childId) {
    final child = getChildById(childId);
    if (child != null) {
      selectChild(child);
    }
  }
  
  // Refresh user data
  Future<bool> refreshUserData() async {
    if (!_isAuthenticated || _accessToken == null) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Fetch children data (like frontend.html does)
      final childrenData = await ApiService.getChildren();
      
      if (_currentUser != null) {
        // Update existing user with fresh children data
        _currentUser = User(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          children: childrenData.map((child) => Child.fromJson(child)).toList(),
        );
      }
      
      _isLoading = false;
      notifyListeners();
      
      AppLogger.info('User data refreshed');
      return true;
      
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      AppLogger.error('Failed to refresh user data', error: e);
      return false;
    }
  }
  
  // Private helper methods
  
  Future<void> _clearStoredAuth() async {
    await StorageService.deleteSecureData(StorageService.keyAuthToken);
    await StorageService.deleteSecureData(StorageService.keyUserId);
    await StorageService.deleteSecureData(StorageService.keyUserEmail);
  }
  
  String _formatErrorMessage(String error) {
    // Format common error messages for better user experience
    if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Invalid email or password. Please try again.';
    } else if (error.contains('400') || error.contains('Bad request')) {
      return 'Please check your information and try again.';
    } else if (error.contains('409') || error.contains('Conflict')) {
      return 'An account with this email already exists.';
    } else if (error.contains('Network') || error.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}