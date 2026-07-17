class LeaveFormData {
  static const List<Map<String, String>> cutiTypes = [
    {
      'value': '1',
      'name': 'Cuti Tahunan',
      'desc': 'Hak cuti tahunan pegawai setelah masa kerja tertentu.',
      'max': '12 Hari / Tahun'
    },
    {
      'value': '2',
      'name': 'Cuti Sakit',
      'desc': 'Cuti akibat sakit atau kondisi medis yang memerlukan perawatan.',
      'max': '30 Hari dengan Surat Dokter'
    },
    {
      'value': '3',
      'name': 'Cuti Melahirkan',
      'desc': 'Cuti bersalin bagi pegawai wanita yang melahirkan.',
      'max': '3 Bulan'
    },
    {
      'value': '4',
      'name': 'Cuti Menunaikan Ibadah Haji',
      'desc': 'Cuti khusus untuk pegawai yang menunaikan ibadah haji.',
      'max': '50 Hari (Sekali selama bekerja)'
    },
    {
      'value': '5',
      'name': 'Cuti Menunaikan Ibadah Umroh',
      'desc': 'Cuti khusus untuk pegawai yang menunaikan ibadah umroh.',
      'max': '15 Hari'
    },
    {
      'value': '6',
      'name': 'Cuti Diluar Tanggungan',
      'desc': 'Cuti di luar tanggungan negara karena alasan mendesak.',
      'max': 'Maksimal 3 Tahun'
    },
    {
      'value': '7',
      'name': 'Cuti Alasan Penting (Pernikahan)',
      'desc': 'Cuti untuk melangsungkan pernikahan pegawai.',
      'max': '3 Hari'
    },
    {
      'value': '8',
      'name': 'Cuti Alasan Penting (Keluarga Meninggal Dunia)',
      'desc': 'Cuti karena keluarga dekat meninggal dunia.',
      'max': '2 Hari'
    },
    {
      'value': '9',
      'name': 'Cuti Alasan Penting (Menikahkan Anak)',
      'desc': 'Cuti untuk menikahkan child kandung pegawai.',
      'max': '2 Hari'
    },
    {
      'value': '10',
      'name': 'Cuti Alasan Penting (Mengkhitan Anak / Baptis Anak)',
      'desc': 'Cuti untuk pelaksanaan khitanan atau baptis anak pegawai.',
      'max': '2 Hari'
    },
    {
      'value': '11',
      'name': 'Cuti Alasan Penting (Istri Melahirkan)',
      'desc': 'Cuti bagi suami saat istri melahirkan.',
      'max': '2 Hari'
    },
  ];

  static const List<Map<String, String>> izinTypes = [
    {'value': '1', 'name': 'Sakit'},
    {'value': '5', 'name': 'Keperluan Keluarga'},
    {'value': '6', 'name': 'Dinas Luar Kantor'},
    {'value': '7', 'name': 'Tugas Penunjang Tri Darma'},
    {'value': '8', 'name': 'Tugas Belajar (Studi Lanjut)'},
  ];

  static const List<Map<String, String>> sppdTypes = [
    {'value': '1', 'name': 'Perjalanan Dinas Dalam Negeri'},
    {'value': '2', 'name': 'Perjalanan Dinas Luar Negeri'},
    {'value': '3', 'name': 'Dinas Rapat / Koordinasi'},
    {'value': '4', 'name': 'Tugas Penunjang Tri Darma'},
  ];
}
