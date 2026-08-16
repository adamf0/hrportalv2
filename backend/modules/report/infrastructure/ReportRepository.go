package infrastructure

import (
	"context"
	"fmt"
	"log"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	accountDomain "hrportal_backend/modules/account/domain"
	attendanceDomain "hrportal_backend/modules/attendance/domain"
	permissionDomain "hrportal_backend/modules/izin/domain"
	leaveDomain "hrportal_backend/modules/leave/domain"
	"hrportal_backend/modules/report/domain"
	sppdDomain "hrportal_backend/modules/sppd/domain"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type ReportRepository struct {
	db *gorm.DB
}

func NewReportRepository(db *gorm.DB) domain.IReportRepository {
	return &ReportRepository{db: db}
}

func (r *ReportRepository) GetDB() *gorm.DB {
	if r == nil {
		return nil
	}
	return r.db
}

func (r *ReportRepository) GetReportSummary(ctx context.Context, nip string, periodeType domain.PeriodeType, periodeKey string) (*domain.RekapLaporanBulanan, error) {
	targetNip := strings.TrimSpace(nip)
	if periodeKey == "" {
		periodeKey = time.Now().Format("2006-01")
	}

	if r == nil || r.db == nil {
		now := time.Now()
		return &domain.RekapLaporanBulanan{
			Nip:         targetNip,
			Nidn:        targetNip,
			PeriodeType: periodeType,
			PeriodeKey:  periodeKey,
			UpdatedAt:   &now,
		}, nil
	}

	loc := time.Local
	refDate, err := time.ParseInLocation("2006-01", periodeKey, loc)
	if err != nil {
		refDate = time.Now().In(loc)
	}

	var vStart, vEnd time.Time
	if periodeType == domain.PeriodeCutoff {
		vStart = time.Date(refDate.Year(), refDate.Month()-1, 16, 0, 0, 0, 0, loc)
		vEnd = time.Date(refDate.Year(), refDate.Month(), 15, 0, 0, 0, 0, loc)
	} else {
		vStart = time.Date(refDate.Year(), refDate.Month(), 1, 0, 0, 0, 0, loc)
		vEnd = time.Date(refDate.Year(), refDate.Month()+1, 0, 0, 0, 0, 0, loc)
	}

	startStr := vStart.Format("2006-01-02")
	endStr := vEnd.Format("2006-01-02")

	now := time.Now().In(loc)
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, loc)

	evalEnd := vEnd
	if evalEnd.After(today) {
		evalEnd = today
	}
	evalEndStr := evalEnd.Format("2006-01-02")

	var (
		wg                                                        sync.WaitGroup
		cMasuk, cIzin, cCuti, cSppd, cUpacara, cLibur, cWorkedOff int64
		emp                                                       accountDomain.Pegawai
	)

	wg.Add(7)

	// 1. Employee info
	go func() {
		defer wg.Done()
		if targetNip != "" && r.db != nil {
			_ = r.db.WithContext(ctx).Model(&accountDomain.Pegawai{}).
				Where("nip = ? OR nidn = ?", targetNip, targetNip).
				First(&emp).Error
		}
	}()

	// 2. Absen Masuk (active up to today) & count check-ins on off-days (Sundays & holidays)
	go func() {
		defer wg.Done()
		if r.db != nil {
			buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}), targetNip, targetNip).
				Where("tanggal >= ? AND tanggal <= ? AND absen_masuk IS NOT NULL", startStr, evalEndStr).
				Count(&cMasuk)

			var dates []string
			buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}), targetNip, targetNip).
				Where("tanggal >= ? AND tanggal <= ? AND absen_masuk IS NOT NULL", startStr, evalEndStr).
				Pluck("tanggal", &dates)

			for _, dStr := range dates {
				cleanDate := strings.Split(dStr, "T")[0]
				if t, err := time.Parse("2006-01-02", cleanDate); err == nil {
					isOff := t.Weekday() == time.Sunday
					if !isOff {
						var countLibur int64
						r.db.WithContext(ctx).Table("master_libur").
							Where("tanggal LIKE ? AND is_national_holiday = 1", cleanDate+"%").
							Count(&countLibur)
						if countLibur > 0 {
							isOff = true
						}
					}
					if isOff {
						cWorkedOff++
					}
				}
			}
		}
	}()

	// 3. Izin (Terima SDM) (active up to today)
	go func() {
		defer wg.Done()
		if r.db != nil {
			buildUserWhere(r.db.WithContext(ctx).Model(&permissionDomain.Izin{}), targetNip, targetNip).
				Where("tanggal_pengajuan >= ? AND tanggal_pengajuan <= ? AND LOWER(status) IN ('terima sdm', 'disetujui', 'diterima sdm')", startStr, evalEndStr).
				Count(&cIzin)
		}
	}()

	// 4. Cuti (Terima SDM) (active up to today)
	go func() {
		defer wg.Done()
		if r.db != nil {
			buildUserWhere(r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}), targetNip, targetNip).
				Where("tanggal_mulai <= ? AND tanggal_akhir >= ? AND LOWER(status) IN ('terima sdm', 'disetujui', 'diterima sdm')", evalEndStr, startStr).
				Count(&cCuti)
		}
	}()

	// 5. SPPD + Anggota (Terima SDM) (active up to today)
	go func() {
		defer wg.Done()
		if r.db != nil {
			buildSppdUserWhere(r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}), targetNip, targetNip).
				Where("tanggal_berangkat <= ? AND tanggal_kembali >= ? AND LOWER(status) IN ('terima sdm', 'disetujui', 'diterima sdm')", evalEndStr, startStr).
				Count(&cSppd)
		}
	}()

	// 6. Absen Upacara (Full Year YYYY)
	go func() {
		defer wg.Done()
		if r.db != nil {
			yearStartStr := fmt.Sprintf("%d-01-01", refDate.Year())
			yearEndStr := fmt.Sprintf("%d-12-31", refDate.Year())
			buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}), targetNip, targetNip).
				Where("tanggal >= ? AND tanggal <= ?", yearStartStr, yearEndStr).
				Count(&cUpacara)
		}
	}()

	// 7. Master Libur (active up to today)
	go func() {
		defer wg.Done()
		if r.db != nil {
			r.db.WithContext(ctx).Table("master_libur").
				Where("tanggal >= ? AND tanggal <= ? AND is_national_holiday = 1", startStr, evalEndStr).
				Count(&cLibur)
		}
	}()

	wg.Wait()

	totalElapsedDays := 0
	sundaysCount := 0
	if !vStart.After(evalEnd) {
		for d := vStart; !d.After(evalEnd); d = d.AddDate(0, 0, 1) {
			totalElapsedDays++
			if d.Weekday() == time.Sunday {
				if d.Before(today) {
					sundaysCount++
				}
			}
		}
	}

	if periodeType == domain.PeriodeCutoff && sundaysCount == 4 {
		sundaysCount = 3
	}

	totalOffDays := sundaysCount + int(cLibur)
	elapsedWorkingDays := totalElapsedDays - totalOffDays
	if elapsedWorkingDays < 0 {
		elapsedWorkingDays = 0
	}

	regularWorkingMasuk := int(cMasuk) - int(cWorkedOff)
	if regularWorkingMasuk < 0 {
		regularWorkingMasuk = 0
	}

	totalTidakMasuk := elapsedWorkingDays - regularWorkingMasuk - int(cIzin) - int(cCuti) - int(cSppd)
	if totalTidakMasuk < 0 {
		totalTidakMasuk = 0
	}

	namaVal := emp.Nama
	if namaVal == "" {
		namaVal = targetNip
	}
	unitVal := ""
	if emp.UnitKerja != nil && *emp.UnitKerja != "" {
		unitVal = *emp.UnitKerja
	} else if emp.Unit != nil {
		unitVal = *emp.Unit
	}
	fakultasVal := ""
	if emp.Fakultas != nil {
		fakultasVal = *emp.Fakultas
	}
	prodiVal := ""
	if emp.Prodi != nil {
		prodiVal = *emp.Prodi
	}

	rekap := &domain.RekapLaporanBulanan{
		Nip:             targetNip,
		Nidn:            targetNip,
		Nama:            namaVal,
		Unit:            unitVal,
		Fakultas:        fakultasVal,
		Prodi:           prodiVal,
		PeriodeType:     periodeType,
		PeriodeKey:      periodeKey,
		TanggalMulai:    startStr,
		TanggalAkhir:    endStr,
		TotalMasuk:      int(cMasuk),
		TotalIzin:       int(cIzin),
		TotalCuti:       int(cCuti),
		TotalSppd:       int(cSppd),
		TotalUpacara:    int(cUpacara),
		TotalLibur:      totalOffDays,
		TotalTidakMasuk: totalTidakMasuk,
		UpdatedAt:       &now,
	}

	return rekap, nil
}

