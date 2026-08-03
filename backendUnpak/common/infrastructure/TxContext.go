package infrastructure

import (
	"context"

	"gorm.io/gorm"
)

type txContextKey struct{}

var TxKey = txContextKey{}

// GetTx returns the transaction from the context if it exists, otherwise returning the fallback DB.
func GetTx(ctx context.Context, fallback *gorm.DB) *gorm.DB {
	if tx, ok := ctx.Value(TxKey).(*gorm.DB); ok {
		return tx.WithContext(ctx)
	}
	return fallback.WithContext(ctx)
}
