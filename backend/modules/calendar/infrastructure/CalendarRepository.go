package infrastructure

import (
	"context"
	"sync"
	"time"

	attendanceDomain "hrportal_backend/modules/attendance/domain"
	"hrportal_backend/modules/calendar/domain"
	izinDomain "hrportal_backend/modules/izin/domain"
	leaveDomain "hrportal_backend/modules/leave/domain"
	sppdDomain "hrportal_backend/modules/sppd/domain"

	"gorm.io/gorm"
)

type CalendarRepository struct {
	db *gorm.DB
}

func NewCalendarRepository(db *gorm.DB) domain.ICalendarRepository {
	return &CalendarRepository{db: db}
}

func (r *CalendarRepository) GetCalendarEvents(ctx context.Context, nip string, nidn string, startDate string, endDate string) ([]domain.CalendarItem, error) {
	var (
		wg      sync.WaitGroup
		absens  []attendanceDomain.Absen
		izins   []izinDomain.Izin
		cutis   []leaveDomain.Cuti
		sppds   []sppdDomain.Sppd
		mu      sync.Mutex
		results []domain.CalendarItem
	)

	wg.Add(4)

	// 1. Fetch Absen
	go func() {
		defer wg.Done()
		var list []attendanceDomain.Absen
		query := r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}).Where("absen_masuk IS NOT NULL")
		if startDate != "" && endDate != "" {
			query = query.Where("tanggal >= ? AND tanggal <= ?", startDate, endDate)
		}
		if nip != "" && nidn != "" {
			query = query.Where("nip = ? OR nidn = ?", nip, nidn)
		} else if nip != "" {
			query = query.Where("nip = ?", nip)
		} else if nidn != "" {
			query = query.Where("nidn = ?", nidn)
		}
		_ = query.Find(&list)
		mu.Lock()
		absens = list
		mu.Unlock()
	}()

	// 2. Fetch Izin
	go func() {
		defer wg.Done()
		var list []izinDomain.Izin
		query := r.db.WithContext(ctx).Model(&izinDomain.Izin{})
		if startDate != "" && endDate != "" {
			query = query.Where("tanggal_pengajuan >= ? AND tanggal_pengajuan <= ?", startDate, endDate)
		}
		if nip != "" && nidn != "" {
			query = query.Where("nip = ? OR nidn = ?", nip, nidn)
		} else if nip != "" {
			query = query.Where("nip = ?", nip)
		} else if nidn != "" {
			query = query.Where("nidn = ?", nidn)
		}
		_ = query.Find(&list)
		mu.Lock()
		izins = list
		mu.Unlock()
	}()

	// 3. Fetch Cuti (Leave)
	go func() {
		defer wg.Done()
		var list []leaveDomain.Cuti
		query := r.db.WithContext(ctx).Model(&leaveDomain.Cuti{})
		if startDate != "" && endDate != "" {
			query = query.Where("tanggal_mulai >= ? AND tanggal_mulai <= ?", startDate, endDate)
		}
		if nip != "" && nidn != "" {
			query = query.Where("nip = ? OR nidn = ?", nip, nidn)
		} else if nip != "" {
			query = query.Where("nip = ?", nip)
		} else if nidn != "" {
			query = query.Where("nidn = ?", nidn)
		}
		_ = query.Find(&list)
		mu.Lock()
		cutis = list
		mu.Unlock()
	}()

	// 4. Fetch Sppd
	go func() {
		defer wg.Done()
		var list []sppdDomain.Sppd
		query := r.db.WithContext(ctx).Model(&sppdDomain.Sppd{})
		if startDate != "" && endDate != "" {
			query = query.Where("tanggal_berangkat >= ? AND tanggal_berangkat <= ?", startDate, endDate)
		}
		if nip != "" && nidn != "" {
			query = query.Where("nip = ? OR nidn = ?", nip, nidn)
		} else if nip != "" {
			query = query.Where("nip = ?", nip)
		} else if nidn != "" {
			query = query.Where("nidn = ?", nidn)
		}
		_ = query.Find(&list)
		mu.Lock()
		sppds = list
		mu.Unlock()
	}()

	wg.Wait()

	// Map Absens
	for _, a := range absens {
		note := "Hadir"
		if a.CatatanTelat != nil && *a.CatatanTelat != "" {
			note = *a.CatatanTelat
		}
		dateStr := a.Tanggal
		if t, err := parseDateString(dateStr); err == nil {
			dateStr = t.Format("2006-01-02")
		}
		results = append(results, domain.CalendarItem{
			Nip:     a.Nip,
			Nidn:    a.Nidn,
			Tanggal: dateStr,
			Type:    "absen",
			Catatan: note,
			Status:  "acc",
		})
	}

	// Map Izins
	for _, i := range izins {
		dateStr := i.TanggalPengajuan
		if t, err := parseDateString(dateStr); err == nil {
			dateStr = t.Format("2006-01-02")
		}
		results = append(results, domain.CalendarItem{
			Nip:     i.Nip,
			Nidn:    i.Nidn,
			Tanggal: dateStr,
			Type:    "izin",
			Catatan: i.Tujuan,
			Status:  i.Status,
		})
	}

	// Map Cutis (Flatten Date Range)
	for _, c := range cutis {
		dates := getDatesInRange(c.TanggalMulai, c.TanggalSelesai)
		for _, date := range dates {
			results = append(results, domain.CalendarItem{
				Nip:     c.Nip,
				Nidn:    c.Nidn,
				Tanggal: date,
				Type:    "cuti",
				Catatan: c.Alasan,
				Status:  c.Status,
			})
		}
	}

	// Map Sppds (Flatten Date Range)
	for _, s := range sppds {
		dates := getDatesInRange(s.TanggalBerangkat, s.TanggalKembali)
		for _, date := range dates {
			results = append(results, domain.CalendarItem{
				Nip:     s.Nip,
				Nidn:    s.Nidn,
				Tanggal: date,
				Type:    "sppd",
				Catatan: s.Keterangan,
				Status:  s.Status,
			})
		}
	}

	return results, nil
}

func parseDateString(s string) (time.Time, error) {
	// Try parsing RFC3339/ISO
	t, err := time.Parse(time.RFC3339, s)
	if err == nil {
		return t, nil
	}
	// Try parsing YYYY-MM-DD
	t, err = time.Parse("2006-01-02", s)
	if err == nil {
		return t, nil
	}
	return time.Time{}, err
}

func getDatesInRange(startStr, endStr string) []string {
	start, err := parseDateString(startStr)
	if err != nil {
		return []string{startStr}
	}
	end, err := parseDateString(endStr)
	if err != nil {
		return []string{startStr}
	}

	if start.After(end) {
		start, end = end, start
	}

	// Normalize to local date boundaries
	start = time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, time.Local)
	end = time.Date(end.Year(), end.Month(), end.Day(), 0, 0, 0, 0, time.Local)

	var dates []string
	for d := start; !d.After(end); d = d.AddDate(0, 0, 1) {
		dates = append(dates, d.Format("2006-01-02"))
	}
	return dates
}