func (r *ReportRepository) GetAllLaporanAbsen(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string) (map[string]interface{}, error) {
	db := r.db
	if db == nil {
		log.Println("[ReportRepository] Error: Database connection is nil in GetAllLaporanAbsen")
		return map[string]interface{}{
			"versi_1_calendar": map[string]interface{}{"start": "", "end": "", "list_data": []domain.RekapLaporanBulanan{}},
			"versi_2_cutoff":   map[string]interface{}{"start": "", "end": "", "list_data": []domain.RekapLaporanBulanan{}},
		}, nil
	}

	now := time.Now()

	// 1. Versi 1 (Calendar Month)
	v1Start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	v1End := v1Start.AddDate(0, 1, -1)
	v1Key := v1Start.Format("2006-01")

	var rekapsV1 []domain.RekapLaporanBulanan
	q1 := db.WithContext(ctx).Model(&domain.RekapLaporanBulanan{}).
		Where("periode_type = ? AND periode_key = ?", domain.PeriodeCalendar, v1Key)
	if nip != "" {
		q1 = q1.Where("nip = ?", nip)
	}
	if nidn != "" {
		q1 = q1.Where("nidn = ?", nidn)
	}
	q1.Find(&rekapsV1)

	// 2. Versi 2 (Cutoff Period)
	v2Start := time.Date(now.Year(), now.Month()-1, 15, 0, 0, 0, 0, now.Location())
	v2End := time.Date(now.Year(), now.Month(), 15, 0, 0, 0, 0, now.Location())
	v2Key := now.Format("2006-01")

	var rekapsV2 []domain.RekapLaporanBulanan
	q2 := db.WithContext(ctx).Model(&domain.RekapLaporanBulanan{}).
		Where("periode_type = ? AND periode_key = ?", domain.PeriodeCutoff, v2Key)
	if nip != "" {
		q2 = q2.Where("nip = ?", nip)
	}
	if nidn != "" {
		q2 = q2.Where("nidn = ?", nidn)
	}
	q2.Find(&rekapsV2)

	return map[string]interface{}{
		"versi_1_calendar": map[string]interface{}{
			"start":     v1Start.Format("02 January 2006"),
			"end":       v1End.Format("02 January 2006"),
			"list_data": rekapsV1,
		},
		"versi_2_cutoff": map[string]interface{}{
			"start":     v2Start.Format("02 January 2006"),
			"end":       v2End.Format("02 January 2006"),
			"list_data": rekapsV2,
		},
	}, nil
}

