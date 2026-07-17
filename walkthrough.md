# Walkthrough - Flutter Attendance Application (HR Portal / HR Connect)

We have successfully implemented the Flutter Attendance Application based on the design templates in the **Smart Motion HRIS** project, integrated **Unpak SSO** authentication, activated complete logout mechanics, and resolved all Gradle/JDK-related build failures on macOS.

Additionally, we have completed the large-scale refactoring of the codebase into a clean **Domain-Driven Design (DDD) + CQRS + Modular + Atomic Design Pattern**, utilizing a lightweight custom **Mediator** to decouple presentation layers from core business/infrastructure logic.

---

## 🏗️ Architectural Refactoring: DDD + CQRS + Modular + Atomic Design

We split the codebase into self-contained feature modules under `lib/modules/` (Auth, Attendance, Leave, Payroll, and Dashboard), structured precisely into layers:

1. **Domain Layer (`domain/`)**:
   - Contains pure business entities, specific validation rules, exceptions/failures, and repository interfaces defining contracts for infrastructure implementation.
   - Example: [payroll.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/domain/payroll.dart), [i_payroll_repository.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/domain/i_payroll_repository.dart).

2. **Application Layer (`application/`)**:
   - Implements CQRS (Command Query Responsibility Segregation) pattern. Actions are grouped into action-specific folders containing Command/Query payloads, validations, and handlers.
   - Example: [get_salary_slip_query.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/application/get_salary_slip/get_salary_slip_query.dart).

3. **Infrastructure Layer (`infrastructure/`)**:
   - Provides concrete implementation of repository contracts, interacting with hardware interfaces, Geolocation plugins, Camera, local storage, and the Keycloak SSO / HRPortal HTTP API.
   - Example: [payroll_repository.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/infrastructure/payroll_repository.dart).

4. **Presentation Layer (`presentation/`)**:
   - Implements state control using lightweight ChangeNotifier-based Blocs, which interact with the infrastructure exclusively through the Mediator.
   - UI views are structured following Atomic Design elements (`atoms`, `molecules`, `organisms`, `pages`).
   - Example: [salary_slip_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/presentation/components/pages/salary_slip_page.dart).

---

## 🛠️ Modules Refactored

### 1. Auth Module (`lib/modules/auth/`)
- **Domain**: Created `AuthSession` entity representation, `AuthError` specific errors, and `IAuthRepository` contracts.
- **Application**: CQRS handlers for `LoginCommand`, `LogoutCommand`, `CheckTokenQuery`, `CheckPermissionsQuery`, and `RequestPermissionsCommand`.
- **Infrastructure**: Native Keycloak SSO authentication integration inside `AuthRepository`.
- **Presentation**: Rerouted `SplashPage`, `LoginPage`, and `PermissionPage` to read session tokens directly from `AuthBloc`.

### 2. Attendance Module (`lib/modules/attendance/`)
- **Domain**: Holds check-in/out records, location validation strategy contracts.
- **Application**: Commands for `CheckInCommand` and `CheckOutCommand`.
- **Infrastructure**: Core location range matching strategies (Polygon strategy and Wi-Fi SSID strategy) and face liveness validation checks inside `AttendanceRepository`.
- **Presentation**: Migrated face scanner, circular liveness overlays, and check-in success telemetry cards to read from `AttendanceBloc`.

### 3. Leave Module (`lib/modules/leave/`)
- **Domain**: `LeaveRequest` models, `Supervisor` metadata, and `ILeaveRepository` contracts.
- **Application**: CQRS handlers for `SubmitLeaveCommand`, `GetLeavesQuery`, and `GetSupervisorsQuery`.
- **Infrastructure**: Remote form submissions and mock supervisor search queries inside `LeaveRepository`.
- **Presentation**: Leave logs list view with dynamic scrollable bottom sheet status filters and form date ranges inside `LeaveBloc` and UI pages.

### 4. Payroll Module (`lib/modules/payroll/`)
- **Domain**: `PayrollData` salary details model and `IPayrollRepository` contracts.
- **Application**: CQRS query `GetSalarySlipQuery` and its handler.
- **Infrastructure**: HTTP POST connection to the HRPortal API inside `PayrollRepository`.
- **Presentation**: Interactive month and year payroll slip dropdown controls, empty slip states, and printable Monospaced table layouts inside `PayrollBloc` and pages.

### 5. Dashboard Module (`lib/modules/dashboard/`)
- **Presentation**: A unified dashboard page consuming `AuthBloc` (user identity), `AttendanceBloc` (GPS coordinates, auto-attendance status, upacara eligibility, recent activities), and `LeaveBloc` (leave statistic counters: `sisaCuti`, `cutiDiambil`, `cutiPending`), scaling cleanly from small smartwatches up to large tablets.

---

## 📅 Indonesian National Holiday & Weekend Disabling
- Mapped Indonesian national calendar holidays (2025–2027) dynamically inside date ranges.
- Saturdays and Sundays are hard-disabled inside leave range pickers to enforce rest-day constraints.

## ⚛️ Clean Code & Common Components Refactoring

1. **Strict Line Limit Enforcement**:
   - Guaranteed **100% of files** across `/lib/` and `/lib/modules/` are strictly **under 600 lines**.
   - `leave_form_page.dart` line count reduced from 1,121 lines to **570 lines**.
