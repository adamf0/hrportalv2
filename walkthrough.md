# Walkthrough - Flutter Attendance Application (HR Portal / HR Connect)

We have successfully implemented the Flutter Attendance Application based on the design templates in the **Smart Motion HRIS** project from the Stitch MCP server, integrated **Unpak SSO** authentication, activated complete logout mechanics, and resolved all Gradle/JDK-related build failures on macOS.

Additionally, we have implemented **Automated Attendance Check-in** based on campus Wi-Fi IP ranges and GPS university coordinates, with a real-time status display card directly on the Dashboard.

Recently, we have resolved the face scanner rotation & conversion mechanics to improve ML Kit face recognition on physical Android front cameras (handling strides and mirroring), fixed form right layout overflows, redesigned the Requests tab to offer status-based filtering and search, expanded the Quick Menu section on the Dashboard to contain all 5 requested items linked directly to their forms and pages, and fully implemented the SPPD tab form matching Unpak templates.

---

## 🛠️ Changes Made

1. **Location & Wi-Fi Check Utility (`lib/core/location_wifi_helper.dart`)**:
   - Computes GPS distance constraints using the **Haversine formula**.
   - Contains a target latitude/longitude configuration for **Universitas Pakuan** (`-6.600109`, `106.814324`).
   - Checks if the user's active IP address matches Pakuan campus subnet rules: `103.169.*.*` (IPv4) or `2001:df0:3140::/32` (IPv6).
   - **Prioritized Public IP Resolution**: Always prioritizes fetching public internet IPs (via `api.ipify.org`) over local network interfaces. This correctly resolves public ISP IP subnets (like `103.169.193.133`) even when running within the NAT layer of the Android Emulator.
   - **GPS Redirect Settings Handler**: Redirects users to location settings when GPS services are off or location permissions are permanently denied.
   - **Startup Timeout Blocker (`getPublicIpWithTimeoutFallback`)**: Added an explicit blocking/awaiting network call (with a short 1.5-second timeout limit) on startup. This prevents the app from immediately returning the local NAT emulator IP (`10.0.2.16`) and flashing the error/warning card on launch.

2. **Real-time IP & GPS Tracker State (`lib/state/app_state.dart`)**:
   - **Real-time GPS Stream**: Subscribed to a geolocator position stream (`Geolocator.getPositionStream`) updating coordinates dynamically in real-time every 3 meters of physical movement.
   - **Real-time IP Polling**: Runs a background periodic timer checking active network interface connection IPs every 5 seconds.
   - **Dynamic Verification Evaluation**: Triggers the auto check-in validation constraint evaluation immediately whenever coordinates or IP address changes are detected. If the user moves within the radius or joins the campus Wi-Fi network, they are checked in automatically.
   - **Sensor Asli (Real-time) Default**: Configured `_useRealNetworkAndGps = true` by default, making actual device sensors the primary and only operational mode.
   - **Actual Local Time Check-in**: Replaced the hardcoded check-in time (`"08:15"`) with the actual current time (`DateTime.now()`) format (`HH:mm`), logged dynamically on auto check-in.
   - **Initial Evaluation Lifecycle Flag**: Added `isAutoCheckInEvaluating` flag. Set to `true` on login/initialization. Once the initial IP resolution and GPS query loops execute, the flag updates to `false`.
   - **Startup IP Verification Loop**: Added a startup loop attempting to fetch the real public IP up to 3 times (with 800ms delays). If it receives the loopback IP (`127.0.0.1`) or emulator NAT IP (`10.0.2.16`), it retries in the background.
   - **Login Reset Trigger**: Reset `isAutoCheckInEvaluating` to `true` and re-runs `_initRealTimeIpAndGpsTracking` inside the `login()` method. This ensures that whenever the user logs in (or is auto-logged in), a fresh detection cycle starts, and the blue loading card appears on Dashboard load.

