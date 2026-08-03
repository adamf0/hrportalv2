package domain

type UserInfo struct {
	Sid          string `json:"sid"`
	Source       string `json:"source"`
	Fakultas     string `json:"fakultas"`
	Prodi        string `json:"prodi"`
	KodeFakultas string `json:"kode_fakultas"`
	KodeProdi    string `json:"kode_prodi"`
	Unit         string `json:"unit"`
	Level        string `json:"level"`
	Name         string `json:"name"`
	Email        string `json:"email"`
	Nip          string `json:"nip"`
	Nidn         string `json:"nidn"`
}
