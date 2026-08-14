package storage

import (
	"log"
	"os"
	"strings"
	"sync"
)

type StorageConfig struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	UseSSL    bool
	Region    string
}

var (
	GlobalStorageService IStorageService
	storageOnce          sync.Once
)

// InitStorageService initializes the storage adapter based on STORAGE_CONNECTOR env.
// Supported connectors:
// - "storageSvcS3" / "s3" -> Real S3/MinIO Object Storage
// - "storageSvcMoq" / "moq" / "mock" -> Mock Storage in-memory & local disk
func InitStorageService() IStorageService {
	storageOnce.Do(func() {
		connector := os.Getenv("STORAGE_CONNECTOR")

		lower := strings.ToLower(strings.TrimSpace(connector))
		switch {
		case lower == "storagesvcmoq":
			log.Printf("[StorageAdapter] Active Connector: storageSvcMoq (Mock Storage Driver)")
			GlobalStorageService = NewStorageSvcMoq()
		default:
			log.Printf("[StorageAdapter] Active Connector: storageSvcS3 (S3/MinIO Storage Driver)")
			GlobalStorageService = NewStorageSvcS3()
		}
	})

	return GlobalStorageService
}
