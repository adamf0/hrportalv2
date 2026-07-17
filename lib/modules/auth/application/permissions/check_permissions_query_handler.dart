import '../../../../core/mediator/mediator.dart';
import '../../domain/i_auth_repository.dart';
import 'check_permissions_query.dart';

class CheckPermissionsQueryHandler extends IQueryHandler<CheckPermissionsQuery, bool> {
  final IAuthRepository repository;

  CheckPermissionsQueryHandler(this.repository);

  @override
  Future<bool> handle(CheckPermissionsQuery query) async {
    return await repository.checkPermissionsGranted();
  }
}
