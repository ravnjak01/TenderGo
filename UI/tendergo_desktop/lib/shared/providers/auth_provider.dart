import 'package:tendergo/shared/models/requests/login_request.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
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

  Future<ApiResponse> loadUser() async {
    final result = await handleAsync(() => _authService.getCurrentUser());
    if (result != null && result.success) {
      _currentUser = result.data;
      notifyListeners();
    } else {
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    }

    return result ??
        ApiResponse.failure(error ?? 'Failed to load user', statusCode: 400);
  }
Future<ApiResponse> login(String email, String password) async {
  final result = await _authService.login(
    LoginRequest(email: email, password: password),
  );
  
  if (!result.success) {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();

   return ApiResponse.failure(
      'Pogrešan email ili lozinka.', 
      statusCode: result.statusCode ,
    );
  }
  
  final userResult = await loadUser();
  
  if (userResult.success && !isAdmin) {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
    
    return ApiResponse.failure('Pristup odbijen. Nemate administratorske privilegije.', statusCode: 403);
  }

  return userResult;
}

  void logout() {
    _currentUser = null;
    safeNotify();
  }
}
