import 'leave.dart';

abstract class ILeaveRepository {
  Future<List<LeaveRequest>> getLeaves();
  Future<bool> submitLeave(LeaveRequest request, String supervisorId, String? attachmentPath);
  Future<List<Supervisor>> getSupervisors();
}
