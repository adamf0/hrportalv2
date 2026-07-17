import '../../../../core/mediator/mediator.dart';
import '../../domain/i_attendance_repository.dart';
import 'check_out_command.dart';

class CheckOutCommandHandler extends ICommandHandler<CheckOutCommand, bool> {
  final IAttendanceRepository repository;

  CheckOutCommandHandler(this.repository);

  @override
  Future<bool> handle(CheckOutCommand command) async {
    return await repository.checkOut(
      command.latitude,
      command.longitude,
      command.ipAddress,
    );
  }
}
