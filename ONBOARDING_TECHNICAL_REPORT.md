# Onboarding Feature — Technical Report

## 1. What Was Removed

### Splash View
- **File removed:** `lib/features/splash/presentation/screens/splash_screen.dart`
- **Route change:** The route at path `'/'` previously built `SplashScreen`; it now builds `OnboardingFlowScreen`.
- **Route name:** `RouteNames.splash` was renamed to `RouteNames.onboarding` in `app_router.dart`.
- The old splash showed a logo with slide/fade animation and a single "Get Started" button that navigated to `/auth`. It had no first-launch logic and no persistence.

---

## 2. What Was Added

### Onboarding Feature (Clean Architecture)

**Data:**
- `lib/features/onboarding/data/onboarding_storage.dart`  
  - `hasSeenOnboarding()` and `setOnboardingComplete()` using `SharedPreferences` and key `has_seen_onboarding`.  
  - No business logic; only persistence.

**Presentation:**
- `lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart`  
  - Root screen at `'/'`.  
  - `FutureBuilder` on `OnboardingStorage.hasSeenOnboarding()`:  
    - **Loading:** `CircularProgressIndicator` (uses `AppColors.primary`).  
    - **Already seen:** `context.go('/auth')` in a post-frame callback.  
    - **First launch:** Renders `OnboardingScreen`.

- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`  
  - `PageView` with `NeverScrollableScrollPhysics` and 3 children.  
  - `PageController` for programmatic next/previous.  
  - On "complete" (Log In, Skip, Sign Up, Sign In):  
    - Calls `OnboardingStorage.setOnboardingComplete()`, then `context.go('/auth')`.  
  - No business logic in the UI; storage and navigation are delegated.

- `lib/features/onboarding/presentation/widgets/onboarding_pagination_dots.dart`  
  - Reusable dot indicator: active = `AppColors.primary` (wider), inactive = `AppColors.grey`.

- `lib/features/onboarding/presentation/widgets/onboarding_page_1.dart`  
  - "Rescue Food, Feed Hope." — header pill (eco + Kathir), hero image, Community Impact badge, gradient on "Feed Hope.", Get Started, "Already have an account? Log In", terms.

- `lib/features/onboarding/presentation/widgets/onboarding_page_2.dart`  
  - "Connect & Impact" — Back, Skip, image with "Reduce Waste" card, pagination dots, circular Next.

- `lib/features/onboarding/presentation/widgets/onboarding_page_3.dart`  
  - "Join the Movement" — Back, central gradient circle + `volunteer_activism`, floating `restaurant` and `diversity_1` badges, Sign Up, Sign In.

**Dependencies (pubspec.yaml):**
- `shared_preferences` for first-launch persistence.  
- `google_fonts` for Plus Jakarta Sans.

---

## 3. How the Onboarding Flow Works

1. **App start, `'/'`:**  
   - `OnboardingFlowScreen` runs.  
   - It reads `OnboardingStorage.hasSeenOnboarding()`.

2. **First launch (`hasSeenOnboarding == false`):**  
   - `OnboardingScreen` is shown (3-page `PageView`).  
   - **Page 1:** Get Started → next page; Log In → complete and go to `/auth`.  
   - **Page 2:** Back → previous; Skip → complete and go to `/auth`; Next (circle) → page 3.  
   - **Page 3:** Back → previous; Sign Up or Sign In → complete and go to `/auth`.  
   - On any "complete" action: `OnboardingStorage.setOnboardingComplete()` then `context.go('/auth')`.

3. **Later launches (`hasSeenOnboarding == true`):**  
   - `OnboardingFlowScreen` schedules `context.go('/auth')` in a post-frame callback.  
   - User goes straight to auth; onboarding is skipped.

4. **Routing:**  
   - `GoRouter` redirect logic is unchanged: `'/'` is allowed when not logged in; when logged in, `'/'` is redirected to home/dashboard.  
   - Onboarding only applies when not logged in and at `'/'`.

---

## 4. How Clean Architecture Was Respected

- **Data:**  
  - `OnboardingStorage` is the only place that talks to `SharedPreferences`.  
  - No UI or domain imports in the data layer.

- **Presentation:**  
  - Screens and widgets only:  
    - Call `OnboardingStorage` for read/write.  
    - Use `context.go('/auth')` for navigation.  
  - No use cases or repositories were added; the flow is simple and the storage API is used directly from the presentation layer, which is acceptable for a single persisted flag.

- **Feature layout:**  
  - `features/onboarding/data/` and `features/onboarding/presentation/` follow the existing feature structure.  
  - No domain/use case layer for this flag.

- **Reuse and separation:**  
  - `OnboardingPaginationDots` is reused on all three pages.  
  - Page widgets are `StatelessWidget`s; `OnboardingScreen` holds `PageController` and completion logic.  
  - Navigation and persistence stay out of the page widgets; they only receive `VoidCallback`s.

---

## 5. How AppColors Were Enforced

- **Centralisation:**  
  - All colors come from `lib/core/utils/app_colors.dart`.  
  - No `Colors.red`, `Colors.xyz`, or inline `Color(0xFF...)` in onboarding.

- **Primary = RED:**  
  - `AppColors.primary` = `0xFFD32F2F`.  
  - `AppColors.primaryDark` = `0xFFB71C1C`.  
  - `AppColors.primarySoft` = `0xFFEF5350`.  
  - `primaryAccent` and `secondaryAccent` point to `primary` and `primaryDark`.  
  - `brandRed` = `primary`.

- **Usage in onboarding:**  
  - Buttons, gradients, icons, shadows, and indicators use `AppColors.primary`, `primaryDark`, `primarySoft`, `primaryAccent`, `backgroundLight`, `backgroundDark`, `surfaceDark`, `white`, `black`, `darkText`, `grey`, `dividerLight`, `dividerDark`, `transparent`.  
  - Opacity is applied only via `.withOpacity()` on these `AppColors` values (e.g. `AppColors.primary.withOpacity(0.2)`), never on hardcoded colors.

---

## 6. Assets and Conventions

- **Images:**  
  - Page 1 and 2 use `lib/resources/assets/images/8040836.jpg`, matching the existing `lib/resources/assets/images/` setup and `pubspec.yaml`.  
  - `errorBuilder` falls back to an icon + `AppColors.primary` tint.

- **Icons:**  
  - Material Icons: `Icons.eco`, `Icons.volunteer_activism`, `Icons.arrow_forward`, `Icons.arrow_back`, `Icons.restaurant`, `Icons.diversity_1`, `Icons.person`.

- **Fonts:**  
  - Plus Jakarta Sans via `GoogleFonts.plusJakartaSans()` for titles and body text.

---

## 7. Summary

- **Removed:** Splash screen and its route; `'/'` now shows the onboarding flow or a redirect to auth.  
- **Added:** 3-page onboarding, `OnboardingStorage`, `OnboardingFlowScreen`, and small reusable widgets, all under `features/onboarding` and using `AppColors` only.  
- **Flow:** First launch → onboarding; later launches → redirect to `/auth`.  
- **Architecture:** Data (storage) and presentation (screens, widgets) are separated; no new patterns beyond what the project already uses.  
- **Theme:** Primary and accents are red; gradients use `primary` / `primaryDark` / `primarySoft` from `AppColors`.
