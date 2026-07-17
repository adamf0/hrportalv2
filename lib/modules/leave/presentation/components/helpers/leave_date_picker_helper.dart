import 'package:flutter/material.dart';
import 'package:hrportalv2/core/location_wifi_helper.dart';
import 'package:hrportalv2/modules/leave/domain/leave_form_type.dart';

class LeaveDatePickerHelper {
  static Future<DateTime?> pickDate({
    required BuildContext context,
    required bool isStart,
    required LeaveFormType formType,
    required DateTime cutiStartDate,
    required DateTime cutiEndDate,
    required DateTime izinDate,
    required DateTime sppdStartDate,
    required DateTime sppdEndDate,
  }) async {
    DateTime initialDate;
    DateTime firstDate;

    switch (formType) {
      case LeaveFormType.cuti:
        initialDate = isStart ? cutiStartDate : cutiEndDate;
        firstDate = isStart
            ? DateTime.now().subtract(const Duration(days: 30))
            : cutiStartDate;
        break;
      case LeaveFormType.izin:
        initialDate = izinDate;
        firstDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case LeaveFormType.sppd:
        initialDate = isStart ? sppdStartDate : sppdEndDate;
        firstDate = isStart
            ? DateTime.now().subtract(const Duration(days: 30))
            : sppdStartDate;
        break;
    }

    // if (LocationWifiHelper.isIndonesianHoliday(initialDate)) {
    //   while (LocationWifiHelper.isIndonesianHoliday(initialDate)) {
    //     initialDate = initialDate.add(const Duration(days: 1));
    //   }
    // }
    // if (LocationWifiHelper.isIndonesianHoliday(firstDate)) {
    //   while (LocationWifiHelper.isIndonesianHoliday(firstDate)) {
    //     firstDate = firstDate.add(const Duration(days: 1));
    //   }
    // }

    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // selectableDayPredicate: (date) {
      //   return !LocationWifiHelper.isIndonesianHoliday(date);
      // },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
