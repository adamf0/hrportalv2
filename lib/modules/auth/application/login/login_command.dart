import '../../../../core/mediator/mediator.dart';
import '../../domain/auth.dart';

class LoginCommand extends ICommand<AuthSession?> {
  final String username;
  final String password;

  LoginCommand({required this.username, required this.password});
}
