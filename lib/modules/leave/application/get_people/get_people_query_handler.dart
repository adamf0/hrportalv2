import '../../../../core/mediator/mediator.dart';
import '../../domain/leave.dart';
import '../../domain/i_leave_repository.dart';
import 'get_people_query.dart';

class GetPeopleQueryHandler extends IQueryHandler<GetPeopleQuery, List<Supervisor>> {
  final ILeaveRepository repository;

  GetPeopleQueryHandler(this.repository);

  @override
  Future<List<Supervisor>> handle(GetPeopleQuery query) async {
    return await repository.getPeople();
  }
}
