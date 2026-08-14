package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

type mockFileItem struct {
	Data        []byte
	ContentType string
	UpdatedAt   time.Time
}

type StorageSvcMoq struct {
	storageRoot string
	inMemory    map[string]*mockFileItem
	mu          sync.RWMutex
}

func NewStorageSvcMoq() *StorageSvcMoq {
	mockRoot := filepath.Join("exports", "mock_storage")
	_ = os.MkdirAll(mockRoot, 0755)

	log.Println("[storageSvcMoq] Initialized Mock Storage Connector (In-Memory + Local Directory: exports/mock_storage)")

	return &StorageSvcMoq{
		storageRoot: mockRoot,
		inMemory:    make(map[string]*mockFileItem),
	}
}

func (m *StorageSvcMoq) EnsureBucketExists(ctx context.Context, bucketName string) {
	bucketDir := filepath.Join(m.storageRoot, bucketName)
	_ = os.MkdirAll(bucketDir, 0755)
}

func (m *StorageSvcMoq) GeneratePresignedUploadURL(ctx context.Context, storageType string, filename string, contentType string) (uploadURL string, objectKey string, err error) {
	bucketName := GetBucketName(storageType)
	m.EnsureBucketExists(ctx, bucketName)

	now := time.Now()
	cleanFilename := filepath.Base(filename)
	if cleanFilename == "" || cleanFilename == "." {
		cleanFilename = "mock_dokumen.pdf"
	}
	cleanFilename = strings.ReplaceAll(cleanFilename, " ", "_")

	uniquePrefix := generateRandomHex(6)
	objectKey = fmt.Sprintf("%04d/%02d/%s_%s", now.Year(), now.Month(), uniquePrefix, cleanFilename)

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	// Presigned URL for Mock points to mock upload route on Go backend
	uploadURL = fmt.Sprintf("http://127.0.0.1:%s/api/storage/mock-upload?type=%s&object=%s", port, bucketName, objectKey)

	// Pre-create placeholder in mock storage
	m.mu.Lock()
	m.inMemory[fmt.Sprintf("%s/%s", bucketName, objectKey)] = &mockFileItem{
		Data:        []byte(fmt.Sprintf("Mock Document Content for %s", cleanFilename)),
		ContentType: contentType,
		UpdatedAt:   time.Now(),
	}
	m.mu.Unlock()

	return uploadURL, objectKey, nil
}

func (m *StorageSvcMoq) GeneratePresignedReadURL(ctx context.Context, storageType string, objectKey string, expiry time.Duration) (readURL string, err error) {
	bucketName := GetBucketName(storageType)
	cleanKey := strings.TrimPrefix(strings.TrimSpace(objectKey), bucketName+"/")

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	// In Mock connector, read URL points to the backend secure streaming route
	readURL = fmt.Sprintf("http://127.0.0.1:%s/api/storage/file?type=%s&object=%s", port, bucketName, cleanKey)

	return readURL, nil
}

func (m *StorageSvcMoq) GetObjectStream(ctx context.Context, storageType string, objectKey string) (io.ReadCloser, string, error) {
	bucketName := GetBucketName(storageType)
	cleanKey := strings.TrimPrefix(strings.TrimSpace(objectKey), bucketName+"/")
	lookupKey := fmt.Sprintf("%s/%s", bucketName, cleanKey)

	m.mu.RLock()
	item, found := m.inMemory[lookupKey]
	m.mu.RUnlock()

	if found && item != nil {
		return io.NopCloser(bytes.NewReader(item.Data)), item.ContentType, nil
	}

	// Check local filesystem
	localPath := filepath.Join(m.storageRoot, bucketName, cleanKey)
	if data, err := os.ReadFile(localPath); err == nil {
		contentType := "application/pdf"
		if strings.HasSuffix(cleanKey, ".jpg") || strings.HasSuffix(cleanKey, ".jpeg") {
			contentType = "image/jpeg"
		} else if strings.HasSuffix(cleanKey, ".png") {
			contentType = "image/png"
		}
		return io.NopCloser(bytes.NewReader(data)), contentType, nil
	}

	// Fallback mock sample PDF content
	samplePDF := []byte("%PDF-1.4 Mock Attachment PDF Sample\n1 0 obj\n<< /Title (Mock Document) >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF")
	return io.NopCloser(bytes.NewReader(samplePDF)), "application/pdf", nil
}

func (m *StorageSvcMoq) SaveMockObject(storageType string, objectKey string, contentType string, data []byte) error {
	bucketName := GetBucketName(storageType)
	cleanKey := strings.TrimPrefix(strings.TrimSpace(objectKey), bucketName+"/")
	lookupKey := fmt.Sprintf("%s/%s", bucketName, cleanKey)

	m.mu.Lock()
	m.inMemory[lookupKey] = &mockFileItem{
		Data:        data,
		ContentType: contentType,
		UpdatedAt:   time.Now(),
	}
	m.mu.Unlock()

	// Also write to local mock directory
	targetPath := filepath.Join(m.storageRoot, bucketName, cleanKey)
	_ = os.MkdirAll(filepath.Dir(targetPath), 0755)
	return os.WriteFile(targetPath, data, 0644)
}
