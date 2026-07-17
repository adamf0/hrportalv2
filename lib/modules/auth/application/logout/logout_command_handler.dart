import '../../../../core/mediator/mediator.dart';
import '../../domain/i_auth_repository.dart';
import 'logout_command.dart';

class LogoutCommandHandler extends ICommandHandler<LogoutCommand, void> {
  final IAuthRepository repository;

  LogoutCommandHandler(this.repository);

  @override
  Future<void> handle(LogoutCommand command) async {
    await repository.logout();
  }
}
