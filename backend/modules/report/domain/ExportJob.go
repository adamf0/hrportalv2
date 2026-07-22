package domain

import "time"

type ExportJob struct {
	ID           uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	TaskID       string    `gorm:"column:task_id;type:varchar(64);uniqueIndex" json:"task_id"`
	TanggalMulai string    `gorm:"column:tanggal_mulai;type:varchar(20)" json:"tanggal_mulai"`
	TanggalAkhir string    `gorm:"column:tanggal_akhir;type:varchar(20)" json:"tanggal_akhir"`
	Status       string    `gorm:"column:status;type:varchar(30)" json:"status"` // pending, processing, completed, failed
	Progress     int       `gorm:"column:progress" json:"progress"`
	FilePath     string    `gorm:"column:file_path;type:varchar(255)" json:"file_path"`
	ErrorMessage string    `gorm:"column:error_message;type:text" json:"error_message"`
	CreatedAt    time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt    time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (ExportJob) TableName() string {
	return "export_jobs"
}
