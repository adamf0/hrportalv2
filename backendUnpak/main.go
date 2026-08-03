package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/helmet"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/joho/godotenv"
	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	commoninfra "hrportal_backend_unpak/common/infrastructure"
	commonpresentation "hrportal_backend_unpak/common/presentation"

	accountInfrastructure "hrportal_backend_unpak/modules/account/infrastructure"
	accountPresentation "hrportal_backend_unpak/modules/account/presentation"

	masterdataInfrastructure "hrportal_backend_unpak/modules/masterdata/infrastructure"
	masterdataPresentation "hrportal_backend_unpak/modules/masterdata/presentation"
)

var startupErrors []fiber.Map

func mustStart(name string, fn func() error) {
	if err := fn(); err != nil {
		startupErrors = append(startupErrors, fiber.Map{
			"module": name,
			"error":  err.Error(),
		})
	}
}

func tryConnectDB(envVar string, dbName string) (*gorm.DB, error) {
	candidates := []string{}
	if envDSN := os.Getenv(envVar); envDSN != "" {
		candidates = append(candidates, envDSN)
	}
	// Candidate fallbacks: empty password, 'password', 'root'
	candidates = append(candidates,
		fmt.Sprintf("root:@tcp(127.0.0.1:3306)/%s?charset=utf8mb4&parseTime=True&loc=Local", dbName),
		fmt.Sprintf("root:password@tcp(127.0.0.1:3306)/%s?charset=utf8mb4&parseTime=True&loc=Local", dbName),
		fmt.Sprintf("root:root@tcp(127.0.0.1:3306)/%s?charset=utf8mb4&parseTime=True&loc=Local", dbName),
	)

	var lastErr error
	for _, dsn := range candidates {
		db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
		if err == nil && db != nil {
			sqlDB, errSql := db.DB()
			if errSql == nil {
				sqlDB.SetMaxOpenConns(100)
				sqlDB.SetMaxIdleConns(100)
				sqlDB.SetConnMaxLifetime(10 * time.Minute)
				sqlDB.SetConnMaxIdleTime(5 * time.Minute)
				if errPing := sqlDB.Ping(); errPing == nil {
					log.Printf("Successfully connected %s using DSN: %s", envVar, dsn)
					return db, nil
				} else {
					lastErr = errPing
				}
			}
		} else if err != nil {
			lastErr = err
		}
	}
	return nil, lastErr
}

func main() {
	_ = godotenv.Load()

	cfg := commonpresentation.DefaultHeaderSecurityConfig()
	cfg.ResolveAndCheck = false

	app := fiber.New(fiber.Config{
		ReadBufferSize: 16 * 1024,
		ReadTimeout:    120 * time.Second,
		WriteTimeout:   120 * time.Second,
		IdleTimeout:    120 * time.Second,
	})

	app.Use(recover.New())

	isCors := os.Getenv("ALLOW_CORS")
	origins := os.Getenv("ALLOWED_ORIGINS")

	if isCors == "0" {
		app.Use(cors.New(cors.Config{
			AllowOrigins:     "http://localhost:4000",
			AllowMethods:     "GET,POST,PUT,PATCH,DELETE",
			AllowHeaders:     "Origin, Content-Type, Accept, Authorization",
			AllowCredentials: true,
		}))
	} else {
		app.Use(cors.New(cors.Config{
			AllowOriginsFunc: func(origin string) bool {
				if origin == "" {
					return true
				}
				allowed := strings.Split(origins, ",")
				for _, o := range allowed {
					if strings.TrimSpace(o) == origin {
						return true
					}
				}
				return true
			},
			AllowMethods:     "GET,POST,PUT,PATCH,DELETE",
			AllowHeaders:     "Origin, Content-Type, Accept, Authorization",
			AllowCredentials: true,
		}))
	}

	app.Use(helmet.New(helmet.Config{
		XSSProtection:             "1; mode=block",
		ContentTypeNosniff:        "nosniff",
		XFrameOptions:             "DENY",
		ReferrerPolicy:            "no-referrer",
		ContentSecurityPolicy:     "default-src 'self'",
		CrossOriginEmbedderPolicy: "require-corp",
		CrossOriginOpenerPolicy:   "same-origin",
		CrossOriginResourcePolicy: "same-origin",
	}))

	app.Use(commonpresentation.LoggerMiddleware)
	app.Use(commonpresentation.HeaderSecurityMiddleware(cfg))

	mediatr.RegisterRequestPipelineBehaviors(NewValidationBehavior())

	var (
		db       *gorm.DB
		dbSimak  *gorm.DB
		dbSimpeg *gorm.DB
	)
	mustStart("Database", func() error {
		var err error
		db, err = tryConnectDB("DB_HRPORTAL", "unpak_hrportal")
		// if err == nil && db != nil {
		// 	commonhelper.GlobalFcmManager.SetDB(db)
		// }
		return err
	})

	mustStart("Database SIMAK", func() error {
		var err error
		dbSimak, err = tryConnectDB("DB_SIMAK", "unpak_simak")
		return err
	})

	mustStart("Database SIMPEG", func() error {
		var err error
		dbSimpeg, err = tryConnectDB("DB_SIMPEG", "unpak_simpeg")
		return err
	})

	mustStart("Account Module", func() error {
		if dbSimak == nil {
			dbSimak = db
		}
		if dbSimpeg == nil {
			dbSimpeg = db
		}
		return accountInfrastructure.RegisterModuleAccount(db, dbSimak, dbSimpeg)
	})

	mustStart("MasterData Module", func() error {
		return masterdataInfrastructure.RegisterModuleMasterData(db)
	})

	if len(startupErrors) > 0 {
		log.Printf("Startup warnings/errors encountered: %v", startupErrors)
	}

	accountPresentation.ModuleAccount(app)
	masterdataPresentation.ModuleMasterData(app)

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok", "service": "Unpak HRPortal Backend API (Account & MasterData)"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}
	log.Printf("Server HRPortal BackendUnpak running on port :%s", port)
	app.Listen(":" + port)
}

type ValidationBehavior struct{}

func NewValidationBehavior() *ValidationBehavior {
	return &ValidationBehavior{}
}

func (b *ValidationBehavior) Handle(
	ctx context.Context,
	request interface{},
	next mediatr.RequestHandlerFunc,
) (interface{}, error) {
	if err := commoninfra.Validate(request); err != nil {
		return nil, err
	}
	return next(ctx)
}
