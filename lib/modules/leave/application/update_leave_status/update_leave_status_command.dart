import '../../../../core/mediator/mediator.dart';
import '../../domain/i_leave_repository.dart';

class UpdateLeaveStatusCommand extends ICommand<bool> {
  final String id;
  final String status;
  final String? note;

  UpdateLeaveStatusCommand({
    required this.id,
    required this.status,
    this.note,
  });
}

class UpdateLeaveStatusCommandHandler
    implements ICommandHandler<UpdateLeaveStatusCommand, bool> {
  final ILeaveRepository _leaveRepository;

  UpdateLeaveStatusCommandHandler(this._leaveRepository);

  @override
  Future<bool> handle(UpdateLeaveStatusCommand command) async {
    return await _leaveRepository.updateLeaveStatus(
      command.id,
      command.status,
      command.note,
    );
  }
}
