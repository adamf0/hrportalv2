import '../../../../core/mediator/mediator.dart';
import '../../domain/i_auth_repository.dart';
import 'request_permissions_command.dart';

class RequestPermissionsCommandHandler extends ICommandHandler<RequestPermissionsCommand, bool> {
  final IAuthRepository repository;

  RequestPermissionsCommandHandler(this.repository);

  @override
  Future<bool> handle(RequestPermissionsCommand command) async {
    return await repository.requestPermissions();
  }
}
