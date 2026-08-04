import '../../../../core/mediator/mediator.dart';
import '../../domain/leave.dart';

class SubmitLeaveCommand extends ICommand<bool> {
  final LeaveRequest request;
  final String supervisorId;
  final String? attachmentPath;
  final List<Supervisor>? members;

  SubmitLeaveCommand({
    required this.request,
    required this.supervisorId,
    this.attachmentPath,
    this.members,
  });
}
