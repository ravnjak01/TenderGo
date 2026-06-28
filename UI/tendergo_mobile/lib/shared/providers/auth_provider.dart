import 'package:tendergo/shared/core/auth/auth_token_store.dart';
import 'package:tendergo/shared/models/requests/login_request.dart';
import 'package:tendergo/shared/models/requests/register_request.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/services/auth_service.dart';

class AuthProvider extends BaseProvider {
  final AuthService _authService;
  static const AuthTokenStore _tokenStore = AuthTokenStore();

  AuthProvider(this._authService);

  UserDto? _currentUser;
  UserDto? get currentUser => _currentUser;

  String? get errorMessage => error;

  bool get isAdmin {
    final roles = _currentUser?.roles ?? const <String>[];
    return roles.any((role) => role.toLowerCase() == 'admin');
  }

  Future<ApiResponse> loadUser() async {
    if (!await _tokenStore.hasValidAccessToken()) {
      _currentUser = null;
      safeNotify();
      return ApiResponse.failure('Not authenticated.', statusCode: 401);
    }

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
      return result;
    }

    final userResult = await loadUser();

    if (!userResult.success) {
      return userResult;
    }

    if (isAdmin) {
      await _authService.logout();
      _currentUser = null;
      notifyListeners();

      return ApiResponse.failure(
        'Pristup odbijen. Administratori koriste desktop aplikaciju.',
        statusCode: 403,
      );
    }
    return result;
  }

  Future<bool> registerUser(RegisterRequest request) async {
    final result = await handleAsync(() => _authService.register(request));
    return result ?? false;
  }

  Future<ApiResponse> resetPassword(ResetPasswordRequest request) async {
    final result = await handleAsync(() => _authService.resetPassword(request));
    return result ??
        ApiResponse.failure(error ?? 'Something went wrong', statusCode: 400);
  }

  Future<ApiResponse> sendForgotPasswordEmail(String email) async {
    final result = await handleAsync(() => _authService.forgotPassword(email));
    return result ??
        ApiResponse.failure(error ?? 'Something went wrong', statusCode: 400);
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    safeNotify();
  }
}