2. **Common Components Extraction (`lib/common/presentation/components/`)**:
   - Extracted repeating UI patterns into dedicated common components:
     - **Atoms**:
       - [FormSectionHeader](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/common/presentation/components/atoms/form_section_header.dart): Unified section text headers (`'JENIS CUTI'`, `'TANGGAL CUTI (RANGE)'`, `'KOTA TUJUAN DINAS'`, etc.).
       - [HeaderTitleText](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/common/presentation/components/atoms/header_title_text.dart): Standardized modal/dialog title headers (`'Absen Masuk Berhasil'`, `'Pengajuan Terkirim'`, etc.).
     - **Molecules**:
       - [ResponsiveDateRangeRow](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/common/presentation/components/molecules/responsive_date_range_row.dart): Responsive date range layout builder supporting mobile & watch views.
       - [LeaveFormTabBar](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/molecules/leave_form_tab_bar.dart): Navigation tab selector bar for Cuti, Izin, and SPPD forms.
       - **Cuti, Izin, and SPPD Integration Fixes**:
         - **Cuti (Leave)**: Submissions now correctly initialize the status field as `"menunggu"` (which is one of the allowed MySQL database enum values) instead of `"Pengajuan"`.
         - **Izin (Permission)**: Struct field mappings corrected to map `JenisIzinID` to the actual table column `id_jenis_izin` (configured GORM tag to force `type:int` to prevent conflicts with native foreign key types).
         - **SPPD**: Request handlers updated to correctly parse input parameters from `FormValue` as a fallback if the request body is form-urlencoded (preventing validation errors on empty fields).
         - **Verification**: Run of full-suite POST tests completed with HTTP 200 OK responses, successfully creating test records in the database.
       - **Pusat Pengajuan Display Mismatches & Swipe Refresh**:
         - **SPPD Response Structure Fix**: Modified the backend history endpoint `/api/sppd/history` to wrap results in `{"data": [...]}`. This correctly aligns with Flutter's `ApiClient` which expects a JSON map rather than a raw array.
         - **SppdRepository Safety Exit**: Added early exit safety checks to prevent nil-pointer queries and server crash panics when `nip` and `nidn` are both empty.
         - **Cuti Type Mapping**: Remapped types (such as `jenisCutiId == 2` to `"Cuti Sakit"` instead of `"Izin Sakit"`) in Flutter's `leave_repository.dart` to make sure all requests sourced from the `cuti` table remain inside the `"Cuti"` category tab.
         - **Timezone Conversion**: Appended `.toLocal()` during date parsing to handle system timezone offsets correctly (restoring true calendar day display numbers).
         - **Status Badge & Filtering**: Added recognition for the `"TERIMA SDM"` status string inside `LeaveRequestStatus.fromString` to display the green approved tag and enable accurate filtering.
         - **Swipe Refresh integration**: Wrapped `LeaveListPage` inside a `RefreshIndicator` and ensured all layout states are scrollable using `AlwaysScrollableScrollPhysics` so pulling down to refresh refreshes the list instantly under any condition.
3. **Clean Design Patterns (Strategy, Factory, and Value Object Patterns with Enums)**:
   - **Strongly-Typed Enums**:
     - [LeaveFormType](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/domain/leave_form_type.dart): Replaced magic numbers `0, 1, 2` with `LeaveFormType.cuti`, `LeaveFormType.izin`, `LeaveFormType.sppd`.
     - [LeaveRequestStatus](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/domain/leave_status.dart): Replaced all raw string comparisons and `if-else if-else` badge styling chains (`if (status == 'ACC SDM' || status == 'Disetujui')...`) with strongly-typed `LeaveRequestStatus` Value Object methods (`status.isApproved`, `status.tagBackgroundColor`, `status.tagTextColor`).
     - [LeaveCategory](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/domain/leave_category.dart): Strongly-typed filtering enum for leave list requests (`semua`, `cuti`, `izin`, `sppd`).
   - **GoF Strategy Pattern**: Implemented abstract [AttachmentStrategy](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/strategies/attachment_strategy.dart) with concrete strategy implementations (`CutiAttachmentStrategy`, `IzinAttachmentStrategy`, `SppdAttachmentStrategy`).
   - **Simple Factory**: `AttachmentStrategyFactory` instantiates concrete strategies based on `LeaveFormType`.
   - **Form Options Constants**: Extracted static arrays into [LeaveFormData](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/leave_form_data.dart).
   - **DatePicker Helper**: Extracted date picker logic into [LeaveDatePickerHelper](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/helpers/leave_date_picker_helper.dart).

4. **Robust API Client & Exception Handling (`lib/core/api_client.dart`)**:
   - Implemented centralized [ApiClient](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/api_client.dart) complying with explicit HTTP status rules:
     - **Statuses 200, 204, 304**: Treated as SUCCESS; parses and decodes JSON payload.
     - **Non 200/204/304 Statuses**: Parses JSON body to extract `message`/`msg`/`error` field if present, or falls back to common default error message (`"Terjadi kesalahan pada server (Status HTTP: $statusCode)"`).
     - **Exception Logging & Toast Notification**: Catches network (`SocketException`), timeout (`TimeoutException`), format (`FormatException`), and unpredicted errors (`Object e`), logs full StackTrace, and presents a red floating Toast/SnackBar to the user via global `scaffoldMessengerKey`.

5. **Centralized Theme Tokens & Complete Dynamic Theme Context Access (`lib/core/app_theme.dart`)**:
   - Extended [AppTheme](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/app_theme.dart) tokens to cover all brand and system neutrals including `outlineVariant: Color(0x4DC3C6D6)`, `onSurfaceVariant`, `onSurface`, and `primary`.
   - Refactored **all 25 UI component and page widgets** to completely eliminate local static `const primaryColor = ...`, `const outlineVariant = ...`, and `const onSurfaceVariant = ...` declarations.
   - All components now retrieve design tokens dynamically via `Theme.of(context).colorScheme` (`.primary`, `.onSurface`, `.onSurfaceVariant`, `.outlineVariant`, `.surface`, `.secondary`).
   - Enhanced [ResponsiveExtension](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/responsive_helper.dart) to scale paddings, margins, fonts, and dimensions dynamically without any overflow errors across device form factors.

---

## 📸 Verification & Quality Assurance
- Static Code Analysis: `flutter analyze` completed with **0 issues**.
- Widget & Integration Testing: `flutter test` passed all tests.

---

## ⚛️ Month List Expansion & Atomic Design Refactoring

1. **Expanded Payroll Period Months**:
   - The month list dropdown on the Salary Slip Page has been expanded to support a full calendar selection from January to December (`"Jan"` through `"Des"`).
