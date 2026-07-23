package main

import (
	"context"
	"errors"
	"log"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/helmet"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/mehdihadeli/go-mediatr"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	commonhelper "hrportal_backend/common/helper"
	commoninfra "hrportal_backend/common/infrastructure"
	commonpresentation "hrportal_backend/common/presentation"

	accountInfrastructure "hrportal_backend/modules/account/infrastructure"
	accountPresentation "hrportal_backend/modules/account/presentation"

	attendanceInfrastructure "hrportal_backend/modules/attendance/infrastructure"
	attendancePresentation "hrportal_backend/modules/attendance/presentation"

	leaveInfrastructure "hrportal_backend/modules/leave/infrastructure"
	leavePresentation "hrportal_backend/modules/leave/presentation"

	masterdataInfrastructure "hrportal_backend/modules/masterdata/infrastructure"
	masterdataPresentation "hrportal_backend/modules/masterdata/presentation"

	reportInfrastructure "hrportal_backend/modules/report/infrastructure"
	reportPresentation "hrportal_backend/modules/report/presentation"

	sppdInfrastructure "hrportal_backend/modules/sppd/infrastructure"
	sppdPresentation "hrportal_backend/modules/sppd/presentation"

	izinInfrastructure "hrportal_backend/modules/izin/infrastructure"
	izinPresentation "hrportal_backend/modules/izin/presentation"

	ceremonyAttendanceInfrastructure "hrportal_backend/modules/ceremony_attendance/infrastructure"
	ceremonyAttendancePresentation "hrportal_backend/modules/ceremony_attendance/presentation"

	calendarInfrastructure "hrportal_backend/modules/calendar/infrastructure"
	calendarPresentation "hrportal_backend/modules/calendar/presentation"

	holidayInfrastructure "hrportal_backend/modules/holiday/infrastructure"
	holidayPresentation "hrportal_backend/modules/holiday/presentation"

	notificationPresentation "hrportal_backend/modules/notification/presentation"
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

var (
	dbMain   *gorm.DB
	onceMain sync.Once
)

func NewMySQL() (*gorm.DB, error) {
	var err error
	onceMain.Do(func() {
		dsn := os.Getenv("DB_HRPORTAL")
		if dsn == "" {
			dsn = "root:@tcp(127.0.0.1:3306)/unpak_hrportal?charset=utf8mb4&parseTime=True&loc=Local"
		}
		dbMain, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
		if err != nil {
			log.Printf("gagal konek database hrportal: %v", err)
			return
		}
		log.Println("berhasil koneksi database unpak_hrportal")

		sqlDB, _ := dbMain.DB()
		sqlDB.SetMaxOpenConns(100)
		sqlDB.SetMaxIdleConns(100)
		sqlDB.SetConnMaxLifetime(10 * time.Minute)
		sqlDB.SetConnMaxIdleTime(5 * time.Minute)
	})
	return dbMain, err
}

func main() {
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
		db, err = NewMySQL()
		if err == nil && db != nil {
			commonhelper.GlobalFcmManager.SetDB(db)
		}
		return err
	})

	mustStart("Database SIMAK", func() error {
		dsn := os.Getenv("DB_SIMAK")
		if dsn == "" {
			dsn = "root:@tcp(127.0.0.1:3306)/unpak_simak?charset=utf8mb4&parseTime=True&loc=Local"
		}
		var err error
		dbSimak, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
		return err
	})

	mustStart("Database SIMPEG", func() error {
		dsn := os.Getenv("DB_SIMPEG")
		if dsn == "" {
			dsn = "root:@tcp(127.0.0.1:3306)/unpak_simpeg?charset=utf8mb4&parseTime=True&loc=Local"
		}
		var err error
		dbSimpeg, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
		return err
	})

	mustStart("Report Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return reportInfrastructure.RegisterModuleReport(db)
	})

	mustStart("Account Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		if dbSimak == nil {
			dbSimak = db
		}
		if dbSimpeg == nil {
			dbSimpeg = db
		}
		return accountInfrastructure.RegisterModuleAccount(db, dbSimak, dbSimpeg)
	})

	mustStart("Attendance Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return attendanceInfrastructure.RegisterModuleAttendance(db)
	})

	mustStart("Leave Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return leaveInfrastructure.RegisterModuleLeave(db)
	})

	mustStart("MasterData Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return masterdataInfrastructure.RegisterModuleMasterData(db)
	})

	mustStart("Sppd Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return sppdInfrastructure.RegisterModuleSppd(db)
	})

	mustStart("Izin Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return izinInfrastructure.RegisterModuleIzin(db)
	})

	mustStart("CeremonyAttendance Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return ceremonyAttendanceInfrastructure.RegisterModuleCeremonyAttendance(db)
	})

	mustStart("Calendar Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return calendarInfrastructure.RegisterModuleCalendar(db)
	})

	mustStart("Holiday Module", func() error {
		if db == nil {
			return errors.New("db nil")
		}
		return holidayInfrastructure.RegisterModuleHoliday(db)
	})

	if len(startupErrors) > 0 {
		log.Printf("Startup warnings/errors encountered: %v", startupErrors)
	}

	accountPresentation.ModuleAccount(app)
	attendancePresentation.ModuleAttendance(app)
	leavePresentation.ModuleLeave(app)
	masterdataPresentation.ModuleMasterData(app)
	sppdPresentation.ModuleSppd(app)
	izinPresentation.ModuleIzin(app)
	ceremonyAttendancePresentation.ModuleCeremonyAttendance(app)
	calendarPresentation.ModuleCalendar(app)
	reportPresentation.ModuleReport(app)
	holidayPresentation.ModuleHoliday(app, db)
	notificationPresentation.ModuleNotification(app)

	// Note: Background Jobs (SDM Auto-Verify, Holiday Sync, Export Worker) are separated into standalone binaries in /cmd
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok", "service": "Unpak HRPortal Backend API"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}
	log.Printf("Server HRPortal Backend running on port :%s", port)
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
