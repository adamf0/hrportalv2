package presentation

import (
	"context"
	"time"

	"github.com/gofiber/fiber/v2"

	commoninfra "hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"
	login "hrportal_backend/modules/account/application/Login"
	who "hrportal_backend/modules/account/application/Whoami"
	accountInfrastructure "hrportal_backend/modules/account/infrastructure"

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

	refreshStr, errRefresh := generateJWT(result.Value.Sid, result.Value.Source, 7*24*time.Hour)
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

func ModuleAccount(app *fiber.App) {
	app.Post("/api/account/login", LoginHandlerfunc)
	app.Get("/api/account/whoami", commonpresentation.JWTMiddleware(), WhoAmIHandler)
}
