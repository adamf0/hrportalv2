package domain

import (
	"context"
)

type IAttendanceRepository interface {
	FindByNipAndTanggal(ctx context.Context, nip string, nidn string, tanggal string) (*Absen, error)
	CreateAbsen(ctx context.Context, absen *Absen) error
	UpdateAbsen(ctx context.Context, absen *Absen) error
	GetHistoryByNip(ctx context.Context, nip string, nidn string) ([]Absen, error)
	CreateKlaim(ctx context.Context, klaim *KlaimAbsen) error

	FindByNipAndTanggalUpacara(ctx context.Context, nip string, nidn string, tanggal string) (*AbsenUpacara, error)
	CreateAbsenUpacara(ctx context.Context, upacara *AbsenUpacara) error
	DeleteEmptyAbsen(ctx context.Context) (int64, error)
}
