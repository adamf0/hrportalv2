/// Strongly-typed Enum for Leave Categories (Cuti, Izin, SPPD, Semua)
enum LeaveCategory {
  semua('Semua'),
  cuti('Cuti'),
  izin('Izin'),
  sppd('SPPD');

  final String label;
  const LeaveCategory(this.label);

  static LeaveCategory fromString(String categoryStr) {
    switch (categoryStr.trim().toUpperCase()) {
      case 'CUTI':
        return LeaveCategory.cuti;
      case 'IZIN':
        return LeaveCategory.izin;
      case 'SPPD':
        return LeaveCategory.sppd;
      default:
        return LeaveCategory.semua;
    }
  }

  bool matches(String itemType) {
    if (this == LeaveCategory.semua) return true;
    return itemType.toLowerCase().contains(label.toLowerCase());
  }
}
