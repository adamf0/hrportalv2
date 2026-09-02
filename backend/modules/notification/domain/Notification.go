package domain

import (
	"time"

	common "hrportal_backend/common/domain"
)

type NotificationModel struct {
	ID             uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	NotificationID string    `gorm:"column:notification_id;uniqueIndex" json:"notification_id"`
	TargetNip      string    `gorm:"column:target_nip;index" json:"target_nip"`
	TargetNidn     string    `gorm:"column:target_nidn;index" json:"target_nidn"`
	Title          string    `gorm:"column:title" json:"title"`
	Body           string    `gorm:"column:body" json:"body"`
	Type           string    `gorm:"column:type" json:"type"`
	Status         string    `gorm:"column:status;index" json:"status"` // "pending", "sent", "failed", "circuit_broken"
	RetryCount     int       `gorm:"column:retry_count;default:0" json:"retry_count"`
	ErrorMessage   string    `gorm:"column:error_message" json:"error_message"`
	PayloadJSON    string    `gorm:"column:payload_json;type:text" json:"payload_json"`
	CreatedAt      time.Time `gorm:"column:created_at;index" json:"created_at"`
	UpdatedAt      time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (NotificationModel) TableName() string {
	return "notifications"
}

type FcmTokenModel struct {
	ID        uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	Nip       string    `gorm:"column:nip;uniqueIndex" json:"nip"`
	Nidn      string    `gorm:"column:nidn;uniqueIndex" json:"nidn"`
	FcmToken  string    `gorm:"column:fcm_token;type:text" json:"fcm_token"`
	IsSdm     bool      `gorm:"column:is_sdm;default:false" json:"is_sdm"`
	UpdatedAt time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (FcmTokenModel) TableName() string {
	return "user_fcm_tokens"
}

func NotificationError(msg string) common.Error {
	return common.FailureError("Notification.Error", msg)
}
