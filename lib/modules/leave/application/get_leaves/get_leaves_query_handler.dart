import '../../../../core/mediator/mediator.dart';
import '../../domain/leave.dart';
import '../../domain/i_leave_repository.dart';
import 'get_leaves_query.dart';

class GetLeavesQueryHandler extends IQueryHandler<GetLeavesQuery, List<LeaveRequest>> {
  final ILeaveRepository repository;

  GetLeavesQueryHandler(this.repository);

  @override
  Future<List<LeaveRequest>> handle(GetLeavesQuery query) async {
    return await repository.getLeaves();
  }
}