3. **Dashboard Real-time Auto-Attendance Status Card (`lib/pages/dashboard_page.dart`)**:
   - Removed the mock simulation panel ("Di Kampus Pakuan" / "Di Luar Kampus" / "Gunakan Sensor Asli Switch") completely from the footer.
   - Added a new, beautiful, responsive Status Card directly under the "Jam Masuk" and "Jam Pulang" row:
     - **Loading / Processing State**: Displays while `isAutoCheckInEvaluating` is `true` (on first load/login), showing: `"Proses Absensi Otomatis... mencoba absen otomatis dari jaringan / gps unpak..."` and an animated progress bar.
     - **Success State**: Displays when the user is successfully checked in automatically via campus IP/GPS matching.
     - **Warning State**: Displays when evaluation completes and neither constraint is met (i.e. outside Universitas Pakuan and not on campus Wi-Fi), showing: `"sistem gagal absensi otomatis, perlu presensi manual oleh pengguna"`, showing raw detected real-time IP/GPS details, and featuring an overlay button for "Presensi Manual (Scan Wajah)" which navigates users to the liveness scanner tab index.

4. **LoginPage Redesign & Auto-Login (`lib/pages/login_page.dart`)**:
   - Removed all username and password text field inputs, form keys, and validations.
   - Implemented a single, beautiful "Masuk dengan Unpak SSO" action button.
   - Added a double-tap developer bypass on the branding logo which signs the user in directly as a demo user (helpful for offline/local testing).
   - **Active Session Redirect**: Added automatic check on startup. If a valid token exists, the login page automatically Wedding-authenticates and redirects the user directly to the dashboard.

5. **Tab Lifecycle-Aware Attendance Page (`lib/pages/attendance_page.dart`)**:
   - **Front Camera ML Kit Recognition Improvements**:
     - Handle mirrored image coordinates properly by checking absolute Head Euler Y angles (`yaw.abs() > 15.0`).
     - YUV420 to NV21 byte buffer conversion is rewritten to respect `bytesPerRow` row-stride on Android, preventing garbled frames on Xiaomi and standard mobile devices.
     - Automatically skips every 2 out of 3 video frames to reduce CPU load and keep execution smooth on lower-end devices.
     - Full console logging is integrated to debug face counts, orientations, bounding boxes, and head angles in real-time.
   - **Clean Simple Layout**: Removed the top navigation header row and the Kembali back navigation row, focusing the screen purely on liveness face scanning elements.
   - **Background Scanning Fix**: Reconfigured the simulated liveness scanner. The scanner now only runs if the user has actively opened the Attendance tab (`appState.currentTabIndex == 1`). If the user leaves the tab, the timer is cancelled and the progress resets.
   - **Checked-In State Handling**: If `appState.isCheckedIn` is already true, any active scanner timer is stopped, and the page renders a beautiful checkmark success screen telling the user they are already verified, disabling scanning triggers.

6. **Leave & Permission Management Forms (`lib/pages/leave_list_page.dart`, `lib/pages/leave_form_page.dart`)**:
   - Redesigned `leave_form_page.dart` completely to match Unpak Web Portal layout templates.
   - Now features 3 segmented tabs: **Form Cuti**, **Form Izin**, and **Form SPPD** (Perjalanan Dinas).
   - **Form Cuti** features:
     - 11 dropdown options for Cuti types.
     - Start/End date pickers.
     - Automatic duration calculation.
     - Reason field, document upload (up to 10MB), and supervisor selectors.
   - **Form Izin** features:
     - Date picker for single-day izin request.
     - 5 dropdown options for Izin types, reason, document upload, and supervisor selectors.
   - **Form SPPD** features:
     - 4 dropdown options for SPPD types.
     - Destination City text input field.
     - Start/End travel date pickers.
     - Automatic duration calculation.
     - Purpose, document upload, and supervisor selectors.
   - **Form Dropdowns Overflow Fix**: Added `isExpanded: true` to all type selection dropdown widgets to fix horizontal layout overflows on narrow mobile screens.

