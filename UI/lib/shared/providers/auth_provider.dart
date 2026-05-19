import 'package:tendergo/shared/models/requests/login_request.dart';
import 'package:tendergo/shared/models/requests/register_request.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';
import 'package:tendergo/shared/services/auth_service.dart';

class AuthProvider extends BaseProvider {
  final AuthService _authService;

  AuthProvider(this._authService);

  UserDto? _currentUser;
  UserDto? get currentUser => _currentUser;


  String? get errorMessage => error;

  bool get isAdmin {
      final roles = _currentUser?.roles ?? const <String>[];
      return roles.any((role) => role.toLowerCase() == 'admin');
    }


  Future<AuthResult> loadUser() async {
    final result = await handleAsync(() => _authService.getCurrentUser());
    if (result != null && result.success) {
    _currentUser = result.data;
    notifyListeners();
  } else {
    // Ako loadUser ne uspije (npr. backend vrati ACCOUNT_BANNED)
    // Obavezno čistimo lokalno stanje i token da aplikacija ne upadne u beskonačnu petlju
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
  
  return result ?? AuthResult(success: false, message: error ?? 'Failed to load user');
  }

  Future<AuthResult> login(String email, String password) async {
    final result = await _authService.login(
      LoginRequest(email: email, password: password),
    );
    if (!result.success) {
      await _authService.logout();
      _currentUser = null;         
    notifyListeners();
      return result;
    }
    return loadUser();
  }

  Future<bool> registerUser(RegisterRequest request) async {
    final result = await handleAsync(() => _authService.register(request));
    return result ?? false;
  }

  Future<AuthResult> resetPassword(ResetPasswordRequest request) async {
    final result = await handleAsync(() => _authService.resetPassword(request));
    return result ?? AuthResult(success: false, message: error ?? 'Something went wrong');
  }

  Future<AuthResult> sendForgotPasswordEmail(String email) async {
    final result = await handleAsync(() => _authService.forgotPassword(email));
    return result ?? AuthResult(success: false, message: error ?? 'Something went wrong');
  }

  void logout() {
    _currentUser = null;
    safeNotify();
  }
}