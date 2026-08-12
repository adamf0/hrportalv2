package presentation

import (
	"context"
	"time"

	"github.com/gofiber/fiber/v2"

	commoninfra "hrportal_backend_unpak/common/infrastructure"
	commonpresentation "hrportal_backend_unpak/common/presentation"
	login "hrportal_backend_unpak/modules/account/application/Login"
	who "hrportal_backend_unpak/modules/account/application/Whoami"
	accountInfrastructure "hrportal_backend_unpak/modules/account/infrastructure"

	"github.com/golang-jwt/jwt/v5"
)

// =======================================================
// POST /login
// =======================================================

// LoginHandler godoc
// @Summary Login
// @Tags Login
// @Param username formData string true "Username"
// @Param password formData string true "Password"
// @Produce json
// @Success 200 {object} map[string]string "jwt"
// @Failure 400 {object} commoninfra.ResponseError
// @Failure 404 {object} commoninfra.ResponseError
// @Failure 409 {object} commoninfra.ResponseError
// @Failure 500 {object} commoninfra.ResponseError
// @Router /login [post]
var jwtSecret = []byte("secret")

func generateJWT(sid string, source string, duration time.Duration) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"exp":    time.Now().Add(duration).Unix(),
		"sid":    sid,
		"source": source,
	})
	return token.SignedString(jwtSecret)
}

func LoginHandlerfunc(c *fiber.Ctx) error {
	cmd := login.LoginCommand{
		Username: c.FormValue("username"),
		Password: c.FormValue("password"),
	}

	ctx := c.UserContext()
	if ctx == nil {
		ctx = context.Background()
	}

	handler := login.NewLoginCommandHandler(
		accountInfrastructure.GlobalRepoLocal,
		accountInfrastructure.GlobalRepoSimak,
		accountInfrastructure.GlobalRepoSimpeg,
	)
	result, err := handler.Handle(ctx, &cmd)
	if err != nil {
		return commoninfra.HandleError(c, err)
	}

	if !result.IsSuccess {
		return commoninfra.HandleError(c, result.Error)
	}

	tokenStr, errToken := generateJWT(result.Value.Sid, result.Value.Source, 3*time.Hour)
	if errToken != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate access token"})
	}

	refreshStr, errRefresh := generateJWT(result.Value.Sid, result.Value.Source, 365*24*time.Hour)
	if errRefresh != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate refresh token"})
	}

	return c.JSON(fiber.Map{
		"token":   tokenStr,
		"refresh": refreshStr,
	})
}

// =======================================================
// GET /whoami
// =======================================================
func WhoAmIHandler(c *fiber.Ctx) error {
	sid := c.FormValue("sid")
	source := c.FormValue("source")

	query := who.WhoamiQuery{
		Sid:    sid,
		Source: source,
	}

	ctx := c.UserContext()
	if ctx == nil {
		ctx = context.Background()
	}

	handler := who.NewWhoamiQueryHandler(
		accountInfrastructure.GlobalRepoLocal,
		accountInfrastructure.GlobalRepoSimak,
		accountInfrastructure.GlobalRepoSimpeg,
	)
	result, err := handler.Handle(ctx, &query)
	if err != nil {
		return commoninfra.HandleError(c, err)
	}

	return c.JSON(result.Value)
}

// =======================================================
// GET /whoamiv2
// =======================================================
func WhoAmIV2Handler(c *fiber.Ctx) error {
	sid := c.Query("sid")
	source := c.Query("source")

	query := who.WhoamiQuery{
		Sid:    sid,
		Source: source,
	}

	ctx := c.UserContext()
	if ctx == nil {
		ctx = context.Background()
	}

	handler := who.NewWhoamiQueryHandler(
		accountInfrastructure.GlobalRepoLocal,
		accountInfrastructure.GlobalRepoSimak,
		accountInfrastructure.GlobalRepoSimpeg,
	)
	result, err := handler.Handle(ctx, &query)
	if err != nil {
		return commoninfra.HandleError(c, err)
	}

	return c.JSON(result.Value)
}

// =======================================================
// POST /refresh-token
// =======================================================
func RefreshTokenHandler(c *fiber.Ctx) error {
	refreshTokenStr := c.FormValue("refresh_token")
	if refreshTokenStr == "" {
		refreshTokenStr = c.FormValue("refresh")
	}
	if refreshTokenStr == "" {
		var req struct {
			RefreshToken string `json:"refresh_token"`
			Refresh      string `json:"refresh"`
		}
		if err := c.BodyParser(&req); err == nil {
			if req.RefreshToken != "" {
				refreshTokenStr = req.RefreshToken
			} else if req.Refresh != "" {
				refreshTokenStr = req.Refresh
			}
		}
	}
	if refreshTokenStr == "" {
		authHeader := c.Get("Authorization")
		if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
			refreshTokenStr = authHeader[7:]
		}
	}

	if refreshTokenStr == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Missing refresh_token"})
	}

	token, err := jwt.Parse(refreshTokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return jwtSecret, nil
	})

	if err != nil || token == nil || !token.Valid {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid or expired refresh token"})
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid token claims"})
	}

	sid, _ := claims["sid"].(string)
	source, _ := claims["source"].(string)
	if sid == "" {
		return c.Status(401).JSON(fiber.Map{"error": "Token missing SID"})
	}

	newTokenStr, errToken := generateJWT(sid, source, 3*time.Hour)
	if errToken != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate access token"})
	}

	newRefreshStr, errRefresh := generateJWT(sid, source, 365*24*time.Hour)
	if errRefresh != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate refresh token"})
	}

	return c.JSON(fiber.Map{
		"token":   newTokenStr,
		"refresh": newRefreshStr,
	})
}

func ModuleAccount(app *fiber.App) {
	app.Post("/api/account/login", LoginHandlerfunc)
	app.Post("/api/v2/account/login", LoginHandlerfunc)
	app.Post("/account/login", LoginHandlerfunc)

	app.Post("/api/account/refresh-token", RefreshTokenHandler)
	app.Post("/api/v2/account/refresh-token", RefreshTokenHandler)
	app.Post("/account/refresh-token", RefreshTokenHandler)

	app.Get("/api/account/whoami", commonpresentation.JWTMiddleware(), WhoAmIHandler)
	app.Get("/api/v2/account/whoami", commonpresentation.JWTMiddleware(), WhoAmIHandler)
	app.Get("/api/account/whoamiv2", commonpresentation.JWTMiddleware(), WhoAmIHandler)
	app.Get("/api/v2/account/whoamiv2", commonpresentation.JWTMiddleware(), WhoAmIHandler)
}
