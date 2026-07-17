import '../../../../core/mediator/mediator.dart';

class CheckOutCommand extends ICommand<bool> {
  final double latitude;
  final double longitude;
  final String ipAddress;

  CheckOutCommand({
    required this.latitude,
    required this.longitude,
    required this.ipAddress,
  });
}
