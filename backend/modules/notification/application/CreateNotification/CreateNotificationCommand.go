package CreateNotification

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/notification/domain"

	"gorm.io/gorm"
)

type CreateNotificationCommand struct {
	TargetNips  []string          `json:"target_nips"`
	TargetNidns []string          `json:"target_nidns"`
	Title       string            `json:"title"`
	Body        string            `json:"body"`
	Type        string            `json:"type"`
	Payload     map[string]string `json:"payload"`
}

type CreateNotificationCommandHandler struct {
	db *gorm.DB
}

func NewCreateNotificationCommandHandler(db *gorm.DB) *CreateNotificationCommandHandler {
	return &CreateNotificationCommandHandler{db: db}
}

func (h *CreateNotificationCommandHandler) Handle(ctx context.Context, cmd *CreateNotificationCommand) (common.ResultValue[bool], error) {
	if h.db == nil {
		log.Println("[Notification Command Error] DB connection is nil")
		return common.FailureValue[bool](domain.NotificationError("Database connection is nil")), nil
	}

	payloadBytes, _ := json.Marshal(cmd.Payload)
	payloadJSON := string(payloadBytes)
	now := time.Now()

	for _, nip := range cmd.TargetNips {
		if nip == "" {
			continue
		}
		notifID := fmt.Sprintf("%s-%s-%d", cmd.Type, nip, now.UnixNano())
		model := domain.NotificationModel{
			NotificationID: notifID,
			TargetNip:      nip,
			TargetNidn:     "",
			Title:          cmd.Title,
			Body:           cmd.Body,
			Type:           cmd.Type,
			Status:         "pending",
			RetryCount:     0,
			PayloadJSON:    payloadJSON,
			CreatedAt:      now,
			UpdatedAt:      now,
		}

		if err := h.db.Create(&model).Error; err != nil {
			log.Printf("[Notification Command Error] Failed to insert notification %s into DB: %v", notifID, err)
		} else {
			log.Printf("[Notification Command] Created notification ID %d (%s) for NIP %s [Status: PENDING]", model.ID, notifID, nip)
		}
	}

	for _, nidn := range cmd.TargetNidns {
		if nidn == "" {
			continue
		}
		notifID := fmt.Sprintf("%s-%s-%d", cmd.Type, nidn, now.UnixNano())
		model := domain.NotificationModel{
			NotificationID: notifID,
			TargetNip:      "",
			TargetNidn:     nidn,
			Title:          cmd.Title,
			Body:           cmd.Body,
			Type:           cmd.Type,
			Status:         "pending",
			RetryCount:     0,
			PayloadJSON:    payloadJSON,
			CreatedAt:      now,
			UpdatedAt:      now,
		}

		if err := h.db.Create(&model).Error; err != nil {
			log.Printf("[Notification Command Error] Failed to insert notification %s into DB: %v", notifID, err)
		} else {
			log.Printf("[Notification Command] Created notification ID %d (%s) for NIDN %s [Status: PENDING]", model.ID, notifID, nidn)
		}
	}

	return common.SuccessValue(true), nil
}
