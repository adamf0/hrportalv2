package domain

type Fakultas struct {
	KodeFakultas string `gorm:"primaryKey;column:kode_fakultas" json:"kode_fakultas"`
	NamaFakultas string `gorm:"column:nama_fakultas" json:"nama_fakultas"`

	ID   string `gorm:"-" json:"id"`
	Kode string `gorm:"-" json:"kode"`
	Nama string `gorm:"-" json:"nama"`
}

func (Fakultas) TableName() string {
	return "connect_m_fakultas"
}

type Prodi struct {
	KodeProdi    string `gorm:"primaryKey;column:kode_prodi" json:"kode_prodi"`
	NamaProdi    string `gorm:"column:nama_prodi" json:"nama_prodi"`
	KodeFakultas string `gorm:"column:kode_fakultas" json:"kode_fakultas"`
	NamaFakultas string `gorm:"column:nama_fakultas" json:"nama_fakultas"`

	ID         string `gorm:"-" json:"id"`
	FakultasID string `gorm:"-" json:"fakultas_id"`
	Kode       string `gorm:"-" json:"kode"`
	Nama       string `gorm:"-" json:"nama"`
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

type Verifikator struct {
	Nip        string `gorm:"column:nip" json:"nip"`
	Nama       string `gorm:"column:nama" json:"nama"`
	Struktural string `gorm:"column:struktural" json:"struktural"`
}

func (Verifikator) TableName() string {
	return "connect_payroll_m_pegawai"
}