func (r *ReportRepository) GetLaporanMergedParallel(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string, userType string) ([]domain.LaporanPenggunaMerged, error) {
	db := r.db
	if db == nil {
		log.Println("[ReportRepository] Error: Database connection is nil in GetLaporanMergedParallel")
		return []domain.LaporanPenggunaMerged{}, nil
	}

	if tanggalMulai == "" {
		tanggalMulai = time.Now().Format("2006-01") + "-01"
	}
	if tanggalAkhir == "" {
		tanggalAkhir = time.Now().Format("2006-01-02")
	}

	var (
		wg           sync.WaitGroup
		pegawais     []accountDomain.Pegawai
		absens       []attendanceDomain.Absen
		izins        []permissionDomain.Izin
		cutis        []leaveDomain.Cuti
		sppds        []sppdDomain.Sppd
		sppdAnggotas []sppdDomain.SppdAnggota
		upacaras     []attendanceDomain.AbsenUpacara
	)

	wg.Add(6)

	// Query 1: Absen Masuk
	go func() {
		defer wg.Done()
		if db == nil {
			return
		}
		q := db.WithContext(ctx).Model(&attendanceDomain.Absen{}).
			Where("tanggal >= ? AND tanggal <= ? AND absen_masuk IS NOT NULL", tanggalMulai, tanggalAkhir)
		if nip != "" {
			q = q.Where("nip = ?", nip)
		}
		if nidn != "" {
			q = q.Where("nidn = ?", nidn)
		}
		q.Find(&absens)
	}()

	// Query 2: Izin
	go func() {
		defer wg.Done()
		if db == nil {
			return
		}
		q := db.WithContext(ctx).Model(&permissionDomain.Izin{}).
			Where("tanggal_pengajuan >= ? AND tanggal_pengajuan <= ? AND (status IS NULL OR status NOT IN ('Tolak Atasan', 'Tolak SDM', 'tolak atasan', 'tolak sdm'))", tanggalMulai, tanggalAkhir)
		if nip != "" {
			q = q.Where("nip = ?", nip)
		}
		if nidn != "" {
			q = q.Where("nidn = ?", nidn)
		}
		q.Find(&izins)
	}()

	// Query 3: Cuti
	go func() {
		defer wg.Done()
		if db == nil {
			return
		}
		q := db.WithContext(ctx).Model(&leaveDomain.Cuti{}).
			Where("tanggal_mulai <= ? AND tanggal_akhir >= ? AND (status IS NULL OR status NOT IN ('Tolak Atasan', 'Tolak SDM', 'tolak atasan', 'tolak sdm'))", tanggalAkhir, tanggalMulai)
		if nip != "" {
			q = q.Where("nip = ?", nip)
		}
		if nidn != "" {
			q = q.Where("nidn = ?", nidn)
		}
		q.Find(&cutis)
	}()

	// Query 4: SPPD
	go func() {
		defer wg.Done()
		if db == nil {
			return
		}
		q := db.WithContext(ctx).Model(&sppdDomain.Sppd{}).
			Where("tanggal_berangkat <= ? AND tanggal_kembali >= ? AND (status IS NULL OR status NOT IN ('Tolak Atasan', 'Tolak SDM', 'tolak atasan', 'tolak sdm'))", tanggalAkhir, tanggalMulai)
		if nip != "" {
			q = q.Where("nip = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ?)", nip, nip)
		}
		if nidn != "" {
			q = q.Where("nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nidn = ?)", nidn, nidn)
		}
		q.Find(&sppds)
	}()

	// Query 5: SPPD Anggota
	go func() {
		defer wg.Done()
		if db == nil {
			return
		}
		qSa := db.WithContext(ctx).Model(&sppdDomain.SppdAnggota{}).
			Joins("JOIN sppd ON sppd.id = sppd_anggota.id_sppd").
			Where("sppd.tanggal_berangkat <= ? AND sppd.tanggal_kembali >= ? AND (sppd.status IS NULL OR sppd.status NOT IN ('Tolak Atasan', 'Tolak SDM', 'tolak atasan', 'tolak sdm'))", tanggalAkhir, tanggalMulai)
		if nip != "" {
			qSa = qSa.Where("sppd_anggota.nip = ?", nip)
		}
		if nidn != "" {
			qSa = qSa.Where("sppd_anggota.nidn = ?", nidn)
		}
		qSa.Find(&sppdAnggotas)
	}()

	// Query 6: Absen Upacara
	go func() {
		defer wg.Done()
		if db == nil {
			return
		}
		qu := db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}).
			Where("tanggal >= ? AND tanggal <= ?", tanggalMulai, tanggalAkhir)
		if nip != "" {
			qu = qu.Where("nip = ?", nip)
		}
		if nidn != "" {
			qu = qu.Where("nidn = ?", nidn)
		}
		qu.Find(&upacaras)
	}()

	wg.Wait()

	// Extract unique Pegawai list in-memory directly from fetched activity slices
	empMap := make(map[string]accountDomain.Pegawai)
	addPegawai := func(nipVal, nidnVal, namaVal, fakVal, prodiVal, unitVal string) {
		nipClean := strings.TrimSpace(nipVal)
		nidnClean := strings.TrimSpace(nidnVal)
		if nipClean == "" && nidnClean == "" {
			return
		}
		key := nipClean
		if key == "" {
			key = nidnClean
		}
		if _, exists := empMap[key]; !exists {
			uStr := unitVal
			fStr := fakVal
			pStr := prodiVal
			empMap[key] = accountDomain.Pegawai{
				Nip:       nipClean,
				Nidn:      nidnClean,
				Nama:      namaVal,
				UnitKerja: &uStr,
				Unit:      &uStr,
				Fakultas:  &fStr,
				Prodi:     &pStr,
			}
		}
	}

	for _, a := range absens {
		addPegawai(a.Nip, a.Nidn, a.NamaPegawai, a.Fakultas, a.Prodi, a.Unit)
	}
	for _, iz := range izins {
		addPegawai(iz.Nip, iz.Nidn, iz.NamaPemohon, iz.Fakultas, iz.Prodi, iz.Unit)
	}
	for _, c := range cutis {
		addPegawai(c.Nip, c.Nidn, c.NamaPemohon, c.Fakultas, c.Prodi, c.Unit)
	}
	for _, sp := range sppds {
		addPegawai(sp.Nip, sp.Nidn, sp.NamaPemohon, sp.Fakultas, sp.Prodi, sp.Unit)
	}
	for _, sa := range sppdAnggotas {
		addPegawai(sa.Nip, sa.Nidn, sa.Nama, sa.Fakultas, sa.Prodi, sa.Unit)
	}
	for _, u := range upacaras {
		addPegawai(u.Nip, u.Nidn, u.Nama, u.Fakultas, u.Prodi, u.Unit)
	}

	if len(empMap) == 0 && (nip != "" || nidn != "") {
		key := nip
		if key == "" {
			key = nidn
		}
		empMap[key] = accountDomain.Pegawai{
			Nip:  nip,
			Nidn: nidn,
			Nama: nip,
		}
	}

	for _, p := range empMap {
		pegawais = append(pegawais, p)
	}

	// Map to look up members by SppdID quickly
	anggotaBySppdID := make(map[uint][]sppdDomain.SppdAnggota)
	for _, sa := range sppdAnggotas {
		anggotaBySppdID[sa.SppdID] = append(anggotaBySppdID[sa.SppdID], sa)
	}

	recordsByNip := make(map[string][]domain.RecordItem)
	recordsByNidn := make(map[string][]domain.RecordItem)

	for _, a := range absens {
		var masukStr, keluarStr *string
		if a.AbsenMasuk != nil {
			s := a.AbsenMasuk.In(time.Local).Format("2006-01-02 15:04:05")
			masukStr = &s
		}
		if a.AbsenKeluar != nil {
			s := a.AbsenKeluar.In(time.Local).Format("2006-01-02 15:04:05")
			keluarStr = &s
		}
		rec := domain.RecordItem{
			ID:      a.ID,
			Tanggal: a.Tanggal,
			Type:    "absen",
			Info: map[string]interface{}{
				"masuk":  masukStr,
				"keluar": keluarStr,
			},
		}
		if a.Nip != "" {
			recordsByNip[a.Nip] = append(recordsByNip[a.Nip], rec)
		} else if a.Nidn != "" {
			recordsByNidn[a.Nidn] = append(recordsByNidn[a.Nidn], rec)
		}
	}

	for _, iz := range izins {
		rec := domain.RecordItem{
			ID:      iz.ID,
			Tanggal: iz.TanggalPengajuan,
			Type:    "izin",
			Info: map[string]interface{}{
				"tujuan": iz.Tujuan,
			},
		}
		if iz.Nip != "" {
			recordsByNip[iz.Nip] = append(recordsByNip[iz.Nip], rec)
		} else if iz.Nidn != "" {
			recordsByNidn[iz.Nidn] = append(recordsByNidn[iz.Nidn], rec)
		}
	}

	for _, c := range cutis {
		start, _ := time.Parse("2006-01-02", c.TanggalMulai)
		end, _ := time.Parse("2006-01-02", c.TanggalSelesai)
		if end.Before(start) {
			end = start
		}
		for cur := start; !cur.After(end); cur = cur.AddDate(0, 0, 1) {
			rec := domain.RecordItem{
				ID:      c.ID,
				Tanggal: cur.Format("2006-01-02"),
				Type:    "cuti",
				Info: map[string]interface{}{
					"alasan": c.Alasan,
					"status": c.Status,
				},
			}
			if c.Nip != "" {
				recordsByNip[c.Nip] = append(recordsByNip[c.Nip], rec)
			} else if c.Nidn != "" {
				recordsByNidn[c.Nidn] = append(recordsByNidn[c.Nidn], rec)
			}
		}
	}

	for _, sp := range sppds {
		start, _ := time.Parse("2006-01-02", sp.TanggalBerangkat)
		end, _ := time.Parse("2006-01-02", sp.TanggalKembali)
		if end.Before(start) {
			end = start
		}
		for cur := start; !cur.After(end); cur = cur.AddDate(0, 0, 1) {
			rec := domain.RecordItem{
				ID:      sp.ID,
				Tanggal: cur.Format("2006-01-02"),
				Type:    "sppd",
				Info: map[string]interface{}{
					"maksud": sp.Keterangan,
					"tujuan": sp.Tujuan,
				},
			}
			if sp.Nip != "" {
				recordsByNip[sp.Nip] = append(recordsByNip[sp.Nip], rec)
			} else if sp.Nidn != "" {
				recordsByNidn[sp.Nidn] = append(recordsByNidn[sp.Nidn], rec)
			}

			for _, member := range anggotaBySppdID[sp.ID] {
				if member.Nip != "" {
					recordsByNip[member.Nip] = append(recordsByNip[member.Nip], rec)
				} else if member.Nidn != "" {
					recordsByNidn[member.Nidn] = append(recordsByNidn[member.Nidn], rec)
				}
			}
		}
	}

	for _, u := range upacaras {
		rec := domain.RecordItem{
			ID:      u.ID,
			Tanggal: u.Tanggal,
			Type:    "upacara",
			Info: map[string]interface{}{
				"tanggal": u.Tanggal,
			},
		}
		if u.Nip != "" {
			recordsByNip[u.Nip] = append(recordsByNip[u.Nip], rec)
		} else if u.Nidn != "" {
			recordsByNidn[u.Nidn] = append(recordsByNidn[u.Nidn], rec)
		}
	}

	var results []domain.LaporanPenggunaMerged
	for _, p := range pegawais {
		kode := "NA"
		userTypeVal := "NA"
		if p.Nidn != "" {
			kode = p.Nidn
			userTypeVal = "dosen"
		} else if p.Nip != "" {
			kode = p.Nip
			userTypeVal = "pegawai"
		}

		recs := recordsByNip[p.Nip]
		if len(recs) == 0 && p.Nidn != "" {
			recs = recordsByNidn[p.Nidn]
		}
		if recs == nil {
			recs = []domain.RecordItem{}
		}

		results = append(results, domain.LaporanPenggunaMerged{
			Kode:     kode,
			Pengguna: p,
			Type:     userTypeVal,
			Records:  recs,
		})
	}

	return results, nil
}

