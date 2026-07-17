package infrastructure

import (
	"context"
	"errors"
	"fmt"
	"strconv"

	"hrportal_backend/modules/account/domain"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type LocalRepository struct {
	db *gorm.DB
}

func NewLocalRepository(db *gorm.DB) domain.ILocalRepository {
	return &LocalRepository{db: db}
}

func (r *LocalRepository) Authenticate(ctx context.Context, username, password string) (*domain.AuthResult, error) {
	var localUsers []struct {
		ID       uint   `gorm:"column:id"`
		Username string `gorm:"column:username"`
		Password string `gorm:"column:password"`
	}
	_ = r.db.WithContext(ctx).Table("users").Where("username = ?", username).Find(&localUsers)

	var matchedIDs []uint
	for _, lu := range localUsers {
		if errBcrypt := bcrypt.CompareHashAndPassword([]byte(lu.Password), []byte(password)); errBcrypt == nil {
			matchedIDs = append(matchedIDs, lu.ID)
		}
	}

	if len(matchedIDs) > 1 {
		return nil, errors.New("akun " + username + " lebih dari 1")
	}

	if len(matchedIDs) == 1 {
		return &domain.AuthResult{
			Sid:    fmt.Sprintf("%d", matchedIDs[0]),
			Source: "local",
		}, nil
	}

	return nil, nil
}

func (r *LocalRepository) GetInfo(ctx context.Context, sid string) (*domain.UserInfo, error) {
	id, err := strconv.Atoi(sid)
	if err != nil {
		return nil, errors.New("invalid sid format")
	}

	var u struct {
		Username string `gorm:"column:username"`
		Name     string `gorm:"column:name"`
		Email    string `gorm:"column:email"`
	}

	err = r.db.WithContext(ctx).Table("users").Where("id = ?", id).First(&u).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("data local tidak ditemukan")
		}
		return nil, err
	}

	return &domain.UserInfo{
		Sid:          sid,
		Source:       "local",
		Fakultas:     "",
		Prodi:        "",
		KodeFakultas: "",
		KodeProdi:    "",
		Unit:         "",
		Level:        "sdm",
		Name:         u.Name,
		Email:        u.Email,
		Nip:          u.Username,
		Nidn:         "",
	}, nil
}
