// Utility for formatting dates and times in standard Indonesian format

const MONTHS_ID = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

const DAYS_ID = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

/**
 * Format a date string or Date object into "17 Agustus 2026" or "Senin, 17 Agustus 2026"
 */
export const formatIndonesianDate = (dateInput, includeDayName = false) => {
  if (!dateInput) return '-';

  let dateObj;
  if (typeof dateInput === 'string') {
    const cleaned = dateInput.trim();
    dateObj = new Date(cleaned);
  } else if (dateInput instanceof Date) {
    dateObj = dateInput;
  } else {
    return String(dateInput);
  }

  if (isNaN(dateObj.getTime())) {
    return String(dateInput);
  }

  const dayName = DAYS_ID[dateObj.getDay()];
  const dateNum = dateObj.getDate();
  const monthName = MONTHS_ID[dateObj.getMonth()];
  const yearNum = dateObj.getFullYear();

  if (includeDayName) {
    return `${dayName}, ${dateNum} ${monthName} ${yearNum}`;
  }

  return `${dateNum} ${monthName} ${yearNum}`;
};

/**
 * Format a timestamp into time format "17:45 WIB"
 */
export const formatIndonesianTime = (dateInput) => {
  if (!dateInput || dateInput === '-') return '-';

  let dateObj;
  if (typeof dateInput === 'string') {
    if (/^\d{2}:\d{2}(:\d{2})?$/.test(dateInput.trim())) {
      return dateInput.trim().substring(0, 5) + ' WIB';
    }
    dateObj = new Date(dateInput.trim());
  } else if (dateInput instanceof Date) {
    dateObj = dateInput;
  } else {
    return String(dateInput);
  }

  if (isNaN(dateObj.getTime())) {
    return String(dateInput);
  }

  const hours = String(dateObj.getHours()).padStart(2, '0');
  const minutes = String(dateObj.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes} WIB`;
};

/**
 * Calculate duration in days between two dates
 */
export const calculateDurationDays = (startDateInput, endDateInput) => {
  if (!startDateInput) return 1;
  if (!endDateInput || startDateInput === endDateInput) return 1;

  const start = new Date(startDateInput);
  const end = new Date(endDateInput);

  if (isNaN(start.getTime()) || isNaN(end.getTime())) return 1;

  const diffTime = end.getTime() - start.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
  return diffDays > 0 ? diffDays : 1;
};

/**
 * Normalize any date input string to standard HTML5 date input format "YYYY-MM-DD"
 */
export const formatInputDate = (dateInput) => {
  if (!dateInput) return '';
  const str = String(dateInput).trim();
  if (!str) return '';

  // Case 1: YYYY-MM-DD... (e.g. "2026-09-04" or "2026-09-04 00:00:00" or "2026-09-04T00:00:00Z")
  const ymdMatch = str.match(/^(\d{4})[-/](\d{1,2})[-/](\d{1,2})/);
  if (ymdMatch) {
    const y = ymdMatch[1];
    const m = ymdMatch[2].padStart(2, '0');
    const d = ymdMatch[3].padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  // Case 2: DD-MM-YYYY or DD/MM/YYYY
  const dmyMatch = str.match(/^(\d{1,2})[-/](\d{1,2})[-/](\d{4})/);
  if (dmyMatch) {
    const d = dmyMatch[1].padStart(2, '0');
    const m = dmyMatch[2].padStart(2, '0');
    const y = dmyMatch[3];
    return `${y}-${m}-${d}`;
  }

  // Case 3: Try Date object parsing
  const dObj = new Date(str);
  if (!isNaN(dObj.getTime())) {
    const year = dObj.getFullYear();
    const month = String(dObj.getMonth() + 1).padStart(2, '0');
    const day = String(dObj.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  return '';
};

/**
 * Format date range into "17 Agustus 2026 s/d 20 Agustus 2026"
 */
export const formatIndonesianDateRange = (startDateInput, endDateInput, showDuration = false) => {
  const startStr = startDateInput || endDateInput || '';
  const endStr = endDateInput || startDateInput || '';
  if (!startStr) return '-';

  const startFormatted = formatIndonesianDate(startStr);
  const endFormatted = formatIndonesianDate(endStr);
  const days = calculateDurationDays(startStr, endStr);

  const rangeText = `${startFormatted} s/d ${endFormatted}`;
  return showDuration ? `${rangeText} (${days} Hari)` : rangeText;
};