7. **Requests Tab Selector & Search Center (`lib/pages/leave_list_page.dart`)**:
   - Refactored the Requests tab into a stateful, rich status-based query dashboard.
   - Includes a search bar to index Cuti, Izin, or SPPD (Perjalanan Dinas) entries.
   - Offers 4 main tabs: **Semua**, **Cuti**, **Izin**, and **SPPD**:
     - **Semua Tab**: Groups all requests together under beautiful Indonesian day/date header sub-lists (e.g., `"Senin, 13 Juli 2026"`).
     - **Cuti, Izin, and SPPD Tabs**: Displays a flat descending date list of requests specific to that category without date header grouping.
   - Integrates horizontal status statistic badges (Pengajuan, Di ACC Atasan, ACC SDM, Sisa Cuti) at the top of the tab for high-fidelity summary viewing.

8. **Dashboard Quick Menu Upgrade (`lib/pages/dashboard_page.dart`)**:
   - Expanded the Quick Menu section to support exactly 5 menu items in a clean, scrollable horizontal row:
     - **Absensi**: Sets tab index to 1 (Attendance / face scanning page).
     - **Cuti**: Navigates directly to the Leave Form Page with **Form Cuti** tab active by default.
     - **Izin**: Navigates directly to the Leave Form Page with **Form Izin** tab active by default.
     - **SPPD**: Navigates directly to the Leave Form Page with **Form SPPD** tab active by default.
     - **Slip Gaji**: Sets tab index to 3 (Slip Gaji / Payroll).

9. **Dynamic Real-Time Payroll Slip (`lib/pages/salary_slip_page.dart`, `lib/state/app_state.dart`)**:
   - Integrated dynamic `POST` endpoint connection to `https://hrportal.unpak.ac.id/api/slip_gaji` carrying `nip`, `tahun`, and `bulan` parameters.
   - Deleted the Cetak Slip button and mapped the **Unduh PDF** action.
   - Renders the exact dot-matrix paper style salary sheet layout matching the Unpak templates (featuring thin black borders, signature fields, and total pendapatan/potongan sum blocks) for both Dosen and Pegawai employee profiles.

---

## 🛠️ Debug & Build Configuration Upgrades

To resolve the Gradle process build error with Java 21 (`jlink` JDK transformation failures with path_provider and core-for-system-modules):
- **Gradle Version Upgrade**: Upgraded Gradle Wrapper from version `8.3` to `8.7` in `gradle-wrapper.properties` to ensure compatibility with Java 21.
- **Gradle Plugins Upgrade**: Upgraded Android Application gradle plugin to `8.3.2` and Kotlin Android plugin to `1.9.24` in `settings.gradle`.
- **Placeholder Appending**: Used `+=` on `manifestPlaceholders` in `build.gradle` to append the OAuth redirect scheme instead of overwriting, preventing the manifest merger from missing `${applicationName}` placeholder values.
- **taskAffinity Lifecycle Fix**: Removed `android:taskAffinity=""` from `AndroidManifest.xml` to prevent intent dispatching in a separate task context, which was breaking the AppAuth state holding mechanism and causing immediate WebView exits.
- **CocoaPods UTF-8 Encoding**: Linked iOS workspace pods and verified compile-safe simulator builds by specifying UTF-8 locales:
  ```bash
  LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 pod install
  ```

---

## 🧪 Verification & Testing

### Automated Verification
- We ran `flutter analyze` ensuring zero static issues, compile errors, or warning-level issues:
  ```bash
  flutter analyze
  # Analyzing hrportalv2...
  # No issues found!
  ```
- We ran the widget test suite `test/widget_test.dart` to verify that the app builds and successfully loads the Login Page elements (Title, Welcome text, Unpak SSO button) without overflows:
  ```bash
  flutter test
  # 00:02 +1: HR Portal App SSO Smoke Test
  # 00:02 +1: All tests passed!
  ```

### Build Test Compilation
- Built a debug Android APK:
  ```bash
  flutter build apk --debug
  # ✓ Built build/app/outputs/flutter-apk/app-debug.apk
  ```
- Built an iOS Simulator application:
  ```bash
  LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 flutter build ios --simulator --no-codesign
  # ✓ Built build/ios/iphonesimulator/Runner.app
  ```
  Both builds completed successfully!
