package storage

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type StorageSvcS3 struct {
	client *minio.Client
	config StorageConfig
}

func NewStorageSvcS3() *StorageSvcS3 {
	endpoint := os.Getenv("S3_ENDPOINT")
	if endpoint == "" {
		endpoint = "s3.fra.databucket.eu"
	}
	endpoint = strings.TrimPrefix(endpoint, "https://")
	endpoint = strings.TrimPrefix(endpoint, "http://")
	endpoint = strings.TrimRight(endpoint, "/")

	accessKey := os.Getenv("S3_ACCESS_KEY")
	secretKey := os.Getenv("S3_SECRET_KEY")

	useSSL := true
	if sslEnv := os.Getenv("S3_USE_SSL"); sslEnv == "false" || sslEnv == "0" {
		useSSL = false
	}

	region := os.Getenv("S3_REGION")
	if region == "" {
		region = "fra"
	}

	cfg := StorageConfig{
		Endpoint:  endpoint,
		AccessKey: accessKey,
		SecretKey: secretKey,
		UseSSL:    useSSL,
		Region:    region,
	}

	minioClient, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
		Region: cfg.Region,
	})

	if err != nil {
		log.Printf("[storageSvcS3] Failed to initialize MinIO/S3 client: %v", err)
	} else {
		log.Printf("[storageSvcS3] Initialized S3 Connector for endpoint: %s (Region: %s, SSL: %v)", cfg.Endpoint, cfg.Region, cfg.UseSSL)
	}

	s3Svc := &StorageSvcS3{
		client: minioClient,
		config: cfg,
	}

	// Ensure default buckets exist
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	for _, b := range []string{"cuti", "izin", "sppd"} {
		s3Svc.EnsureBucketExists(ctx, b)
	}

	return s3Svc
}

func (s *StorageSvcS3) EnsureBucketExists(ctx context.Context, bucketName string) {
	if s.client == nil {
		return
	}
	exists, err := s.client.BucketExists(ctx, bucketName)
	if err == nil && !exists {
		errMake := s.client.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{Region: s.config.Region})
		if errMake != nil {
			log.Printf("[storageSvcS3] Warning: Could not make bucket '%s': %v", bucketName, errMake)
		} else {
			log.Printf("[storageSvcS3] Bucket '%s' created successfully", bucketName)
		}
	}
}

func (s *StorageSvcS3) GeneratePresignedUploadURL(ctx context.Context, storageType string, filename string, contentType string) (uploadURL string, objectKey string, err error) {
	if s.client == nil {
		return "", "", fmt.Errorf("storageSvcS3 client not initialized")
	}

	bucketName := GetBucketName(storageType)
	s.EnsureBucketExists(ctx, bucketName)

	now := time.Now()
	cleanFilename := filepath.Base(filename)
	if cleanFilename == "" || cleanFilename == "." {
		cleanFilename = "upload.pdf"
	}
	cleanFilename = strings.ReplaceAll(cleanFilename, " ", "_")

	uniquePrefix := generateRandomHex(6)
	objectKey = fmt.Sprintf("%04d/%02d/%s_%s", now.Year(), now.Month(), uniquePrefix, cleanFilename)

	expiry := 30 * time.Minute

	presignedURL, err := s.client.PresignedPutObject(ctx, bucketName, objectKey, expiry)
	if err != nil {
		return "", "", fmt.Errorf("storageSvcS3 failed to generate presigned upload url: %w", err)
	}

	return presignedURL.String(), objectKey, nil
}

func (s *StorageSvcS3) GeneratePresignedReadURL(ctx context.Context, storageType string, objectKey string, expiry time.Duration) (readURL string, err error) {
	if s.client == nil {
		return "", fmt.Errorf("storageSvcS3 client not initialized")
	}

	bucketName := GetBucketName(storageType)

	cleanKey := strings.TrimSpace(objectKey)
	if strings.Contains(cleanKey, "://") {
		if parsed, errParse := url.Parse(cleanKey); errParse == nil {
			path := strings.TrimPrefix(parsed.Path, "/")
			if strings.HasPrefix(path, bucketName+"/") {
				cleanKey = strings.TrimPrefix(path, bucketName+"/")
			} else {
				cleanKey = path
			}
		}
	}
	cleanKey = strings.TrimPrefix(cleanKey, bucketName+"/")

	if expiry <= 0 {
		expiry = 2 * time.Hour
	}

	reqParams := make(url.Values)
	presignedURL, err := s.client.PresignedGetObject(ctx, bucketName, cleanKey, expiry, reqParams)
	if err != nil {
		return "", fmt.Errorf("storageSvcS3 failed to generate presigned read url: %w", err)
	}

	return presignedURL.String(), nil
}

func (s *StorageSvcS3) GetObjectStream(ctx context.Context, storageType string, objectKey string) (io.ReadCloser, string, error) {
	if s.client == nil {
		return nil, "", fmt.Errorf("storageSvcS3 client not initialized")
	}

	bucketName := GetBucketName(storageType)
	cleanKey := strings.TrimPrefix(strings.TrimSpace(objectKey), bucketName+"/")

	obj, err := s.client.GetObject(ctx, bucketName, cleanKey, minio.GetObjectOptions{})
	if err != nil {
		return nil, "", err
	}

	info, errStat := obj.Stat()
	contentType := "application/octet-stream"
	if errStat == nil && info.ContentType != "" {
		contentType = info.ContentType
	}

	return obj, contentType, nil
}

func (s *StorageSvcS3) SaveMockObject(storageType string, objectKey string, contentType string, data []byte) error {
	return nil
}
