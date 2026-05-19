# EcoAlert Screens Specification & Fix List

## Overview
All 9 screens must follow the design system: **AppColors**, **AppTextStyles**, **AppSpacing** from `lib/config/`.

---

## Screen 1: Splash Screen
**File:** `lib/screens/splash_screen.dart`  
**Status:** ❌ NEEDS FIXES

### Issues to Fix:
1. **Hardcoded Colors** → Replace with AppColors:
   - Line 78: `Colors.black` → `AppColors.bgPrimary` or `AppColors.bgElevated`
   - Line 98: `Colors.white` → `AppColors.textInverse`
   - Line 109: `Color(0x44ffffff)` → Use AppColors with opacity
   - Line 127: `Color(0x15ffffff)` → Use AppColors with opacity
   - Line 129: `Color(0x44ffffff)` → Use AppColors with opacity

2. **Typography Issues:**
   - Line 97-103: Replace inline TextStyle with AppTextStyles (create displayMed equivalent if needed)
   - Line 106-113: Replace inline TextStyle with AppTextStyles.label

3. **Add Import:**
   - `import '../config/app_colors.dart';`
   - `import '../config/app_text_styles.dart';`

### Expected Behavior:
- ✅ Smooth fade-in animation (800ms)
- ✅ Loading bar (3s animation)
- ✅ Auto-navigate after 3.5s to login or home based on auth status
- ✅ Responsive to screen size
- ✅ Status bar transparent with light icons

---

## Screen 2: Login Screen
**File:** `lib/screens/login_screen.dart`  
**Status:** ✅ MOSTLY WORKING (needs minor polish)

### Issues to Fix:
1. **Inconsistent Text Styling:**
   - Replace inline `TextStyle(...)` with AppTextStyles.displayMed, AppTextStyles.label, etc.
   - Audit lines: 214, 373-374, and any raw TextStyle declarations

2. **Polish:**
   - Ensure error messages use AppColors.danger
   - Verify all buttons use consistent padding/spacing from AppSpacing
   - Check password visibility toggle works smoothly
   - Verify "Forgot Password?" navigation works

3. **Functionality to Verify:**
   - ✅ Email validation works
   - ✅ Password validation works (min 6 chars)
   - ✅ Login button shows loading state
   - ✅ Error messages display clearly
   - ✅ Google Sign-In button present and styled correctly
   - ✅ Signup link navigates to signup screen
   - ✅ "Forgot Password?" opens reset flow

---

## Screen 3: Home Screen (Home Root)
**File:** `lib/screens/home_root.dart`  
**Status:** ✅ PRODUCTION READY

### Verify:
- ✅ Theme system used correctly (AppColors, AppTextStyles, AppSpacing)
- ✅ All cards display alerts, AQI, weather, floods
- ✅ Tapping cards navigates to detail screens
- ✅ Bottom navigation shows all 5 tabs: Home, Map, AQI Scan, Alerts, Community
- ✅ Profile icon in top-right navigates to profile screen
- ✅ Loading states display correctly

### No changes needed - use as reference for other screens

---

## Screen 4: Map Screen
**File:** `lib/screens/map_screen.dart`  
**Status:** ✅ MOSTLY GOOD (minor cleanup)

### Issues to Fix:
1. **Minor Style Issues:**
   - Line 739: Replace `Theme.of(context).textTheme.bodySmall` with `AppTextStyles.bodySmall`
   - Audit all Theme.of() calls and replace with AppTextStyles equivalents
   - Ensure all hardcoded spacing uses AppSpacing constants

2. **Verify Functionality:**
   - ✅ Map loads and displays (OpenStreetMap tiles)
   - ✅ Heatmap overlay shows AQI intensity correctly
   - ✅ Location marker updates based on GPS
   - ✅ Clicking hazard zones shows detail popups
   - ✅ Zoom controls work
   - ✅ Legend displays correctly

---

## Screen 5: AQI Detail Screen
**File:** `lib/screens/aqi_detail_screen.dart`  
**Status:** ❌ CRITICAL - Architecture Mismatch

