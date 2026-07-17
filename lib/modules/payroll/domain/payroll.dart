class PayrollData {
  final int idpublish;
  final String nip;
  final String noMesin;
  final String nama;
  final String prodi;
  final String status; // e.g. "DOSEN", "PEGAWAI"
  final String jafung;
  final double gajiPokok;
  final double tkeluarga;
  final double tanak;
  final double tpangan;
  final double tstruktural;
  final double tfungsional;
  final double mengajar;
  final double nonregular;
  final double d3regular;
  final double d3nonregular;
  final double pascasarjana;
  final double transpot;
  final double tkhusus;
  final double bpjs;
  final double astekY;
  final double dplkY;
  final double gajikotor;
  final double astekP;
  final double dplkP;
  final double pkoperasi;
  final double pyayasan;
  final double pzakat;
  final double gajibersih;
  final String bulan;
  final String tahun;

  PayrollData({
    required this.idpublish,
    required this.nip,
    required this.noMesin,
    required this.nama,
    required this.prodi,
    required this.status,
    required this.jafung,
    required this.gajiPokok,
    required this.tkeluarga,
    required this.tanak,
    required this.tpangan,
    required this.tstruktural,
    required this.tfungsional,
    required this.mengajar,
    required this.nonregular,
    required this.d3regular,
    required this.d3nonregular,
    required this.pascasarjana,
    required this.transpot,
    required this.tkhusus,
    required this.bpjs,
    required this.astekY,
    required this.dplkY,
    required this.gajikotor,
    required this.astekP,
    required this.dplkP,
    required this.pkoperasi,
    required this.pyayasan,
    required this.pzakat,
    required this.gajibersih,
    required this.bulan,
    required this.tahun,
  });

  factory PayrollData.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return PayrollData(
      idpublish: json['idpublish'] ?? 0,
      nip: json['nip'] ?? '',
      noMesin: json['no_mesin'] ?? '',
      nama: json['nama'] ?? '',
      prodi: json['prodi'] ?? '',
      status: json['status'] ?? '',
      jafung: json['jafung'] ?? '',
      gajiPokok: toDouble(json['gaji_pokok']),
      tkeluarga: toDouble(json['tkeluarga']),
      tanak: toDouble(json['tanak']),
      tpangan: toDouble(json['tpangan']),
      tstruktural: toDouble(json['tstruktural']),
      tfungsional: toDouble(json['tfungsional']),
      mengajar: toDouble(json['mengajar']),
      nonregular: toDouble(json['nonregular']),
      d3regular: toDouble(json['D3regular']),
      d3nonregular: toDouble(json['D3nonregular']),
      pascasarjana: toDouble(json['pascasarjana']),
      transpot: toDouble(json['transpot']),
      tkhusus: toDouble(json['tkhusus']),
      bpjs: toDouble(json['bpjs']),
      astekY: toDouble(json['astekY']),
      dplkY: toDouble(json['dplkY']),
      gajikotor: toDouble(json['gajikotor']),
      astekP: toDouble(json['astekP']),
      dplkP: toDouble(json['dplkP']),
      pkoperasi: toDouble(json['pkoperasi']),
      pyayasan: toDouble(json['pyayasan']),
      pzakat: toDouble(json['pzakat']),
      gajibersih: toDouble(json['gajibersih']),
      bulan: json['bulan'] ?? '',
      tahun: json['tahun'] ?? '',
    );
  }

  factory PayrollData.mock(String m, String y) {
    return PayrollData(
      idpublish: 168414,
      nip: "10616049757",
      noMesin: "201606012",
      nama: "Roni Jayawinangun, SE., M. Si.",
      prodi: "ISIB",
      status: "DOSEN",
      jafung: "Lektor Kepala",
      gajiPokok: 2277300,
      tkeluarga: 113865,
      tanak: 0,
      tpangan: 160930,
      tstruktural: 2750000,
      tfungsional: 2000000,
      mengajar: 480000,
      nonregular: 370000,
      d3regular: 0,
      d3nonregular: 0,
      pascasarjana: 0,
      transpot: 550000,
      tkhusus: 500000,
      bpjs: 156042,
      astekY: 330809,
      dplkY: 0,
      gajikotor: 9688946,
      astekP: 156042,
      dplkP: 0,
      pkoperasi: 0,
      pyayasan: 0,
      pzakat: 0,
      gajibersih: 8968032,
      bulan: m,
      tahun: y,
    );
  }
}
