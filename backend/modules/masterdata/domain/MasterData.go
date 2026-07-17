package domain

type Fakultas struct {
	ID   uint   `gorm:"primaryKey;column:id" json:"id"`
	Kode string `gorm:"column:kode" json:"kode"`
	Nama string `gorm:"column:nama" json:"nama"`
}

func (Fakultas) TableName() string {
	return "connect_m_fakultas"
}

type Prodi struct {
	ID         uint   `gorm:"primaryKey;column:id" json:"id"`
	FakultasID uint   `gorm:"column:fakultas_id" json:"fakultas_id"`
	Kode       string `gorm:"column:kode" json:"kode"`
	Nama       string `gorm:"column:nama" json:"nama"`
}

func (Prodi) TableName() string {
	return "connect_r_prodi"
}

type JenisCuti struct {
	ID        uint   `gorm:"primaryKey;column:id" json:"id"`
	Nama      string `gorm:"column:nama" json:"nama"`
	MaksHari  int    `gorm:"column:maks_hari" json:"maks_hari"`
	Deskripsi string `gorm:"column:deskripsi" json:"deskripsi"`
}

func (JenisCuti) TableName() string {
	return "jenis_cuti"
}

type JenisIzin struct {
	ID   uint   `gorm:"primaryKey;column:id" json:"id"`
	Nama string `gorm:"column:nama" json:"nama"`
}

func (JenisIzin) TableName() string {
	return "jenis_izin"
}

type JenisSppd struct {
	ID   uint   `gorm:"primaryKey;column:id" json:"id"`
	Nama string `gorm:"column:nama" json:"nama"`
}

func (JenisSppd) TableName() string {
	return "jenis_sppd"
}