### Issues to Fix:
1. **Replace Theme System:**
   - NOT using AppColors system - uses `Theme.of(context).colorScheme`
   - NOT using AppTextStyles - uses `theme.textTheme`
   - NOT using AppSpacing - uses raw EdgeInsets

   **Migration Steps:**
   - Remove all `Theme.of(context).colorScheme.*` → use `AppColors.*`
   - Remove all `theme.textTheme.*` → use `AppTextStyles.*`
   - Replace raw `EdgeInsets.all(16)` → `EdgeInsets.all(AppSpacing.p16)`

2. **Add Imports:**
   - `import '../config/app_colors.dart';`
   - `import '../config/app_text_styles.dart';`
   - `import '../config/app_spacing.dart';` (if exists)

3. **Color Mapping Guide:**
   - Background → `AppColors.bgSecondary`
   - Text primary → `AppColors.textPrimary`
   - Text secondary → `AppColors.textSecondary`
   - Accent → Use color based on AQI value (danger/warning/success)

### Verify Functionality:
- ✅ AQI index displays with correct color coding
- ✅ Health recommendations display based on AQI level
- ✅ Chart/graph renders correctly
- ✅ Refresh button updates data
- ✅ Back button returns to home/map

---

## Screen 6: AQI Scan Screen
**File:** `lib/screens/aqi_scan_screen.dart`  
**Status:** ❌ INCOMPLETE - Camera Placeholder

### Current Issue:
- Line 57 has placeholder text: "Camera preview placeholder (full implementation requires camera package)"
- Camera functionality NOT implemented

### Options to Fix:

**Option A: Show Placeholder with Mock Scan (Quick Fix)**
- Keep the placeholder
- Add a "Scan" button that returns mock AQI data
- Show "Scan Results" with sample AQI reading
- Add: "Tap the camera button to see sample AQI scan results"

**Option B: Implement Real Camera (Better)**
- Use `camera` package to access device camera
- Show live camera preview
- Add crosshair overlay
- Scan button triggers image capture
- Process image → return AQI estimate (via ML model or API)

### Recommended: Option A (faster) with note "Camera integration available via camera package"

### What to Implement:
```dart
// Add mock scan functionality
// When "Scan" button pressed:
// 1. Show camera/scanner animation
// 2. After 2s, display results
// 3. Show: "AQI: 185 (Unhealthy)" with color coding
// 4. Show recommendations based on AQI
// 5. "Save Result" button to add to history
```

### Verify Functionality:
- ✅ Theme colors correct (AppColors)
- ✅ Scan button works (shows results or camera)
- ✅ Results display properly formatted
- ✅ Can save or dismiss results
- ✅ No crashes when navigating

---

## Screen 7: Alerts Screen
**File:** `lib/screens/alerts_screen.dart`  
**Status:** ✅ PRODUCTION READY

### Verify:
- ✅ Theme system used correctly
- ✅ Alerts list displays all active alerts
- ✅ Color coding correct (danger/warning/success by severity)
- ✅ Tapping alert shows detail screen
- ✅ Can dismiss/close individual alerts
- ✅ Loading state shows when fetching alerts
- ✅ Empty state shows when no alerts

### No changes needed

---

## Screen 8: Community Screen
**File:** `lib/screens/community_screen.dart`  
**Status:** ⚠️ INCOMPLETE - Mock Data, No Search

### Issues to Fix:

1. **Mock Data Problem:**
   - Lines 43-85: Using hardcoded mock posts
   - **Fix:** Replace with empty initial state, load from Firestore

2. **Search Feature Not Working:**
   - Line 115: `showComingSoon(context, 'Search')` - incomplete
   - **Fix:** Implement search or disable button with tooltip

3. **Theme Polish:**
   - Line 292: Check emoji rendering ("📍" pin emoji)
   - Ensure all AppColors/AppTextStyles used consistently

### Implementation Changes:

```dart
// Option A: Mock Mode for Presentation
// Show 3-5 demo posts that don't change
// Disable search with tooltip: "Search coming soon"
// This is acceptable for FYP presentation

// Option B: Real Backend Integration (if time permits)
// Load posts from Firestore collection
// Implement search across post content + location
// Show real user posts (filtered by location)
```

### Recommended: Option A (mock mode is fine for presentation)

### Verify Functionality:
- ✅ Posts display correctly
- ✅ Theme colors applied (AppColors)
- ✅ User avatars show initials
- ✅ Verified badge shows correctly
- ✅ "Report" button at bottom navigates to report hazard
- ✅ No crashes when scrolling
- ✅ Search button disabled gracefully (with tooltip)