func (r *ReportRepository) GetFlatLaporanMergedParallel(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string, userType string) ([]domain.FlatRecordItem, error) {
	merged, err := r.GetLaporanMergedParallel(ctx, tanggalMulai, tanggalAkhir, nip, nidn, userType)
	if err != nil {
		return nil, err
	}

	var flatList []domain.FlatRecordItem
	for _, m := range merged {
		for _, rec := range m.Records {
			flatList = append(flatList, domain.FlatRecordItem{
				ID:       rec.ID,
				Tanggal:  rec.Tanggal,
				Type:     rec.Type,
				Info:     rec.Info,
				Pengguna: m.Pengguna,
			})
		}
	}

	return flatList, nil
}

func (r *ReportRepository) CalculateReport(ctx context.Context) (map[string]interface{}, error) {
	// Query unique employees from local activity tables to bypass view_pegawai (connect_m_dosen, connect_e_pribadi, connect_n_pribadi queries)
	type employee struct {
		Nip      string `gorm:"column:nip"`
		Nidn     string `gorm:"column:nidn"`
		Nama     string `gorm:"column:nama"`
		Fakultas string `gorm:"column:fakultas"`
		Prodi    string `gorm:"column:prodi"`
		Unit     string `gorm:"column:unit"`
	}
	empSet := make(map[employee]bool)

	var eAbsen []employee
	r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}).Select("DISTINCT nip, nidn, nama_pegawai AS nama, fakultas, prodi, unit").Find(&eAbsen)
	for _, e := range eAbsen {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eIzin []employee
	r.db.WithContext(ctx).Model(&permissionDomain.Izin{}).Select("DISTINCT nip, nidn, nama_pemohon AS nama, fakultas, prodi, unit").Find(&eIzin)
	for _, e := range eIzin {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eCuti []employee
	r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}).Select("DISTINCT nip, nidn, nama_pemohon AS nama, fakultas, prodi, unit").Find(&eCuti)
	for _, e := range eCuti {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eSppd []employee
	r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}).Select("DISTINCT nip, nidn, nama_pemohon AS nama, fakultas, prodi, unit").Find(&eSppd)
	for _, e := range eSppd {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eSppdAnggota []employee
	r.db.WithContext(ctx).Model(&sppdDomain.SppdAnggota{}).Select("DISTINCT nip, nidn, nama, fakultas, prodi, unit").Find(&eSppdAnggota)
	for _, e := range eSppdAnggota {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eUpacara []employee
	r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}).Select("DISTINCT nip, nidn, nama, fakultas, prodi, unit").Find(&eUpacara)
	for _, e := range eUpacara {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var pegawais []accountDomain.Pegawai
	for emp := range empSet {
		nipVal := strings.TrimSpace(emp.Nip)
		nidnVal := strings.TrimSpace(emp.Nidn)
		if (nipVal == "" || nipVal == "-" || nipVal == "--") && (nidnVal == "" || nidnVal == "-" || nidnVal == "--") {
			continue
		}

		unitVal := emp.Unit
		fakultasVal := emp.Fakultas
		prodiVal := emp.Prodi

		pegawais = append(pegawais, accountDomain.Pegawai{
			Nip:       nipVal,
			Nidn:      nidnVal,
			Nama:      emp.Nama,
			UnitKerja: &unitVal,
			Unit:      &unitVal,
			Fakultas:  &fakultasVal,
			Prodi:     &prodiVal,
		})
	}

	var writeMu sync.Mutex

	var months []string
	// Find distinct months across all activity tables filtered by status
	var mAbsen, mIzin, mCuti, mSppd, mUpacara []string
	qAbsen := r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}).Where("absen_masuk IS NOT NULL")
	qIzin := r.db.WithContext(ctx).Model(&permissionDomain.Izin{}).Where("status IN ('terima sdm', 'Disetujui')")
	qCuti := r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}).Where("status IN ('terima sdm', 'Disetujui')")
	qSppd := r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}).Where("status IN ('terima sdm', 'Disetujui')")
	qUpacara := r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{})

	qAbsen.Select("DISTINCT DATE_FORMAT(tanggal, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal, '%Y-%m')", &mAbsen)
	qIzin.Select("DISTINCT DATE_FORMAT(tanggal_pengajuan, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal_pengajuan, '%Y-%m')", &mIzin)
	qCuti.Select("DISTINCT DATE_FORMAT(tanggal_mulai, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal_mulai, '%Y-%m')", &mCuti)
	qSppd.Select("DISTINCT DATE_FORMAT(tanggal_berangkat, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal_berangkat, '%Y-%m')", &mSppd)
	qUpacara.Select("DISTINCT DATE_FORMAT(tanggal, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal, '%Y-%m')", &mUpacara)

	monthSet := make(map[string]bool)
	for _, list := range [][]string{mAbsen, mIzin, mCuti, mSppd, mUpacara} {
		for _, m := range list {
			if m != "" {
				monthSet[m] = true
			}
		}
	}

	if len(monthSet) == 0 {
		monthSet[time.Now().Format("2006-01")] = true
	}

	for m := range monthSet {
		months = append(months, m)
	}

	now := time.Now()
	var totalRecordsProcessed int64

	for _, mStr := range months {
		loc := time.Local
		refDate, err := time.ParseInLocation("2006-01", mStr, loc)
		if err != nil {
			continue
		}

		// 1. Versi 1 (Calendar Month: 1st to last day)
		v1Start := time.Date(refDate.Year(), refDate.Month(), 1, 0, 0, 0, 0, loc)
		v1End := time.Date(refDate.Year(), refDate.Month()+1, 0, 0, 0, 0, 0, loc)
		v1Key := v1Start.Format("2006-01")

		// 2. Versi 2 (Cutoff Period: 16th of prev month to 15th of curr month)
		v2Start := time.Date(refDate.Year(), refDate.Month()-1, 16, 0, 0, 0, 0, loc)
		v2End := time.Date(refDate.Year(), refDate.Month(), 15, 0, 0, 0, 0, loc)
		v2Key := refDate.Format("2006-01")

		var cLiburV1, cLiburV2 int64
		r.db.WithContext(ctx).Table("master_libur").
			Where("tanggal >= ? AND tanggal <= ? AND is_national_holiday = 1", v1Start.Format("2006-01-02"), v1End.Format("2006-01-02")).
			Count(&cLiburV1)

		r.db.WithContext(ctx).Table("master_libur").
			Where("tanggal >= ? AND tanggal <= ? AND is_national_holiday = 1", v2Start.Format("2006-01-02"), v2End.Format("2006-01-02")).
			Count(&cLiburV2)

		type job struct {
			p accountDomain.Pegawai
		}
		jobs := make(chan job, len(pegawais))
		for _, p := range pegawais {
			jobs <- job{p: p}
		}
		close(jobs)

		var wgWorkers sync.WaitGroup
		numWorkers := 10 // Safe concurrent database workers
		for w := 1; w <= numWorkers; w++ {
			wgWorkers.Add(1)
			go func() {
				defer wgWorkers.Done()
				for j := range jobs {
					p := j.p
					nipVal := strings.TrimSpace(p.Nip)
					nidnVal := strings.TrimSpace(p.Nidn)
					if nipVal == "" && nidnVal == "" {
						continue
					}

					var cMasukV1, cIzinV1, cCutiV1, cSppdV1, cUpacaraV1 int64
					var cMasukV2, cIzinV2, cCutiV2, cSppdV2, cUpacaraV2 int64

					var wgCount sync.WaitGroup
					wgCount.Add(10)

					// Count V1 Calendar in parallel
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}), nipVal, nidnVal).
							Where("tanggal >= ? AND tanggal <= ? AND absen_masuk IS NOT NULL", v1Start.Format("2006-01-02"), v1End.Format("2006-01-02")).
							Count(&cMasukV1)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&permissionDomain.Izin{}), nipVal, nidnVal).
							Where("tanggal_pengajuan >= ? AND tanggal_pengajuan <= ? AND status IN ('terima sdm', 'Disetujui')", v1Start.Format("2006-01-02"), v1End.Format("2006-01-02")).
							Count(&cIzinV1)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}), nipVal, nidnVal).
							Where("tanggal_mulai <= ? AND tanggal_akhir >= ? AND status IN ('terima sdm', 'Disetujui')", v1End.Format("2006-01-02"), v1Start.Format("2006-01-02")).
							Count(&cCutiV1)
					}()
					go func() {
						defer wgCount.Done()
						buildSppdUserWhere(r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}), nipVal, nidnVal).
							Where("tanggal_berangkat <= ? AND tanggal_kembali >= ? AND status IN ('terima sdm', 'Disetujui')", v1End.Format("2006-01-02"), v1Start.Format("2006-01-02")).
							Count(&cSppdV1)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}), nipVal, nidnVal).
							Where("tanggal >= ? AND tanggal <= ?", v1Start.Format("2006-01-02"), v1End.Format("2006-01-02")).
							Count(&cUpacaraV1)
					}()

					// Count V2 Cutoff in parallel
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}), nipVal, nidnVal).
							Where("tanggal >= ? AND tanggal <= ? AND absen_masuk IS NOT NULL", v2Start.Format("2006-01-02"), v2End.Format("2006-01-02")).
							Count(&cMasukV2)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&permissionDomain.Izin{}), nipVal, nidnVal).
							Where("tanggal_pengajuan >= ? AND tanggal_pengajuan <= ? AND status IN ('terima sdm', 'Disetujui')", v2Start.Format("2006-01-02"), v2End.Format("2006-01-02")).
							Count(&cIzinV2)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}), nipVal, nidnVal).
							Where("tanggal_mulai <= ? AND tanggal_akhir >= ? AND status IN ('terima sdm', 'Disetujui')", v2End.Format("2006-01-02"), v2Start.Format("2006-01-02")).
							Count(&cCutiV2)
					}()
					go func() {
						defer wgCount.Done()
						buildSppdUserWhere(r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}), nipVal, nidnVal).
							Where("tanggal_berangkat <= ? AND tanggal_kembali >= ? AND status IN ('terima sdm', 'Disetujui')", v2End.Format("2006-01-02"), v2Start.Format("2006-01-02")).
							Count(&cSppdV2)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}), nipVal, nidnVal).
							Where("tanggal >= ? AND tanggal <= ?", v2Start.Format("2006-01-02"), v2End.Format("2006-01-02")).
							Count(&cUpacaraV2)
					}()

					wgCount.Wait()

					namaVal := p.Nama
					unitVal := ""
					if p.UnitKerja != nil && *p.UnitKerja != "" {
						unitVal = *p.UnitKerja
					} else if p.Unit != nil {
						unitVal = *p.Unit
					}
					fakultasVal := ""
					if p.Fakultas != nil {
						fakultasVal = *p.Fakultas
					}
					prodiVal := ""
					if p.Prodi != nil {
						prodiVal = *p.Prodi
					}

					itemV1 := domain.RekapLaporanBulanan{
						Nip:          nipVal,
						Nidn:         nidnVal,
						Nama:         namaVal,
						Unit:         unitVal,
						Fakultas:     fakultasVal,
						Prodi:        prodiVal,
						PeriodeType:  domain.PeriodeCalendar,
						PeriodeKey:   v1Key,
						TanggalMulai: v1Start.Format("2006-01-02"),
						TanggalAkhir: v1End.Format("2006-01-02"),
						TotalMasuk:   int(cMasukV1),
						TotalIzin:    int(cIzinV1),
						TotalCuti:    int(cCutiV1),
						TotalSppd:    int(cSppdV1),
						TotalUpacara: int(cUpacaraV1),
						TotalLibur:   int(cLiburV1),
						UpdatedAt:    &now,
					}
					conflictCols := []clause.Column{{Name: "nip"}, {Name: "nidn"}, {Name: "periode_type"}, {Name: "periode_key"}}

					writeMu.Lock()
					r.db.WithContext(ctx).Clauses(clause.OnConflict{
						Columns:   conflictCols,
						UpdateAll: true,
					}).Create(&itemV1)

					itemV2 := domain.RekapLaporanBulanan{
						Nip:          nipVal,
						Nidn:         nidnVal,
						Nama:         namaVal,
						Unit:         unitVal,
						Fakultas:     fakultasVal,
						Prodi:        prodiVal,
						PeriodeType:  domain.PeriodeCutoff,
						PeriodeKey:   v2Key,
						TanggalMulai: v2Start.Format("2006-01-02"),
						TanggalAkhir: v2End.Format("2006-01-02"),
						TotalMasuk:   int(cMasukV2),
						TotalIzin:    int(cIzinV2),
						TotalCuti:    int(cCutiV2),
						TotalSppd:    int(cSppdV2),
						TotalUpacara: int(cUpacaraV2),
						TotalLibur:   int(cLiburV2),
						UpdatedAt:    &now,
					}
					r.db.WithContext(ctx).Clauses(clause.OnConflict{
						Columns:   conflictCols,
						UpdateAll: true,
					}).Create(&itemV2)
					writeMu.Unlock()

					atomic.AddInt64(&totalRecordsProcessed, 2)
				}
			}()
		}
		wgWorkers.Wait()
	}

	return map[string]interface{}{
		"status":                  "success",
		"message":                 "Kalkulasi ulang laporan versi 1 dan versi 2 untuk seluruh data pegawai dan bulan telah selesai",
		"total_bulan_dikalkulasi": len(months),
		"total_pegawai":           len(pegawais),
		"total_rekap_records":     int(totalRecordsProcessed),
		"daftar_bulan":            months,
	}, nil
}

func buildUserWhere(db *gorm.DB, nip, nidn string) *gorm.DB {
	if nip != "" && nidn != "" {
		return db.Where("(nip = ? OR nidn = ?)", nip, nidn)
	} else if nip != "" {
		return db.Where("nip = ?", nip)
	} else if nidn != "" {
		return db.Where("nidn = ?", nidn)
	}
	return db.Where("1 = 0")
}

func buildSppdUserWhere(db *gorm.DB, nip, nidn string) *gorm.DB {
	if nip != "" && nidn != "" {
		return db.Where("(nip = ? OR nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ? OR nidn = ?))", nip, nidn, nip, nidn)
	} else if nip != "" {
		return db.Where("(nip = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ?))", nip, nip)
	} else if nidn != "" {
		return db.Where("(nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nidn = ?))", nidn, nidn)
	}
	return db.Where("1 = 0")
}
