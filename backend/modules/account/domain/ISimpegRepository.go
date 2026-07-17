package domain

import "context"

type ISimpegRepository interface {
	Authenticate(ctx context.Context, username, password string) (*AuthResult, error)
	GetInfo(ctx context.Context, sid string) (*UserInfo, error)
}
