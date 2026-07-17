import '../../../../core/mediator/mediator.dart';
import '../../domain/i_leave_repository.dart';
import 'submit_leave_command.dart';

class SubmitLeaveCommandHandler extends ICommandHandler<SubmitLeaveCommand, bool> {
  final ILeaveRepository repository;

  SubmitLeaveCommandHandler(this.repository);

  @override
  Future<bool> handle(SubmitLeaveCommand command) async {
    return await repository.submitLeave(
      command.request,
      command.supervisorId,
      command.attachmentPath,
    );
  }
}
