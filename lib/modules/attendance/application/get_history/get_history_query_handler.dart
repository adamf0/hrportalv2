import '../../../../core/mediator/mediator.dart';
import '../../domain/attendance.dart';
import '../../domain/i_attendance_repository.dart';
import 'get_history_query.dart';

class GetAttendanceHistoryQueryHandler
    extends IQueryHandler<GetAttendanceHistoryQuery, List<ActivityLogItem>> {
  final IAttendanceRepository repository;

  GetAttendanceHistoryQueryHandler(this.repository);

  @override
  Future<List<ActivityLogItem>> handle(GetAttendanceHistoryQuery query) async {
    return await repository.fetchHistory();
  }
}
