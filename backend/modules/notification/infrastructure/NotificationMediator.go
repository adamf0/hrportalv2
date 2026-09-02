package infrastructure

import (
	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/notification/application/CreateNotification"

	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/gorm"
)

func RegisterModuleNotification(db *gorm.DB) error {
	createHandler := CreateNotification.NewCreateNotificationCommandHandler(db)
	err := mediatr.RegisterRequestHandler[*CreateNotification.CreateNotificationCommand, common.ResultValue[bool]](createHandler)
	if err != nil {
		return err
	}
	return nil
}
