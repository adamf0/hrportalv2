package domain

type CalendarItem struct {
	Nidn    string `json:"nidn"`
	Nip     string `json:"nip"`
	Tanggal string `json:"tanggal"`
	Type    string `json:"type"`    // "cuti", "izin", "sppd", "absen"
	Catatan string `json:"catatan"`
	Status  string `json:"status"`   // "acc", "tolak", "menunggu"
}
