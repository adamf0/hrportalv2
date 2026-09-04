package domain

import (
	"context"
)

type SlipGaji struct {
	IDPublish    int64   `gorm:"column:idpublish;primaryKey" json:"idpublish"`
	NIP          string  `gorm:"column:nip" json:"nip"`
	NoMesin      string  `gorm:"column:no_mesin" json:"no_mesin"`
	Nama         string  `gorm:"column:nama" json:"nama"`
	Prodi        string  `gorm:"column:prodi" json:"prodi"`
	Status       string  `gorm:"column:status" json:"status"`
	Jafung       string  `gorm:"column:jafung" json:"jafung"`
	GajiPokok    float64 `gorm:"column:gaji_pokok" json:"gaji_pokok"`
	TKeluarga    float64 `gorm:"column:tkeluarga" json:"tkeluarga"`
	TAnak        float64 `gorm:"column:tanak" json:"tanak"`
	TPangan      float64 `gorm:"column:tpangan" json:"tpangan"`
	TStruktural  float64 `gorm:"column:tstruktural" json:"tstruktural"`
	TFungsional  float64 `gorm:"column:tfungsional" json:"tfungsional"`
	Mengajar     float64 `gorm:"column:mengajar" json:"mengajar"`
	NonRegular   float64 `gorm:"column:nonregular" json:"nonregular"`
	D3Regular    float64 `gorm:"column:D3regular" json:"D3regular"`
	D3NonRegular float64 `gorm:"column:D3nonregular" json:"D3nonregular"`
	Pascasarjana float64 `gorm:"column:pascasarjana" json:"pascasarjana"`
	Transpot     float64 `gorm:"column:transpot" json:"transpot"`
	TKhusus      float64 `gorm:"column:tkhusus" json:"tkhusus"`
	BPJS         float64 `gorm:"column:bpjs" json:"bpjs"`
	AstekY       float64 `gorm:"column:astekY" json:"astekY"`
	DPLKY        float64 `gorm:"column:dplkY" json:"dplkY"`
	GajiKotor    float64 `gorm:"column:gajikotor" json:"gajikotor"`
	AstekP       float64 `gorm:"column:astekP" json:"astekP"`
	DPLKP        float64 `gorm:"column:dplkP" json:"dplkP"`
	PKoperasi    float64 `gorm:"column:pkoperasi" json:"pkoperasi"`
	PYayasan     float64 `gorm:"column:pyayasan" json:"pyayasan"`
	PZakat       float64 `gorm:"column:pzakat" json:"pzakat"`
	GajiBersih   float64 `gorm:"column:gajibersih" json:"gajibersih"`
	Bulan        string  `gorm:"column:bulan" json:"bulan"`
	Tahun        string  `gorm:"column:tahun" json:"tahun"`
}

func (SlipGaji) TableName() string {
	return "payroll_publishb"
}

func NamaBulan(number int) string {
	switch number {
	case 1:
		return "Januari"
	case 2:
		return "Februari"
	case 3:
		return "Maret"
	case 4:
		return "April"
	case 5:
		return "Mei"
	case 6:
		return "Juni"
	case 7:
		return "Juli"
	case 8:
		return "Agustus"
	case 9:
		return "September"
	case 10:
		return "Oktober"
	case 11:
		return "November"
	case 12:
		return "Desember"
	default:
		return ""
	}
}

type IPayrollRepository interface {
	GetSlipGaji(ctx context.Context, tahunStr string, bulanNum int, bulanStr string, namaBulanStr string, nip string) (*SlipGaji, error)
}
