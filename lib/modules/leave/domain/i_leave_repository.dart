import 'leave.dart';

abstract class ILeaveRepository {
  Future<List<LeaveRequest>> getLeaves();
  Future<List<LeaveRequest>> getVerificationLeaves();
  Future<bool> submitLeave(LeaveRequest request, String supervisorId, String? attachmentPath, [List<Supervisor>? members]);
  Future<bool> updateLeaveStatus(String id, String status, String? note);
  Future<bool> deleteLeave(String id);
  Future<List<Supervisor>> getSupervisors();
  Future<List<Supervisor>> getPeople();
}
