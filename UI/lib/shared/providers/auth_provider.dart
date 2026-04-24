import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';
import 'package:tendergo/shared/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Dodajemo polja za korisnika i error poruku
  UserDto? _currentUser;
  UserDto? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthProvider(this._authService);

  // --- NOVA METODA: loadUser ---
  Future<AuthResult> loadUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.getCurrentUser();
      
      if (result.success) {
        _currentUser = result.data;
      } else {
        _errorMessage = result.message;
      }
      return result;
    } catch (e) {
      _errorMessage = "Failed to load user data.";
      return AuthResult(success: false, message: _errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- POSTOJEĆE METODE ---

  Future<bool> login(String email, String password) async {
    // Ovdje bi bilo dobro dodati isLoading ako login traje dugo
    return await _authService.login(
      LoginRequest(email: email, password: password),
    );
  }

  Future<bool> registerUser(RegisterRequest request) async {
    _isLoading = true;
    notifyListeners(); 

    try {
      final success = await _authService.register(request);
      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  Future<AuthResult> resetPassword(ResetPasswordRequest request) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.resetPassword(request);
      return result; 
    } catch (e) {
      return AuthResult(success: false, message: "Something went wrong");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResult> sendForgotPasswordEmail(String email) async {
    _isLoading = true;
    notifyListeners(); 

    try {
      final result = await _authService.forgotPassword(email);
      return result;
    } catch (e) {
      return AuthResult(success: false, message: "Something went wrong.");
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // Bonus: Metoda za logout kako bi očistio podatke
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}