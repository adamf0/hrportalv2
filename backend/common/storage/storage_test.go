package storage

import (
	"context"
	"io"
	"os"
	"strings"
	"sync"
	"testing"
	"time"
)

func TestStorageSvcMoq(t *testing.T) {
	moq := NewStorageSvcMoq()
	ctx := context.Background()

	// 1. Test Presigned Upload URL
	uploadURL, objectKey, err := moq.GeneratePresignedUploadURL(ctx, "cuti", "surat_dokter.pdf", "application/pdf")
	if err != nil {
		t.Fatalf("GeneratePresignedUploadURL failed: %v", err)
	}
	if uploadURL == "" || objectKey == "" {
		t.Fatalf("Expected non-empty uploadURL and objectKey, got url: %s, key: %s", uploadURL, objectKey)
	}
	if !strings.Contains(objectKey, "surat_dokter.pdf") {
		t.Errorf("Expected objectKey to contain filename, got: %s", objectKey)
	}

	// 2. Test Save & Get Object Stream
	dummyData := []byte("Mock PDF Data Content 12345")
	errSave := moq.SaveMockObject("cuti", objectKey, "application/pdf", dummyData)
	if errSave != nil {
		t.Fatalf("SaveMockObject failed: %v", errSave)
	}

	stream, contentType, errStream := moq.GetObjectStream(ctx, "cuti", objectKey)
	if errStream != nil {
		t.Fatalf("GetObjectStream failed: %v", errStream)
	}
	defer stream.Close()

	if contentType != "application/pdf" {
		t.Errorf("Expected contentType application/pdf, got: %s", contentType)
	}

	readBytes, errRead := io.ReadAll(stream)
	if errRead != nil {
		t.Fatalf("io.ReadAll stream failed: %v", errRead)
	}
	if string(readBytes) != string(dummyData) {
		t.Errorf("Expected stream data '%s', got '%s'", string(dummyData), string(readBytes))
	}

	// 3. Test Presigned Read URL
	readURL, errReadURL := moq.GeneratePresignedReadURL(ctx, "cuti", objectKey, 2*time.Hour)
	if errReadURL != nil {
		t.Fatalf("GeneratePresignedReadURL failed: %v", errReadURL)
	}
	if readURL == "" || !strings.Contains(readURL, objectKey) {
		t.Errorf("Expected valid readURL containing objectKey, got: %s", readURL)
	}
}

func TestStorageFactorySwitching(t *testing.T) {
	// Test Moq switch
	os.Setenv("STORAGE_CONNECTOR", "storageSvcMoq")
	storageOnce = syncOnceReset()
	svcMoq := InitStorageService()
	if _, ok := svcMoq.(*StorageSvcMoq); !ok {
		t.Errorf("Expected *StorageSvcMoq when STORAGE_CONNECTOR=storageSvcMoq, got %T", svcMoq)
	}

	// Test S3 switch
	os.Setenv("STORAGE_CONNECTOR", "storageSvcS3")
	storageOnce = syncOnceReset()
	svcS3 := InitStorageService()
	if _, ok := svcS3.(*StorageSvcS3); !ok {
		t.Errorf("Expected *StorageSvcS3 when STORAGE_CONNECTOR=storageSvcS3, got %T", svcS3)
	}
}

func syncOnceReset() (o sync.Once) {
	return o
}
