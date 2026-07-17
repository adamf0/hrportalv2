import '../../../../core/mediator/mediator.dart';
import '../../domain/auth.dart';
import '../../domain/i_auth_repository.dart';
import 'login_command.dart';

class LoginCommandHandler extends ICommandHandler<LoginCommand, AuthSession?> {
  final IAuthRepository repository;

  LoginCommandHandler(this.repository);

  @override
  Future<AuthSession?> handle(LoginCommand command) async {
    return await repository.login(command.username, command.password);
  }
}
