package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type User struct {
	common.Entity
	ID            uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	Name          string     `gorm:"column:name" json:"name"`
	Email         string     `gorm:"column:email" json:"email"`
	Nip           string     `gorm:"column:nip" json:"nip"`
	Nidn          string     `gorm:"column:nidn" json:"nidn"`
	Password      string     `gorm:"column:password" json:"-"`
	RememberToken *string    `gorm:"column:remember_token" json:"-"`
	CreatedAt     *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt     *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (User) TableName() string {
	return "users"
}

type Pegawai struct {
	ID        uint    `gorm:"primaryKey;column:id" json:"id"`
	Nip       string  `gorm:"column:nip" json:"nip"`
	Nidn      string  `gorm:"column:nidn" json:"nidn"`
	Nama      string  `gorm:"column:nama" json:"nama"`
	Email     *string `gorm:"column:email" json:"email"`
	UnitKerja *string `gorm:"column:unit_kerja" json:"unit_kerja"`
	Jabatan   *string `gorm:"column:jabatan" json:"jabatan"`
}

func (Pegawai) TableName() string {
	return "view_pegawai"
}
