import '../../../../core/mediator/mediator.dart';
import '../../domain/i_leave_repository.dart';
import '../../domain/leave.dart';

class GetVerificationLeavesQuery extends IQuery<List<LeaveRequest>> {}

class GetVerificationLeavesQueryHandler
    implements IQueryHandler<GetVerificationLeavesQuery, List<LeaveRequest>> {
  final ILeaveRepository _leaveRepository;

  GetVerificationLeavesQueryHandler(this._leaveRepository);

  @override
  Future<List<LeaveRequest>> handle(GetVerificationLeavesQuery request) async {
    return await _leaveRepository.getVerificationLeaves();
  }
}
