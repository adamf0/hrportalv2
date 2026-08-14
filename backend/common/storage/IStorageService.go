package storage

import (
	"context"
	"crypto/rand"
	"fmt"
	"io"
	"strings"
	"time"
)

// IStorageService defines the common interface for Storage Adapters
type IStorageService interface {
	GeneratePresignedUploadURL(ctx context.Context, storageType string, filename string, contentType string) (uploadURL string, objectKey string, err error)
	GeneratePresignedReadURL(ctx context.Context, storageType string, objectKey string, expiry time.Duration) (readURL string, err error)
	GetObjectStream(ctx context.Context, storageType string, objectKey string) (io.ReadCloser, string, error)
	EnsureBucketExists(ctx context.Context, bucketName string)
	SaveMockObject(storageType string, objectKey string, contentType string, data []byte) error
}

func GetBucketName(storageType string) string {
	lower := strings.ToLower(strings.TrimSpace(storageType))
	switch {
	case strings.Contains(lower, "cuti"):
		return "cuti"
	case strings.Contains(lower, "izin"):
		return "izin"
	case strings.Contains(lower, "sppd"):
		return "sppd"
	default:
		if lower != "" {
			return lower
		}
		return "cuti"
	}
}

func generateRandomHex(n int) string {
	bytes := make([]byte, n)
	if _, err := rand.Read(bytes); err != nil {
		return fmt.Sprintf("%d", time.Now().UnixNano())
	}
	return fmt.Sprintf("%x", bytes)
}