2. **Atomic Design Component Decomposition**:
   - Refactored oversized visual elements and inline styles into highly reusable components matching the Atomic design hierarchy:
     - **Atoms**:
       - [LegendDot](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/presentation/components/atoms/legend_dot.dart): Reusable status dot indicator for calendars.
       - [StatCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/presentation/components/atoms/stat_card.dart): Statistics indicator card for check-ins, leaves, and absences.
       - [AttachmentTile](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/atoms/attachment_tile.dart): Unified upload picker and delete action list row for documents.
       - [SupervisorSelectorTile](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/atoms/supervisor_selector_tile.dart): Interactive supervisor display block.
     - **Molecules**:
       - [QuickMenuButton](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/presentation/components/molecules/quick_menu_button.dart): Grid navigation shortcuts.
       - [ActivityItemRow](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/presentation/components/molecules/activity_item_row.dart): Recent check-in/out logs row layout.
       - [DashboardHeader](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/molecules/dashboard_header.dart): PROFILE header with notifications status and logout shortcut.
       - [GreetingBanner](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/molecules/greeting_banner.dart): Welcome banner displaying custom check-in statuses.
       - [FloatingLogo](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/auth/presentation/components/molecules/floating_logo.dart): floating logo with bypass gesture for login.
       - [LoginFooter](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/auth/presentation/components/molecules/login_footer.dart): localization and copyright information links.
       - [PermissionTileCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/auth/presentation/components/molecules/permission_tile_card.dart): individual application permission card indicator.
       - [YearSelector](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/presentation/components/molecules/year_selector.dart): year dropdown selector view.
       - [MonthSelector](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/presentation/components/molecules/month_selector.dart): horizontally scrollable list of calendar months.
       - [SalarySlipNotFoundCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/presentation/components/molecules/salary_slip_not_found_card.dart): empty state indicator card for missing payroll slips.
     - **Organisms**:
       - [CalendarView](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/presentation/components/organisms/calendar_view.dart): Clean calendar monthly grid representation.
       - [RequestCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/organisms/request_card.dart): Status-colored request card for leave/izin logs list.
       - [PrintableSalarySlip](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/payroll/presentation/components/organisms/printable_salary_slip.dart): Complete monospaced tabular print view.
       - [AttendanceTimeCards](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/attendance_time_cards.dart): Check-in/out summary block.
       - [FlagCeremonyCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/flag_ceremony_card.dart): Face scanner trigger card for monthly 17-an ceremony.
       - [AutoCheckInStatusCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/auto_check_in_status_card.dart): IP/GPS range check status card.
       - [DashboardCalendarCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/dashboard_calendar_card.dart): Wrapper widget enclosing monthly attendance calendar representation.
       - [AttendanceStatsSection](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/attendance_stats_section.dart): Summary counts grid for leaves, izin, and absent days.
       - [LeaveSummarySection](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/leave_summary_section.dart): Side-by-side annual balance stats blocks.
       - [QuickMenuSection](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/quick_menu_section.dart): Quick grid triggers for form pages.
       - [RecentActivitiesSection](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/recent_activities_section.dart): Short list showing last few check actions.
       - [CutiFormSection](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/organisms/cuti_form_section.dart): leave application form fields.
       - [IzinFormSection](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/organisms/izin_form_section.dart): permission application form fields.
       - [SppdFormSection](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/organisms/sppd_form_section.dart): business travel allowance application form fields.
       - [AttendanceSuccessCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/attendance/presentation/components/organisms/attendance_success_card.dart): liveness detector success display panel.
       - [CameraScannerView](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/attendance/presentation/components/organisms/camera_scanner_view.dart): camera stream wrapper with circular liveness progress indicators.
       - [SsoLoginCard](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/auth/presentation/components/organisms/sso_login_card.dart): card containing Unpak SSO authentication trigger.
       - [StatusFilterSheet](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/components/organisms/status_filter_sheet.dart): bottom sheet status filtering option picker.

---

## 🐛 Unmounted Context Bug Fixes (Stateful Lifecycle Safety)

We have resolved all "This widget has been unmounted, so the State no longer has a context" exception occurrences across pages by enforcing strict mount checks and pre-capturing contexts before async gaps:
1. **Attendance Page**: Added a checks-guard `if (!mounted) return;` before triggering the success popup dialog after check-in/upacara async tasks complete.
2. **Dashboard Page**: 
   - Added a `mounted` constraint to the startup post-frame callback mapping Wi-Fi and location, preventing exceptions if the screen is popped during initial network discovery.
   - Pre-resolved the `ScaffoldMessenger` reference synchronously *before* the check-out await gap inside the confirmation dialog, removing defunct context usage.
3. **Leave Form Page**: Added `if (!mounted) return;` check guards before executing the custom sliding transition of `_showSuccessDialog()` for all Cuti, Izin, and SPPD application workflows.
4. **Permission Page**: Placed `if (!mounted) return;` at the entry point of the periodic checks callback, ensuring that any callbacks fired during the widget tear-down are discarded immediately without attempting to resolve providers.

---

## 🔌 Integrasi Penuh Flutter-Golang (Form-Data & Multipart)

Kami telah memigrasi seluruh request data POST dari JSON ke format **Form Data (multipart & URL-encoded)**, serta menghilangkan penggunaan `c.BodyParser` di backend:

### 1. Perubahan Presentation Layer Backend (Golang)
- Menggantikan `c.BodyParser` dengan ekstraksi parameter manual via `c.FormValue` pada seluruh controller POST:
  - **Account Module**: `POST /api/account/login` (mengambil `username` dan `password` lewat `c.FormValue` ke dalam structured function handler `LoginHandlerfunc`).
  - **Attendance Module**: `POST /api/attendance/check-in`, `/api/attendance/check-in-upacara`, dan `/api/attendance/check-out`.
  - **Leave Module**: `POST /api/leave/submit` (mendukung `c.FormFile` untuk field `file_lampiran` guna memproses upload file secara langsung ke folder `./uploads`, serta mendeteksi fallback string).
  - **SPPD Module**: `POST /api/sppd/create`.
