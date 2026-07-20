# Walkthrough - Holiday Integration, SSE Refactoring, Report Calculations, Transactions, Realtime Location Security Metadata, SPPD Member Tracking, Auto Check-In UI, and System VPN / Mock Location Integration

We have successfully integrated the `/holiday` endpoint, refactored data-listing endpoints to stream via Server-Sent Events (SSE), fixed the JWT token expiration time, corrected the report calculation cutoff periods, wrapped database modifications and report increments in a transaction block, and optimized the mobile client's dashboard to fetch calendar, holiday, and summary data concurrently, including shimmer loading states, reload options, a dedicated SPPD card, and realtime location metadata.

Additionally, we fixed the SPPD retrieval logic on both the backend report calculations and the history lookup endpoint to include SPPDs where the active user is registered as an **anggota** (member).

Furthermore, we updated the **AutoCheckInStatusCard** and **CameraScannerView** to display the security indicator flags (`Note: [G]`, `Note: [V]`) alongside the real-time IP and GPS text field.

Finally, we resolved a camera previewSize initialization crash and integrated robust, native security checks:
- **Fake GPS/Mock Location (`G`)**: Integrated the native package `detect_fake_location` to verify if the OS-reported position is simulated.
- **VPN to Campus Network (`V`)**: Implemented a robust mismatch check between the device's public WAN IP and the active local Wi-Fi interface IP range. If the public WAN IP matches the campus network block (`103.169.x.x`), but the local private IP on the Wi-Fi card does NOT match the campus local subnet (`10.200.0.0` - `10.205.255.255`), it is classified as a VPN.

## Changes Made

### Go Backend

#### [NEW] [TxContext.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/common/infrastructure/TxContext.go)
- Created helper to store/retrieve active GORM transactions inside context.

#### [MODIFY] [IReportRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/report/domain/IReportRepository.go)
- Exposed `GetDB() *gorm.DB` in the report repository interface.

#### [MODIFY] [ReportRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/report/infrastructure/ReportRepository.go)
- Implemented `GetDB() *gorm.DB` to retrieve GORM database connection instance.
- Updated `IncrementCounter` to support transactions via context using `commoninfra.GetTx(ctx, r.db)`.
- Corrected cutoff period keys format (removed `-CUTOFF` suffix).
- Adjusted cutoff V2 periods calculation to start on **16th of previous month** and end on **15th of current month** (exactly 30 days, no overlap).

#### [MODIFY] [SppdRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/sppd/infrastructure/SppdRepository.go)
- Updated write methods to support transactions via context.
- Modified `GetHistoryByNip()` to include SPPD documents where the user is listed in `sppd_anggota` table as a member.

#### [MODIFY] [AttendanceRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/attendance/infrastructure/AttendanceRepository.go)
- Updated write methods to support transactions via context.

#### [MODIFY] [CeremonyAttendanceRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/ceremony_attendance/infrastructure/CeremonyAttendanceRepository.go)
- Updated write methods to support transactions via context.

#### [MODIFY] [LeaveRepository.go](file:///Users/adamf/Documents/flutter_project/hrportalv2/backend/modules/leave/infrastructure/LeaveRepository.go)
- Updated write methods to support transactions via context.

#### [MODIFY] [CheckInCommand.go, CheckInUpacaraCommand.go, CreateAbsenUpacaraCommand.go, SubmitCutiCommand.go, CreateSppdCommand.go]
- Wrapped the database insertions and report counter increments inside a GORM transaction block (`db.Begin()`), committing only on success and rolling back completely on any errors.
- Passed transaction-context containing the active transaction down to all database operations.

### Flutter Client

#### [MODIFY] [pubspec.yaml](file:///Users/adamf/Documents/flutter_project/hrportalv2/pubspec.yaml)
- Installed `detect_fake_location` dependency to handle mock location security audits.

#### [MODIFY] [api_client.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/api_client.dart)
- Transparently decodes SSE event stream (`text/event-stream` / `data: ...` format) inside `processResponse`.

#### [MODIFY] [dashboard_page.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/pages/dashboard_page.dart)
- Shifted the Attendance Statistics cards calculation from local activity logs traversal to direct, remote API summary fetching via `/api/laporan/summary`.
- Refactored `_fetchCalendarEvents()` to run all 4 HTTP API calls (calendar, holiday, calendar summary, cutoff summary) in parallel using `Future.wait`.
- Added state-tracking variables `_calendarLoading` and `_calendarError` to control dashboard visual loading feedback.
- Separated `total_sppd` from `total_izin` into dedicated summary variables (`_totalSppd1To31`, `_totalSppd15To15`).
- Passed SPPD variables to the new `AttendanceStatsSection` properties.
- Implemented `PulsingSkeleton` widget to display a fading/pulsing shimmer card matching the calendar structure when data is fetching.
- Added `_buildCalendarError()` widget to display an error notification screen with a "Coba Lagi" reload button if any of the network requests fail.

#### [MODIFY] [attendance_stats_section.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/attendance_stats_section.dart)
- Expose parameters `totalSppd1To31` and `totalSppd15To15` inside the widget.
- Separated the visual layout to show **Total SPPD** as a dedicated card (Card 5) inside the statistics grid.

#### [MODIFY] [location_wifi_helper.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/core/location_wifi_helper.dart)
- Added `checkVpnActive()` helper scanning local network interfaces for active VPN tunnel indicators.

#### [MODIFY] [attendance_bloc.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/attendance/presentation/attendance_bloc.dart)
- Added `_gpsTimer` to run once every second, fetching the active user's location via `Geolocator`.
- Subscribed to `Geolocator.getPositionStream` with `distanceFilter: 0` for fine-grained coordinate updates.
- Added `isMocked` property utilizing `DetectFakeLocation().detectFakeLocation()` package checks to find Fake GPS (`G`).
- Added `_realIpLocal` variable tracking local private IP address.
- Updated `isVpn` property in real mode to check if the public WAN IP matches the campus block but the local local Wi-Fi IP does NOT match the campus local subnet range (`V`).

#### [MODIFY] [camera_scanner_view.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/attendance/presentation/components/organisms/camera_scanner_view.dart)
- Added a metadata panel displaying real-time metrics (`ip:`, `gps:`, `note:`).
- Fixed camera initialization crash by using null-aware accessors on `previewSize`.

#### [MODIFY] [auto_check_in_status_card.dart](file:///Users/adamf/Documents/flutter_project/hrportalv2/lib/modules/dashboard/presentation/components/organisms/auto_check_in_status_card.dart)
- Query `isMocked` and `isVpn` properties of `AttendanceBloc` inside `build` method using `Provider.of`.
- Appended `Note: [G,V]` security markers to the IP & GPS status text row for both successful and failed check-in status templates.

---

## Verification Results

### Report Database Verification
- Verified that all SQL queries compile cleanly under context-based transaction routing.
- Backend server compiled cleanly and is active locally.
