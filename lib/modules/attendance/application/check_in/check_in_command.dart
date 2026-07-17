import '../../../../core/mediator/mediator.dart';

class CheckInCommand extends ICommand<bool> {
  final double latitude;
  final double longitude;
  final String ipAddress;
  final bool isUpacara;

  CheckInCommand({
    required this.latitude,
    required this.longitude,
    required this.ipAddress,
    required this.isUpacara,
  });
}