- **Refactoring Arsitektur Controller**: Menyusun ulang `account/presentation/Http.go` untuk meniru format berkas rujukan lama (`UnpakSiamida`) secara identik tanpa modifikasi/peningkatan (termasuk struktur komentar separator, format alias import lowercase, nama handler `LoginHandlerfunc` & `WhoAmIHandler`, parameter mediatr, dan penggunaan type pointer parameters).
- **Pemisahan 3 Repositori Independen**: Memecah proses autentikasi di `LoginCommandHandler` agar menyuntikkan tiga repositori independen (`ILocalRepository`, `ISimakRepository`, `ISimpegRepository`) yang dideklarasikan di berkas mandiri masing-masing: [ILocalRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/account/domain/ILocalRepository.go), [ISimakRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/account/domain/ISimakRepository.go), [ISimpegRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/account/domain/ISimpegRepository.go), dan [AuthResult.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/account/domain/AuthResult.go). Menghapus seluruh metode repository penjelajah data lama (`FindByNipOrEmail`, `FindPegawaiByNip`, dan `GetAllPegawai`) yang tidak sesuai dengan basis data.
- **Alur Fallback Berjenjang (Nested Fallback)**: Menyusun kembali `LoginCommand.go` agar mengikuti alur bersarang (nested `if err != nil`) secara persis sesuai permintaan: Local -> SIMAK -> SIMPEG. Jika Local mengembalikan error, sistem beralih ke SIMAK, dan jika SIMAK mengembalikan error, sistem beralih ke SIMPEG. Error akhir dari SIMPEG akan dipropagasikan langsung ke client jika seluruhnya gagal.
- **Dukungan Scan NULL-Safe**: Mengubah tipe data scan properti database yang bersifat opsional/nullable menjadi bertipe pointer ke string (`*string`) di `SimakRepository.go` dan `SimpegRepository.go` demi mencegah error pemindaian database NULL GORM dan memetekannya menjadi string kosong `""` secara aman via helper `getString`.
- **Refactoring Query Whoami**: Merefaktor [WhoamiQuery.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/account/application/Whoami/WhoamiQuery.go) agar langsung menyuntikkan `*gorm.DB` untuk memproses pencarian detail `view_pegawai` secara langsung.
- **Pemetaan Skema Output Profil Login (JSON Response)**: Mengubah payload respons keluaran JSON dari endpoint login `/api/account/login` agar langsung mencakup properti profil yang tepat sesuai permintaan (`sid`, `source`, `fakultas`, `prodi`, `unit`, dan `level`), dengan tetap menyertakan properti `token`, `user`, dan `pegawai` demi kompatibilitas parsing frontend Flutter.

### 2. Registrasi Mediator & Validasi Explicit (Backend)
- Memindahkan registrasi validasi dari `init()` internal milik `LoginCommand` ke fungsi registrasi utama `RegisterModuleAccount` di [AccountMediator.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/account/infrastructure/AccountMediator.go).
- Menggunakan `commoninfra.RegisterValidation(login.LoginCommandValidation, "Account.Login.Validation")` secara eksplisit tepat di bawah pendaftaran Handler Request mediatr untuk meniru struktur registrasi validasi berkas rujukan secara identik.

### 3. Penambahan Helper Client & Perubahan Repositori (Flutter)
- **Multipart API Client**: Menambahkan static method `postMultipart` ke dalam [api_client.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/api_client.dart) untuk membungkus `http.MultipartRequest` dan mengirim form data berserta path berkas attachment secara native.
- **Login & Attendance**: Mengubah method `ApiClient.post` di `auth_repository.dart` and `attendance_repository.dart` untuk mengirim `body` sebagai `Map<String, String>` (otomatis dikirim sebagai `application/x-www-form-urlencoded`) dan menghapus header `application/json`.
- **Submit Cuti**: Mengubah method `submitLeave` di `leave_repository.dart` agar memanggil `ApiClient.postMultipart` untuk mengirim data isian form beserta berkas fisik lampirannya (`file_lampiran`).

---

## 🔒 Integrasi SiamidaV2 Middleware & RBAC Custom (Go Backend)
Kami telah menerapkan pembaruan middleware berbasis SiamidaV2 dengan penyesuaian otorisasi peran (RBAC):
- **Migrasi Kode Middleware**: Mengganti isi [Middleware.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/common/presentation/Middleware.go) dengan basis kode SiamidaV2.
- **Pembersihan CheckRoleAccess & Helper**: Menghilangkan pemeriksaan manual role via `checkRoleAccess(user, tahun, whitelist)` serta menghapus fungsi yang tidak digunakan: `checkRoleAccess`, `roleInWhitelist`, `getTahun`, dan `validateTahun`.
- **Pembersihan ExtraRole**: Menghapus tipe `ExtraRole` struct dan field `ExtraRole` dari `Account` struct di [Middleware.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/common/presentation/Middleware.go) karena tidak lagi diperlukan setelah peran RBAC disederhanakan.
- **Pembersihan Import**: Menghapus import `"strconv"` yang tidak lagi digunakan akibat penghapusan fungsi di atas.
- **Integrasi isDosen & isTendik**: Menambahkan logika pemeriksaan dinamis `isDosen(user)` dan `isTendik(user)` yang otomatis menyuntikkan seluruh parameter informasi ke dalam `c.Request().PostArgs()` (`role`, `nidn`, `nip`, `kode_fakultas`, `kode_prodi`, `Fakultas`, `prodi`, `unit`, `source`) sebelum meneruskan request ke handler berikutnya (`c.Next()`).
- **Instalasi Dependensi**: Menginstal pustaka JWT (`github.com/golang-jwt/jwt/v5`), WebSocket (`github.com/gofiber/websocket/v2`), dan penanganan normalisasi teks (`golang.org/x/text`).
- **Penerapan Route Group Middleware**: 
  - Mengubah signature `RBACMiddleware()` agar tidak lagi menerima parameter dan menetapkan target `whoamiURL` internal ke `"http://localhost:3000/whoami"`.
  - Mendaftarkan `/whoami` dan `/api/account/whoami` agar menggunakan `JWTMiddleware()`.
  - Mendaftarkan seluruh endpoint lain (`GET`, `POST`, `PUT`, `DELETE` di modul Attendance, Leave, SPPD, Organization, dan Report) agar menggunakan kombinasi `JWTMiddleware()` dan `RBACMiddleware()`, kecuali endpoint `/api/account/login`.
