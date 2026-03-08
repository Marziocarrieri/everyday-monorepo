import 'package:everyday_app/shared/services/auth_service.dart';

class WelcomeFlowService {
  final AuthService _authService = AuthService();

  bool get hasActiveSession => _authService.currentUser != null;
}
