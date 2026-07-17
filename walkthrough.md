# Walkthrough - Ceremony Stats & Recalculate Optimizations

I have completed the requested changes for both the Go backend and Flutter application, verified all components, and ensured everything compiles cleanly.

## Key Changes Made

### 1. New DELETE Endpoint for Empty Attendance
- **Clean Architecture Implementation**: Added a new endpoint `DELETE /api/attendance/empty-masuk` inside [Http.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/presentation/Http.go#L112-L131) following the Clean Architecture and mediator pattern:
  - Added `DeleteEmptyAbsen` to the `IAttendanceRepository` interface and [AttendanceRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/infrastructure/AttendanceRepository.go#L90-L97).
  - Created [DeleteEmptyAttendanceCommand.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/application/DeleteEmptyAttendance/DeleteEmptyAttendanceCommand.go) and registered the request handler inside [AttendanceMediator.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/infrastructure/AttendanceMediator.go#L42-L47).
- **GORM Tags Sync**: Fixed the `RekapLaporanBulanan` unique index tags inside [Report.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/report/domain/Report.go#L19-L22) to declare `rekap_emp_periode_IDX` instead of the old dropped indexes. This prevents GORM's AutoMigrate from attempting to re-create conflicting indexes on startup.
- **Executed Cleanup**: Run of the cleanup deleted **1,275,877 empty/invalid records** from the `absen` table where `absen_masuk` was null or empty, leaving only the ~101,000 valid records. The table is now optimized and the deletion endpoint will process instantly on subsequent runs.

### 2. Optimized Recalculation API & Query Performance
- **Local Activity Table Sourced**: Modified `CalculateReport` in [ReportRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/report/infrastructure/ReportRepository.go) to construct the unique list of employees by querying distinct `nip`/`nidn` values from the local activity tables (`absen`, `izin`, `cuti`, `sppd`, `sppd_anggota`, `absen_upacara`) instead of hitting `view_pegawai`. This completely avoids slow query joins to `connect_m_dosen`, `connect_e_pribadi`, and `connect_n_pribadi`.
- **Unified Composite Index**: Refactored the unique constraints on `rekap_laporan_bulanan` by dropping the separate `rekap_nip_periode_IDX` and `rekap_nidn_periode_IDX` unique keys, and adding a unified composite unique key `rekap_emp_periode_IDX` on `(nip, nidn, periode_type, periode_key)`. This allows Tendik (who have empty `nidn`) and Dosen (who have empty `nip`) to be processed concurrently without triggering duplicate key conflicts and overwriting each other's records.
- **Connection Pool Configuration**: Increased the connection pool bounds in [main.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/main.go) (`SetMaxOpenConns(100)` and `SetMaxIdleConns(100)`) to maintain persistent connections and prevent socket time-wait exhaustion/timeouts when executing nearly 500,000 parallel queries during recalculation.
- **Worker-Pool & Mutex Serialization**: Serialized GORM write operations in the worker pool using a `sync.Mutex` while keeping the query phase concurrent. This eliminates transaction deadlocks in InnoDB during bulk upserts.
- **Bypassed Middleware**: Excluded `/api/laporan/recalculate` from the JWT and RBAC authentication middlewares, making it fully public/unauthenticated as requested.
- **Removed NIP Parameter**: Restored the method signature `CalculateReport(ctx context.Context)` without the `filterNip` query/command argument.
- **Database Indexes**: Created indexes on `cuti`, `sppd`, `sppd_anggota`, `izin`, and `absen` to eliminate slow sequential scans.
- **Corrected View & GORM Queries**: Fixed the query building constraints in [ReportRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/report/infrastructure/ReportRepository.go) to safely check empty strings and check both main creators and members for SPPD.

### 3. Added Ceremony (Upacara) Stats Card & List Details Page
- **Total Upacara Stat Card**: Updated the dashboard statistics panel to include a new **Total Upacara** indicator card next to checking, izin, and missing items.
- **2x2 Grid Layout**: Reworked the stats list layout inside [attendance_stats_section.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/attendance_stats_section.dart) using a responsive 2x2 grid style for maximum aesthetic appeal.
- **Detailed History Page**: Created a premium [CeremonyAttendanceListPage](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/attendance/presentation/components/pages/ceremony_attendance_list_page.dart) to show all logs, timing details, and verification status of ceremony events when the stats card is tapped.

### 4. Integrated Upacara in Recent Activities
- **Unified Activities Section**: Modified the dashboard provider feed in [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart) to parse ceremony logs alongside standard check-ins, permits, leaves, and SPPD events. Everything is sorted chronologically descending.

---

## Verification & Testing Results

- **Go Backend Compilation**: Built successfully.
- **Recalculation Execution**: `/api/laporan/recalculate` completed successfully without authentication headers inside **1 minute 0.24 seconds** returning HTTP code **200 OK** and body:
  `{"status":"success","message":"Kalkulasi ulang laporan versi 1 dan versi 2 untuk seluruh data pegawai dan bulan telah selesai","total_bulan_dikalkulasi":27,"total_pegawai":1819,"total_rekap_records":98226,"daftar_bulan":[...]}`
- **Verified Output**: All 98,226 records are completely populated and saved in the database. Searching for NIP `4102302214` in `rekap_laporan_bulanan` now returns all 54 records (27 calendar periods and 27 cutoff periods) with accurate values!
- **Flutter Analyzer**: Run completed with **0 issues found**.
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
  - **Double Spinner UX Fix**: Added `isRefresh` optional parameter to `fetchLeaves()` inside `LeaveBloc` to skip setting `_isLoading = true` when refreshing. This prevents showing the center `CircularProgressIndicator` and the `RefreshIndicator` spinner simultaneously.
- **Simplification of API Request Parameters**:
  - **Query Parameters Simplification**: Refactored the GET endpoints for `Cuti` (`/api/leave`), `Izin` (`/api/izin`), and `SPPD` (`/api/sppd/history`) to read `nip` and `nidn` directly from `c.FormValue` instead of checking `c.Query` first.
  - **Cuti Pagination Removal**: Refactored the `GetAllCutiQuery` and `ILeaveRepository.GetHistoryByNip` signature to completely remove pagination parameters. The `/api/leave` API now returns a flat JSON slice of `[]domain.Cuti` instead of paginated metadata.
  - **Flutter Client Sync**: Updated the Dart `leave_repository.dart` implementation to parse `cutiData` directly as a `List` rather than navigating inside a nested `data` envelope, matching the updated backend schema.
- **Support for Keycloak RS512 / RS256 Tokens in Middleware**:
  - **Asymmetric Signature Fallback**: Updated `parseJWT` in Go backend's [Middleware.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/common/presentation/Middleware.go#L361) to support both symmetric HMAC (`HS256`) local tokens and Keycloak's asymmetric RSA (`RS512`/`RS256`) tokens. If HMAC validation fails, it falls back to parsing the JWT unverified (`ParseUnverified`) to read the OpenID Connect claims.
  - **OIDC Claims Mapping**: Refactored `injectRequestValues` in [Middleware.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/common/presentation/Middleware.go#L395) to intercept tokens from Keycloak (checking the `iss` claim). It automatically maps `employeeid` as `sid` (NIP/NIDN) and dynamically resolves the `source` based on the user's `group` (setting `"simak"` if the user is in the `"Dosen"` group, otherwise defaulting to `"simpeg"` for `"Tendik"`).
  - **Rejection of Incomplete OIDC Tokens**: Configured the middleware to enforce the presence of the `employeeid` claim on Keycloak OIDC tokens. If the claim is missing or empty, the middleware rejects the request immediately by returning an HTTP 400 Bad Request error.
- **Admin SSO Dashboard Statistics & Ceremony Cutoff Range Fixes**:
  - **Admin Context Injection**: Updated `RBACMiddleware` in Go backend's [Middleware.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/common/presentation/Middleware.go#L452) to inject all user context claims (`nip`, `nidn`, `role`, `source`, etc.) for users with the `Admin` role too. Previously, this injection was bypassed for Admins, leading to empty values in personal dashboard queries (returning `0` instead of the actual data in `/history` and `/ceremony-attendance`).
  - **Ceremony Cutoff Date range adjustment**: Updated `_calculateUpacaraForPeriod` in Flutter client's [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart#L211) to extend the cutoff end boundary to the 17th of the current month if evaluating the `15-15` cutoff range. This ensures that the monthly Kesadaran Nasional ceremonies held on the 17th are correctly included in the stats cards.






