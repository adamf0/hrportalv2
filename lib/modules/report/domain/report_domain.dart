enum ReportCellStatus {
  absen,
  absenAnomaly,
  izin,
  cuti,
  sppd,
  tidakMasuk,
  libur,
  minggu,
}

enum ReportPeriodType {
  calendar, // 01-31 (Calendar month)
  cutoff,   // 15-15 (16th prev month to 15th curr month)
  annual,   // Tahunan (12 Months of selected year)
}

class PegawaiReportItem {
  final String id;
  final String nip;
  final String nidn;
  final String nama;
  final String unitKerja;
  final String jabatan;
  final String status;
  final String fakultas;
  final String prodi;
  final String type; // 'dosen' or 'tendik'

  PegawaiReportItem({
    required this.id,
    required this.nip,
    required this.nidn,
    required this.nama,
    required this.unitKerja,
    required this.jabatan,
    required this.status,
    required this.fakultas,
    required this.prodi,
    required this.type,
  });

  factory PegawaiReportItem.fromJson(Map<String, dynamic> json) {
    final nipStr = json['nip']?.toString() ?? '';
    final nidnStr = json['nidn']?.toString() ?? '';
    final typeVal = json['type']?.toString().toLowerCase() ??
        (nidnStr.isNotEmpty ? 'dosen' : 'tendik');

    return PegawaiReportItem(
      id: json['id']?.toString() ?? '',
      nip: nipStr,
      nidn: nidnStr,
      nama: json['nama']?.toString() ?? 'Pegawai',
      unitKerja: json['unit_kerja']?.toString() ??
          json['unit']?.toString() ??
          json['pengangkatan']?['unit_kerja']?.toString() ??
          '-',
      jabatan: json['jabatan']?.toString() ?? json['fungsional']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'Aktif',
      fakultas: json['fakultas']?.toString() ?? '-',
      prodi: json['prodi']?.toString() ?? '-',
      type: typeVal,
    );
  }

  String get primaryId => nip.isNotEmpty ? nip : (nidn.isNotEmpty ? nidn : id);
}

class ReportCellData {
  final ReportCellStatus status;
  final String text;
  final String note;
  final bool hasAnomaly;
  final DateTime? timestamp;

  ReportCellData({
    required this.status,
    required this.text,
    this.note = '',
    this.hasAnomaly = false,
    this.timestamp,
  });
}

class ReportPeriodFilter {
  final int month;
  final int year;
  final ReportPeriodType periodType;

  ReportPeriodFilter({
    required this.month,
    required this.year,
    required this.periodType,
  });

  DateTime get startDate {
    if (periodType == ReportPeriodType.annual) {
      return DateTime(year, 1, 1);
    } else if (periodType == ReportPeriodType.calendar) {
      return DateTime(year, month, 1);
    } else {
      // Cutoff: 15th of previous month
      return DateTime(year, month - 1, 15);
    }
  }

  DateTime get endDate {
    if (periodType == ReportPeriodType.annual) {
      return DateTime(year, 12, 31);
    } else if (periodType == ReportPeriodType.calendar) {
      return DateTime(year, month + 1, 0); // Last day of month
    } else {
      // Cutoff: 15th of current month
      return DateTime(year, month, 15);
    }
  }

  List<DateTime> get dateList {
    if (periodType == ReportPeriodType.annual) {
      return List.generate(12, (index) => DateTime(year, index + 1, 1));
    }
    final List<DateTime> list = [];
    DateTime cur = startDate;
    final end = endDate;
    while (!cur.isAfter(end)) {
      list.add(cur);
      cur = DateTime(cur.year, cur.month, cur.day + 1);
    }
    return list;
  }
}
