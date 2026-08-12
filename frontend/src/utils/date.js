const BULAN_INDO = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/**
 * Mengubah string tanggal Y-m-d atau ISO 8601 menjadi format "01 Januari 2026"
 */
export const formatTanggalIndo = (dateStr) => {
  if (!dateStr) return '-';
  try {
    const cleanDate = dateStr.split('T')[0];
    const parts = cleanDate.split('-');
    if (parts.length !== 3) return dateStr;

    const year = parts[0];
    const monthIndex = parseInt(parts[1], 10) - 1;
    const day = parts[2].padStart(2, '0');

    if (monthIndex >= 0 && monthIndex < 12) {
      return `${day} ${BULAN_INDO[monthIndex]} ${year}`;
    }
    return dateStr;
  } catch {
    return dateStr;
  }
};

/**
 * Mengubah rentang tanggal menjadi "01 Januari 2026 s/d 05 Januari 2026"
 */
export const formatRentangTanggalIndo = (startStr, endStr) => {
  if (!startStr && !endStr) return '-';
  if (!endStr || startStr === endStr) return formatTanggalIndo(startStr);
  return `${formatTanggalIndo(startStr)} s/d ${formatTanggalIndo(endStr)}`;
};
