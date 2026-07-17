import '../../../../core/mediator/mediator.dart';
import '../../domain/auth.dart';
import '../../domain/i_auth_repository.dart';
import 'check_token_query.dart';

class CheckTokenQueryHandler extends IQueryHandler<CheckTokenQuery, AuthSession?> {
  final IAuthRepository repository;

  CheckTokenQueryHandler(this.repository);

  @override
  Future<AuthSession?> handle(CheckTokenQuery query) async {
    return await repository.checkValidSession();
  }
}
