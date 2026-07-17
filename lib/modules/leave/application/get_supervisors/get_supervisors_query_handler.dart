import '../../../../core/mediator/mediator.dart';
import '../../domain/leave.dart';
import '../../domain/i_leave_repository.dart';
import 'get_supervisors_query.dart';

class GetSupervisorsQueryHandler extends IQueryHandler<GetSupervisorsQuery, List<Supervisor>> {
  final ILeaveRepository repository;

  GetSupervisorsQueryHandler(this.repository);

  @override
  Future<List<Supervisor>> handle(GetSupervisorsQuery query) async {
    return await repository.getSupervisors();
  }
}