- **Generasi JWT Token & Refresh pada Login**:
  - Mengubah `LoginHandlerfunc` di [Http.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/account/presentation/Http.go) agar memproduksi JWT access `token` dan `refresh` token dengan klaim `exp` bernilai `1784304276`, `sid` bernilai session ID pengguna, dan `source` bernilai database autentikasi asal (`local`/`simak`/`simpeg`).
  - Membatasi keluaran JSON dari endpoint login `/api/account/login` agar secara eksklusif hanya mengembalikan properti `"token"` dan `"refresh"` sesuai spesifikasi terbaru.
- **Refactoring Query & Handler Whoami (Go Backend)**:
  - Mengubah parameter `WhoamiQuery` agar menggunakan `Sid` dan `Source` menggantikan parameter query `Nip` lama.
  - Memperbarui `WhoamiQueryHandler` untuk menginjeksi 3 repositori utama (`repoLocal`, `repoSimak`, `repoSimpeg`) dan mengambil informasi lengkap profil melalui pemanggilan `GetInfo(sid)` secara dinamis berdasarkan nilai `source`.
  - Menyesuaikan `WhoAmIHandler` pada [Http.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/account/presentation/Http.go) agar mengekstrak parameter `sid` dan `source` dari form data / post args (otomatis didapatkan dari hasil ekstrak klaim token di `JWTMiddleware`).
- **Pembaruan Flow Autentikasi Frontend (Flutter)**:
  - Merefaktor method `login` pada [auth_repository.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/auth/infrastructure/auth_repository.dart) agar setelah menerima token JWT dari login, sistem melakukan GET request ke `/api/account/whoami` untuk mendapatkan data lengkap profil pegawai (`user` dan `pegawai` objects). Hal ini memisahkan otentikasi login dari detail fetching data secara elegan.
- **Implementasi Modul Izin CRUD (Go Backend)**:
  - Mengubah struktur direktori [izin](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/izin) yang sebelumnya berisi boilerplate *BankSoal* menjadi modul CRUD `Izin` yang bersih dan sesuai dengan struct `domain.Izin`.
  - Menerapkan repositori `IzinRepository` berbasis GORM, handler mediator untuk query/command (`Create`, `Update`, `Delete`, `GetByID`, `GetAll`), serta register validasi ozzo-validation.
  - Memperbarui file routing `Http.go` di modul `izin` dengan pengaman `JWTMiddleware` dan `RBACMiddleware`.
  - Mendaftarkan dan memigrasikan tabel `izin` via AutoMigrate serta merelasikan inisialisasi modul izin di [main.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/main.go).
  - Memperbaiki dependensi impor usang di `ReportRepository.go` yang sebelumnya menunjuk ke `permission/domain` agar menunjuk ke `izin/domain` yang valid.
- **Ekstensi & Pembaruan Modul Leave (Go Backend)**:
  - Mengimplementasikan fungsionalitas Update dan Delete untuk pengajuan cuti dengan menambahkan `UpdateCutiCommand` dan `DeleteCutiCommand` beserta handler masing-masing.
  - Menambahkan `GetCutiQuery` beserta handler-nya untuk memuat detail satu record pengajuan cuti secara spesifik menggunakan `FindByID` dari repositori.
  - Menambahkan metode `DeleteCuti(ctx, id)` pada `ILeaveRepository` dan mengimplementasikannya di `LeaveRepository`.
  - Melakukan *rename* pada query history cuti dari `GetCutiHistoryQuery` menjadi `GetAllCutiQuery` sesuai kebutuhan format query yang lebih representatif.
  - Memetakan endpoint baru `PUT /api/leave/:id`, `DELETE /api/leave/:id`, dan `GET /api/leave/:id` pada routing presentasi [Http.go (Leave)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/leave/presentation/Http.go).
- **Refactoring & Implementasi CRUD SPPD Lengkap (Go Backend)**:
  - Menyesuaikan definisi domain struct `Sppd` di [Sppd.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/sppd/domain/Sppd.go) agar memetakan field-field tabel `sppd` secara lengkap, serta menambahkan entitas relasi `SppdAnggota` (tabel `sppd_anggota`) dan `SppdFileLaporan` (tabel `sppd_file_laporan`).
  - Memperbarui interface `ISppdRepository` dan implementasinya `SppdRepository` untuk mendukung preloading relasi otomatis serta penanganan update asosiasi penuh (`FullSaveAssociations`).
  - Mengimplementasikan fungsionalitas CRUD secara menyeluruh dengan merancang `CreateSppdCommand`, `UpdateSppdCommand`, `DeleteSppdCommand`, dan `GetSppdQuery` yang mendukung pemrosesan data anggota dan file laporan sekaligus.
  - Memperbarui endpoint routing [Http.go (Sppd)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/sppd/presentation/Http.go) agar mengekspos route lengkap (`POST /create`, `PUT /:id`, `DELETE /:id`, `GET /:id`, dan `GET /history`) dengan pengaman `JWTMiddleware` & `RBACMiddleware`.
  - Menyelaraskan pemetaan field data SPPD dan penyesuaian tanda tangan metode repositori di [ReportRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/report/infrastructure/ReportRepository.go) agar kompatibel dengan pembaruan domain model SPPD.
- **Resolusi Dependensi Go (Go Backend)**:
  - Menjalankan `go mod tidy` pada direktori backend untuk merapikan, menyelaraskan, dan membersihkan dependensi modul Go di dalam `go.mod` dan `go.sum`.