---

## Screen 9: Admin Dashboard
**File:** `lib/screens/admin_dashboard_screen.dart`  
**Status:** ✅ WORKING (needs style standardization)

### Issues to Fix:

1. **Inconsistent Text Styling:**
   - Audit all inline `TextStyle(...)` declarations
   - Replace with AppTextStyles equivalents
   - Example fixes: Lines 796-801 should use AppTextStyles.displayMed

2. **Color Issues:**
   - Line 870: `Colors.orange` hardcoded → use `AppColors.warning`
   - Audit for any other hardcoded colors → replace with AppColors

3. **Spacing Standardization:**
   - Mix of hardcoded padding and AppSpacing
   - Ensure consistency

### Verify Functionality:
- ✅ Admin role check works (shows only for admin users)
- ✅ Content management section loads
- ✅ Report management section shows pending reports
- ✅ System settings section displays options
- ✅ All buttons navigate correctly
- ✅ Navigation back works properly
- ✅ Theme colors applied correctly

---

## Summary: What Cursor Should Do

### Priority 1 (Critical - Screen Usability):
- [ ] **Screen 1:** Replace all hardcoded colors/styles with AppColors/AppTextStyles
- [ ] **Screen 5:** Migrate from Theme.of() to AppColors/AppTextStyles system
- [ ] **Screen 6:** Implement mock AQI scan results (or keep placeholder with note)
- [ ] **Screen 8:** Verify emoji rendering; ensure Community posts display without crashes

### Priority 2 (Polish - Consistency):
- [ ] **Screen 2:** Replace inline TextStyles with AppTextStyles
- [ ] **Screen 4:** Replace Theme.of() calls with AppTextStyles
- [ ] **Screen 9:** Standardize all inline TextStyles; fix hardcoded colors

### Priority 3 (Verification - Testing):
- [ ] Test all 9 screens on web/mobile for layout, navigation, functionality
- [ ] Verify no crashes when navigating between screens
- [ ] Confirm all buttons/interactions work as expected
- [ ] Check theme colors consistent across app

---

## Theme System Reference

### AppColors Location: `lib/config/app_colors.dart`
```dart
// Use these instead of hardcoded colors:
AppColors.primary          // Main brand color
AppColors.danger           // Red for high risk/AQI
AppColors.warning          // Orange/Yellow for medium risk
AppColors.success          // Green for safe/good
AppColors.textPrimary      // Dark text
AppColors.textSecondary    // Muted text
AppColors.textInverse      // Light text (on dark backgrounds)
AppColors.bgPrimary        // Background
AppColors.bgSecondary      // Secondary background
AppColors.bgCard           // Card/elevation background
AppColors.border           // Border color
```

### AppTextStyles Location: `lib/config/app_text_styles.dart`
```dart
// Use these instead of inline TextStyle():
AppTextStyles.displayMed   // Large headings
AppTextStyles.headline     // Section titles
AppTextStyles.titleMed     // Subsection titles
AppTextStyles.label        // Small labels
AppTextStyles.body         // Body text
AppTextStyles.bodySmall    // Small body text
```

### AppSpacing Location: `lib/config/app_spacing.dart` (if exists)
```dart
// Use constants like: AppSpacing.p8, p12, p16, p20, p24, etc.
// Or use: EdgeInsets.all(16) with consistent numbers
```

---

## Testing Checklist After Fixes

- [ ] Screen 1 (Splash): Auto-navigate works, animations smooth
- [ ] Screen 2 (Login): Can log in, errors show, Google Sign-In visible
- [ ] Screen 3 (Home): All cards display, navigation works
- [ ] Screen 4 (Map): Map loads, heatmap shows, zoom works
- [ ] Screen 5 (AQI Detail): Data displays, no Theme.of() errors
- [ ] Screen 6 (AQI Scan): Scan button works (mock or real)
- [ ] Screen 7 (Alerts): Alerts list shows, colors correct
- [ ] Screen 8 (Community): Posts display, no emoji crashes
- [ ] Screen 9 (Admin): Admin-only access works, all sections load
- [ ] **Navigation:** All screens reachable from tabs/buttons
- [ ] **Consistency:** All screens use AppColors/AppTextStyles
- [ ] **No Crashes:** App stable when navigating between all screens

