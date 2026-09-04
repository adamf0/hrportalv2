package helper

import (
	"context"
	"strings"

	"gorm.io/gorm"
)

type PegawaiIDInfo struct {
	Nip      string `gorm:"column:nip"`
	NidnNitk string `gorm:"column:nidn_nitk"`
	Nuptk    string `gorm:"column:nuptk"`
}

// ResolveVerifikatorIDs mencari seluruh identifier verifikator (nip, nidn_nitk, nuptk)
// dari tabel unpak_newsimpeg.pegawais berdasarkan nip atau nidn yang diberikan.
func ResolveVerifikatorIDs(ctx context.Context, db *gorm.DB, nip string, nidn string) []string {
	var ids []string
	seen := make(map[string]bool)

	addID := func(val string) {
		val = strings.TrimSpace(val)
		if val != "" && !seen[val] {
			seen[val] = true
			ids = append(ids, val)
		}
	}

	addID(nip)
	addID(nidn)

	if db == nil || (nip == "" && nidn == "") {
		return ids
	}

	var pInfo PegawaiIDInfo
	// Kueri ke unpak_newsimpeg.pegawais
	err := db.WithContext(ctx).Table("unpak_newsimpeg.pegawais").
		Select("nip, nidn_nitk, nuptk").
		Where("(nip IS NOT NULL AND nip != '' AND (nip = ? OR nip = ?)) OR (nidn_nitk IS NOT NULL AND nidn_nitk != '' AND (nidn_nitk = ? OR nidn_nitk = ?)) OR (nuptk IS NOT NULL AND nuptk != '' AND (nuptk = ? OR nuptk = ?))", nip, nidn, nip, nidn, nip, nidn).
		First(&pInfo).Error

	if err != nil {
		// Fallback ke tabel pegawais tanpa prefix database
		_ = db.WithContext(ctx).Table("pegawais").
			Select("nip, nidn_nitk, nuptk").
			Where("(nip IS NOT NULL AND nip != '' AND (nip = ? OR nip = ?)) OR (nidn_nitk IS NOT NULL AND nidn_nitk != '' AND (nidn_nitk = ? OR nidn_nitk = ?)) OR (nuptk IS NOT NULL AND nuptk != '' AND (nuptk = ? OR nuptk = ?))", nip, nidn, nip, nidn, nip, nidn).
			First(&pInfo).Error
	}

	addID(pInfo.Nip)
	addID(pInfo.NidnNitk)
	addID(pInfo.Nuptk)

	return ids
}