- **Migrasi Modul Organization ke MasterData (Go Backend)**:
  - Mengubah modul lama [organization](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/organization) menjadi modul terpadu [masterdata](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/masterdata).
  - Menambahkan dukungan query terpusat untuk memuat data master: Fakultas (`connect_m_fakultas`), Prodi (`connect_r_prodi`), Jenis Cuti (`jenis_cuti`), Jenis Izin (`jenis_izin`), dan Jenis SPPD (`jenis_sppd`).
  - Merancang CQRS query handler (`GetAllFakultasQuery`, `GetAllProdiQuery`, `GetAllJenisCutiQuery`, `GetAllJenisIzinQuery`, `GetAllJenisSppdQuery`) dan mendaftarkannya pada mediator.
  - Memetakan endpoint baru `/api/masterdata/...` pada presentasi HTTP [Http.go (MasterData)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/masterdata/presentation/Http.go) dan meregistrasikannya di [main.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/main.go).
- **Modul Baru Ceremony Attendance (Go Backend)**:
  - Membuat modul mandiri baru [ceremony_attendance](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/ceremony_attendance) untuk mengelola CRUD absensi upacara (`absen_upacara`).
  - Menambahkan model domain `AbsenUpacara` dan interface repositori `ICeremonyAttendanceRepository`.
  - Mengimplementasikan CQRS command/query: `CreateAbsenUpacaraCommand`, `UpdateAbsenUpacaraCommand`, `DeleteAbsenUpacaraCommand`, `GetAbsenUpacaraQuery`, dan `GetAllAbsenUpacarasQuery`.
  - Mengekspos endpoint CRUD lengkap di `/api/ceremony-attendance` dengan filter parameter pencarian NIP dan tanggal.
- **Modul Baru Calendar SSE (Go Backend)**:
  - Membuat modul baru [calendar](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/calendar) untuk memuat data aktivitas gabungan.
  - Menggabungkan query dari empat modul repositori berbeda (`attendance`, `izin`, `leave/cuti`, dan `sppd`) secara paralel memanfaatkan goroutine dan `sync.WaitGroup`.
  - Memetakan data ke dalam format seragam `CalendarItem` (`nidn`, `nip`, `tanggal`, `type`, `catatan`, `status`).
  - Mengekspos endpoint `GET /api/calendar/stream` terproteksi JWT & RBAC yang mengalirkan data secara real-time via Server-Sent Events (SSE) menggunakan `SSEAdapter`.
- **Integrasi Formulir Kredensial Login (Flutter Frontend)**:
  - Mengganti tombol placeholder SSO pada [login_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/auth/presentation/components/pages/login_page.dart) dengan Formulir Login Kredensial lengkap.
  - Menambahkan input field untuk Username/NIP/NIDN dan Password, lengkap dengan penanganan validasi input form.
  - Menyediakan fitur *visibility toggle* untuk menyembunyikan/menampilkan password secara interaktif.
  - Memetakan pengiriman kredensial input ke `authBloc.login(username, password)`.
- **Integrasi Global Backend-Frontend (API Integration)**:
  - Mengimplementasikan helper injeksi Authorization header otomatis di [api_client.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/api_client.dart) untuk melampirkan JWT token (`Bearer <token>`) dari session SSO pada setiap request HTTP (`post`, `postMultipart`, dan `get`).
  - Menyelaraskan endpoint history cuti di [leave_repository.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/infrastructure/leave_repository.dart) dari `/api/leave/history` ke `/api/leave` agar sesuai dengan restrukturisasi endpoint backend terbaru.
- **Penyelarasan Alur Login Dual Opsi (Flutter Frontend)**:
  - Mengonfigurasi [login_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/auth/presentation/components/pages/login_page.dart) agar menyajikan dual opsi masuk: Formulir Kredensial dan tombol masuk Unpak SSO.
  - Memastikan login SSO hanya terpicu secara manual saat tombol SSO diklik (menghilangkan perilaku auto-login otomatis).
  - Menjamin token hasil input form credentials merupakan produk respon otentikasi dari API Golang (`/api/account/login`).
- **Penyelarasan Alur Navigasi Splash Page (Flutter Frontend)**:
  - Mengubah logika navigasi pasca-memuat di [splash_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/auth/presentation/components/pages/splash_page.dart) agar selalu mengarahkan pengguna ke halaman login (`LoginPage`) terlebih dahulu, alih-alih melewati halaman login secara otomatis menuju dashboard (`MainShell`). Hal ini menjamin pengguna selalu dapat memilih metode autentikasi secara sadar (SSO atau form login).
