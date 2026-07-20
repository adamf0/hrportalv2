import '../../../../core/mediator/mediator.dart';
import '../../domain/i_attendance_repository.dart';
import 'check_in_command.dart';

class CheckInCommandHandler extends ICommandHandler<CheckInCommand, bool> {
  final IAttendanceRepository repository;

  CheckInCommandHandler(this.repository);

  @override
  Future<bool> handle(CheckInCommand command) async {
    return await repository.checkIn(
      command.latitude,
      command.longitude,
      command.ipAddress,
      command.isUpacara,
      command.note,
    );
  }
}