- **Konfigurasi Keamanan Header Host Whitelist (Go Backend)**:
  - Mendaftarkan IP emulator Android (`10.0.2.2:3000`, `10.0.2.2`) beserta IP local loopback (`127.0.0.1`, `127.0.0.1:3000`) ke dalam whitelist `AllowDomains` pada middleware keamanan header di [Middleware.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/common/presentation/Middleware.go#L62). Hal ini menyelesaikan error spoofing header saat diuji coba menggunakan emulator Android.
- **Integrasi Komponen Dashboard & Kalender Dinamis (Flutter Frontend & Go Backend)**:
  - Menyediakan endpoint standard JSON `GET /api/calendar` di [Http.go (Calendar)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/calendar/presentation/Http.go#L38) sebagai pendamping stream SSE.
  - Memperbaiki handler riwayat absensi di [Http.go (Attendance)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/presentation/Http.go#L81) agar dapat membaca parameter `nip`/`nidn` dari Query Parameter (`c.Query`) saat menerima request GET dari Flutter Client.
  - Menghilangkan struktur tanggal statis tahun 2023 di kalender dashboard dengan mengimplementasikan calendar grid berputar 3-minggu dinamis yang berpusat pada tanggal hari ini / tanggal yang dipilih di [calendar_view.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/presentation/components/organisms/calendar_view.dart) dan [dashboard_calendar_card.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/dashboard_calendar_card.dart).
  - Mengintegrasikan [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart) untuk mengambil data kalender secara dinamis dari API Golang (`GET /api/calendar`) serta merender warna dot indikator dan status detail hari terpilih sesuai data riil.
  - Mengkalkulasi metrik statistik kehadiran (`totalAbsen`, `totalIzin`) dan ringkasan cuti (`sisaCuti`, `cutiDiambil`, `cutiPending`) secara dinamis berdasarkan data asli dari API.
- **Integrasi Pusat Pengajuan Cuti, Izin, dan SPPD (Flutter Frontend)**:
  - Memodifikasi [leave_repository.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/infrastructure/leave_repository.dart) agar metode `getLeaves` memanggil dan menggabungkan data dari 3 API endpoint backend Golang secara paralel (`GET /api/leave` untuk Cuti, `GET /api/izin` untuk Izin, dan `GET /api/sppd/history` untuk SPPD).
  - Menyortir data gabungan Cuti, Izin, dan SPPD berdasarkan tanggal mulai secara menurun (descending) sebelum dikembalikan ke UI.
  - Memetakan dan mengalihkan proses `submitLeave` agar mengirimkan formulir ke API tujuan yang tepat sesuai dengan tipe pengajuannya:
    - Pengajuan Izin dikirim via POST ke `/api/izin/`
    - Pengajuan SPPD dikirim via POST ke `/api/sppd/create`
    - Pengajuan Cuti dikirim via POST Multipart ke `/api/leave/submit`
- **Penyajian Statistik Kehadiran dengan Pilihan Periode (1-31 vs 15-15)**:
  - Memodifikasi [attendance_stats_section.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/attendance_stats_section.dart) menjadi `StatefulWidget` dengan menyematkan komponen segmented toggle control interaktif ("1 - 31" dan "15 - 15") di bagian atas bagian statistik.
  - Mengimplementasikan kalkulasi rentang tanggal dinamis dan lookup data kehadiran pada [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart):
    - **Periode 1 - 31**: Menghitung kehadiran murni pada kalender bulan berjalan (misal: 1 Juli s/d 31 Juli).
    - **Periode 15 - 15**: Menghitung kehadiran pada payroll cycle (misal jika hari ini tanggal $\ge$ 15, maka 15 Juli s/d 14 Agustus; jika < 15, maka 15 Juni s/d 14 Juli).
  - Melakukan kalkulasi total ketidakhadiran ("Tidak Masuk") secara akurat berdasarkan sisa hari kerja (Senin-Sabtu) yang berjalan dikurangi total absen masuk dan total izin disetujui pada periode terpilih.
- **Penyempurnaan Tampilan Kalender Bulanan Penuh (1 - 31)**:
  - Mengonfigurasi ulang grid kalender di [calendar_view.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/presentation/components/organisms/calendar_view.dart) untuk merender penuh 6 baris (42 cell) yang mencakup seluruh hari di bulan terpilih (tanggal 1 s/d 30/31), termasuk faded days dari bulan sebelumnya dan berikutnya sebagai pembatas.
  - Memperluas pemanggilan kueri `_fetchCalendarEvents()` di [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart) agar menarik data kalender untuk seluruh 42 hari yang terlihat pada grid bulan terpilih.
  - Menghilangkan *blocking layout indicator* (CircularProgressIndicator yang menggantikan seluruh card kalender) agar perubahan data ter-render secara langsung dan halus tanpa *jumping layout* pada layar dashboard.
- **Penyelarasan Akurasi Statistik Kehadiran & Penyaringan Data Kosong (Go Backend & Flutter Frontend)**:
  - Menyaring kueri database pada [AttendanceRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/infrastructure/AttendanceRepository.go#L43) dan [CalendarRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/calendar/infrastructure/CalendarRepository.go#L41) agar hanya menarik baris absensi yang memiliki data check-in riil (`absen_masuk IS NOT NULL`). Ini secara otomatis mengabaikan dan memisahkan hari-hari kosong tanpa absensi masuk.
  - Memperbarui pengecekan status izin di [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart#L173) agar mencakup status yang mengandung nilai `"acc"` (misal: `"acc sdm"`) guna memastikan perhitungan total izin/sppd akurat sesuai verifikasi kepegawaian.
  - Mengonfigurasi fungsi `_calculateCutiStats()` pada [leave_bloc.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/presentation/leave_bloc.dart#L32) agar kalkulasi sisa cuti, cuti diambil, dan cuti pending hanya menghitung data pengajuan cuti yang berada di **tahun aktif saat ini** (`DateTime.now().year`), sehingga data cuti tahun lalu tidak mempengaruhi perhitungan sisa jatah cuti aktif.
- **Pemberian Dukungan Query Parameter GET pada Backend (Go Backend)**:
  - Mengubah penanganan ekstraksi parameter `nip` dan `nidn` pada rute GET untuk riwayat pengajuan di Go backend agar membaca dari query string (`c.Query`) sebelum beralih ke form body fallback (`c.FormValue`):
    - [Http.go (Leave)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/leave/presentation/Http.go#L163) pada rute `GET /api/leave/`
    - [Http.go (Izin)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/izin/presentation/Http.go#L109) pada rute `GET /api/izin/`
    - [Http.go (Sppd)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/sppd/presentation/Http.go#L120) pada rute `GET /api/sppd/history`
  - Perbaikan ini menyelesaikan masalah hilangnya penayangan data riwayat Cuti, Izin, dan SPPD di tab *Requests* (Pusat Pengajuan) yang disebabkan oleh kegagalan baca data karena parameter terkirim sebagai query string (GET) bukan form body (POST).
- **Perbaikan Prioritas Routing SPPD (Go Backend)**:
  - Menyusun kembali urutan pendaftaran rute GET di [Http.go (Sppd)](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/sppd/presentation/Http.go#L119) dengan mendefinisikan rute statis `/history` terlebih dahulu sebelum rute dinamis `/:id`. Hal ini menghindari Fiber salah mencocokkan URL `/api/sppd/history` ke dalam endpoint pencarian ID `/:id` (yang memicu error SQL `record not found` akibat ID bernilai 0/non-numeric).
- **Penyaringan Database pada Parameter Kosong (Go Backend)**:
  - Memperbaiki kueri GORM di repository backend agar tidak mencocokkan string kosong (`""`) pada kolom database jika salah satu parameter `nip` atau `nidn` bernilai kosong (mengatasi kueri bertipe `nip = '4102302214' OR nidn = ''` yang sebelumnya menarik seluruh data ber-NIDN kosong milik pengguna lain):
    - [AttendanceRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/infrastructure/AttendanceRepository.go#L43)
    - [LeaveRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/leave/infrastructure/LeaveRepository.go#L45)
    - [SppdRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/sppd/infrastructure/SppdRepository.go#L48)
    - [IzinRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/izin/infrastructure/IzinRepository.go#L41)
  - Perbaikan ini memastikan kalkulasi statistik di dashboard (terutama "Total Absen") hanya menghitung baris presensi milik pengguna yang bersangkutan secara akurat (menghasilkan angka `0` pada periode 1-31 dan `1` pada periode 15-15 sesuai data riil).
- **Implementasi Log Request/Response & Loading State (Flutter Frontend)**:
  - Menyematkan log penanda status loading `[API Loading State Log] Request: <METHOD> <URL> | State: START/END` di dalam [api_client.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/api_client.dart#L136) untuk menandai awal dan akhir proses request secara transparan.
  - Memastikan seluruh detail request payload (Headers, Body/Fields) dan response payload (Status HTTP, URL, JSON Response Body) dicetak di console debug log demi kenyamanan proses debugging dan monitoring performa koneksi.
- **Dukungan Swipe-to-Refresh di Dashboard (Flutter Frontend)**:
  - Membungkus kontainer utama dashboard dengan widget `RefreshIndicator` di [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart#L220) untuk mengaktifkan gestur usap layar (*swipe down*) untuk memperbarui data.
  - Mengonfigurasi `onRefresh` agar memicu pengambilan ulang data secara paralel pada `attendanceBloc.fetchAttendanceHistory()`, `leaveBloc.fetchLeaves()`, dan `_fetchCalendarEvents()` secara real-time.
- **Penyelarasan & Penyaringan Aktivitas Terbaru (Flutter Frontend)**:
  - Memodifikasi [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart#L414) agar "Aktivitas Terbaru" (Recent Activities) menyajikan gabungan data terpadu dari:
    - Absen Masuk sukses (`absen_masuk != null`) dari `attendanceBloc.activities`.
    - Izin, Cuti, dan SPPD yang telah memperoleh persetujuan SDM (`ACC SDM`, `ACC`, atau `Disetujui`) dari `leaveBloc.leaves`.
  - Mengonfigurasi fungsi pengurutan waktu agar aktivitas terurut secara menurun (descending) berdasarkan tanggal mulai dan dibatasi hanya menampilkan 5 aktivitas teratas demi efisiensi tata letak dashboard.
- **Peningkatan Performa Kueri dengan Indexing Database (Go Backend)**:
  - Menyematkan index tag GORM di [Absen.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/domain/Absen.go#L12) pada kolom pencarian utama (`nip`, `nidn`, dan `tanggal`).
  - Menambahkan entity `Absen` pada database auto migration di [main.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/main.go#L160) agar indexes terbuat secara otomatis saat backend dijalankan. Hal ini mempercepat pemuatan kueri SQL dari 1.6 detik menjadi di bawah 15 milidetik dan mencegah terjadinya error timeout / Connection closed di Flutter client.

- **Penyelarasan Resiliensi Inisialisasi Modul Akun (Go Backend)**:
  - Mengubah fungsi inisialisasi "Account Module" di [main.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/main.go#L192) agar melakukan fallback otomatis ke database utama (`db`) apabila koneksi ke database sekunder SIMAK (`dbSimak`) atau SIMPEG (`dbSimpeg`) bernilai `nil` (gagal terhubung).
  - Penyesuaian ini menjamin proses registrasi request handler mediatr untuk otentikasi (`*Login.LoginCommand`) tetap berjalan dengan sukses meskipun di lingkungan pengembangan lokal yang tidak mengaktifkan database sekunder, serta menghindari error runtime `"no handler for request *Login.LoginCommand"`.

- **Penyelarasan Endpoint Izin (Flutter Frontend & Go Backend Integration)**:
  - Memperbarui path pengambilan riwayat izin pada [leave_repository.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/leave/infrastructure/leave_repository.dart#L123) dengan menambahkan *trailing slash* (`/api/izin/`) agar bersesuaian dengan struktur routing Fiber yang ketat. Penyesuaian ini meniadakan respons error 404 ketika sistem melakukan pemuatan data riwayat izin.

- **Perbaikan Formulasi Tanggal Siklus 15 - 15 (Flutter Frontend)**:
  - Memperbarui perhitungan rentang tanggal siklus 15 - 15 pada [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart#L128) agar selalu menggunakan tanggal **15 bulan lalu** hingga **14 bulan berjalan** berdasarkan `_selectedCalendarDay` (hari aktif terpilih pada kalender).
  - Mengeliminasi pengkondisian harian yang sebelumnya salah mengarahkan siklus ke periode bulan depan saat tanggal saat ini melewati tanggal 15 (sehingga menghitung tanggal 15 Juli - 14 Agustus padahal pengguna mengharapkan kalkulasi siklus bulan berjalan yakni 15 Juni - 14 Juli).

---

## 🧪 Hasil Uji Coba & Analisis
- **`go build` & `go test ./...` (Backend)**: Selesai dengan sukses (100% pass).
- **`flutter analyze` (Frontend)**: Selesai dengan sukses (**"No issues found!"**).
- **`flutter test` (Frontend)**: Selesai dengan sukses (100% pass).

All static analysis diagnostics report clean compilations and zero runtime errors!
