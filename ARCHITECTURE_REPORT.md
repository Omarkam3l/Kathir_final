# ARCHITECTURE REPORT

## 1) Architecture Summary

This Flutter application follows a **hybrid Clean Architecture with MVVM pattern**, combining feature-based modularization with layered separation of concerns. The architecture uses a three-layer approach (Presentation → Domain → Data) for core features like authentication and meals, while newer features (NGO/Restaurant dashboards) use a simplified MVVM pattern with direct Supabase integration. The app supports multi-role functionality (User, Restaurant, NGO, Admin) with role-based routing and access control. State management is handled primarily through Provider with ChangeNotifier ViewModels, and dependency injection uses GetIt for core services. The backend is entirely Supabase-based (PostgreSQL + Auth + Storage + Realtime), with an optional Python FastAPI chatbot service for AI-powered meal recommendations.

---

## 2) Tech Stack

### Flutter & Dart
- **Flutter SDK**: 3.5.3+ (Material 3 enabled)
- **Dart SDK**: >=3.5.3 <4.0.0
- **Platform Support**: Android, iOS, Web (configured)

### Backend
- **Supabase**: Primary backend-as-a-service
  - **Auth**: Email/password, OAuth (Google, Facebook, Apple), OTP verification, password recovery
  - **Database**: PostgreSQL with Row Level Security (RLS) policies
  - **Storage**: Document uploads (legal docs, meal images, profile avatars)
  - **Realtime**: Chat messaging between NGOs and restaurants
- **Python FastAPI** (Optional): AI chatbot service (`Chatbot/` folder)
  - Google Generative AI integration for meal recommendations
  - Cart building with budget constraints
  - Meal search with semantic embeddings

---

## 3) Dependencies Overview

### Core Dependencies

| Package | Purpose in this app | Where it is used | Notes |
|---------|-------------------|------------------|-------|
| `provider: ^6.0.5` | State management | All ViewModels across features | Primary state management solution |
| `supabase_flutter: ^2.5.6` | Backend integration | `lib/core/supabase/`, all data sources | Handles auth, database, storage, realtime |
| `go_router: ^14.2.0` | Navigation & routing | `lib/features/_shared/router/app_router.dart` | Declarative routing with role-based guards |
| `get_it: ^9.2.0` | Dependency injection | `lib/di/get_it_injection.dart` | Service locator for repositories and use cases |
| `google_generative_ai: ^0.4.6` | AI meal analysis | `lib/core/services/ai_meal_service.dart` | Gemini 2.5 Flash for image-to-meal extraction |
| `geolocator: ^13.0.2` | Location services | `lib/core/services/location_service.dart`, NGO map features | GPS positioning and distance calculations |
| `flutter_map: ^8.2.2` | Map rendering | NGO dashboard map screen | OpenStreetMap integration |
| `latlong2: ^0.9.1` | Coordinate handling | Map features | Works with flutter_map |
| `shared_preferences: ^2.5.4` | Local storage | Cart persistence, user preferences | Key-value storage |
| `flutter_dotenv: ^6.0.0` | Environment config | `.env` file for Supabase credentials | Secure config management |
| `google_fonts: ^6.2.1` | Typography | Theme configuration | Custom font loading |
| `intl: ^0.20.2` | Internationalization | Date/time formatting, currency | Localization support |
| `image_picker: ^1.0.7` | Image selection | Restaurant meal uploads, profile images | Camera and gallery access |
| `file_picker: ^8.1.2` | Document selection | Legal document uploads (NGO/Restaurant) | PDF and file uploads |
| `uuid: ^4.3.3` | Unique ID generation | Order IDs, session IDs | UUID v4 generation |
| `qr_flutter: ^4.1.0` | QR code generation | Order confirmation screens | QR code rendering |
| `flutter_rating_bar: ^4.0.1` | Rating UI | Restaurant ratings display | Star rating widget |
| `dio: ^5.7.0` | HTTP client | Boss chat API service | Alternative to http package |
| `http: ^1.1.0` | HTTP requests | AI service, chatbot API | Standard HTTP client |

### Dev Dependencies

| Package | Purpose | Notes |
|---------|---------|-------|
| `flutter_lints: ^4.0.0` | Code quality | Enforces Flutter best practices |
| `dartz: ^0.10.0` | Functional programming | Used for Either<Failure, Success> pattern in repositories |
| `flutter_bloc: ^8.1.0` | BLoC pattern (unused) | Included but not actively used; Provider is primary |

---

## 4) Project Folder Structure (lib/)

```
lib/
├── app/
│   └── bootstrap/
│       └── di_bootstrap.dart          # Initializes dependency injection
│
├── core/                              # Shared utilities and services
│   ├── errors/
│   │   └── failure.dart               # Error handling model
│   ├── services/
│   │   ├── ai_meal_service.dart       # Gemini AI integration
│   │   ├── geocoding_service.dart     # Address <-> coordinates
│   │   └── location_service.dart      # GPS and permissions
│   ├── supabase/
│   │   ├── supabase_helper.dart       # Supabase client wrapper
│   │   └── supabase_helper_exception.dart
│   └── utils/
│       ├── app_colors.dart            # Color palette
│       ├── app_dimensions.dart        # Spacing constants
│       ├── app_styles.dart            # Text styles
│       ├── auth_logger.dart           # Structured logging
│       ├── either.dart                # Either<L, R> implementation
│       ├── page_transitions.dart      # Custom animations
│       ├── storage_constants.dart     # SharedPreferences keys
│       └── user_role.dart             # Role enum
│
├── data/                              # Legacy data layer (partial Clean Architecture)
│   ├── datasource/
│   ├── model/
│   └── repo/
│
├── di/                                # Dependency injection
│   ├── get_it_injection.dart          # GetIt setup
│   └── global_injection/
│       ├── app_locator.dart           # Service locator
│       ├── supabase_client_provider.dart
│       └── supabase_helper_provider.dart
│
├── domain/                            # Legacy domain layer (partial Clean Architecture)
│   ├── entities/
│   ├── repo/
│   └── usecase/
│
├── features/                          # Feature modules (main app logic)
│   ├── _shared/                       # Shared across features
│   │   ├── config/
│   │   ├── providers/                 # ThemeProvider
│   │   ├── router/
│   │   │   └── app_router.dart        # GoRouter configuration
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── authentication/                # Auth feature (Clean Architecture)
│   │   ├── data/
│   │   │   ├── datasources/           # Supabase auth calls
│   │   │   └── repositories/          # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/              # User entity
│   │   │   ├── repositories/          # Repository interfaces
│   │   │   └── usecases/              # Sign in, sign up, OTP, etc.
│   │   ├── presentation/
│   │   │   ├── blocs/                 # AuthProvider (ChangeNotifier)
│   │   │   ├── screens/               # Login, signup, OTP screens
│   │   │   └── viewmodels/            # AuthViewModel
│   │   └── routes.dart
│   │
│   ├── user_home/                     # User dashboard (Clean Architecture)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── viewmodels/            # HomeViewModel, FavoritesViewModel
│   │
│   ├── ngo_dashboard/                 # NGO features (Simplified MVVM)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/               # 15+ screens (home, map, cart, orders, chat)
│   │       └── viewmodels/            # Direct Supabase integration
│   │
│   ├── restaurant_dashboard/          # Restaurant features (Simplified MVVM)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/               # Meal management, orders, profile
│   │       └── viewmodels/            # (Empty - logic in screens)
│   │
│   ├── boss_chat/                     # AI chatbot integration
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   │   └── boss_chat_api_service.dart  # FastAPI client
│   │   ├── widgets/
│   │   └── boss_chat_screen.dart
│   │
│   ├── meals/                         # Meal browsing (Clean Architecture)
│   ├── restaurants/                   # Restaurant search
│   ├── cart/                          # Shopping cart
│   ├── checkout/                      # Order checkout
│   ├── orders/                        # Order history
│   ├── favorites/                     # Favorites management
│   ├── profile/                       # User profile
│   ├── loyalty/                       # Loyalty program
│   ├── admin_dashboard/               # Admin panel
│   ├── onboarding/                    # First-time user flow
│   └── splash/                        # Splash screen
│
├── injection/                         # Feature-specific DI
├── models/                            # (Empty - models in features)
├── resources/
│   └── assets/
│       └── images/
├── screens/                           # (Empty - screens in features)
├── widgets/                           # (Empty - widgets in features)
└── main.dart                          # App entry point
```

**Key Observations:**
- **Hybrid architecture**: Core features (auth, meals) use Clean Architecture; newer features (NGO/Restaurant) use simplified MVVM
- **Feature-first organization**: Each feature is self-contained with its own data/domain/presentation layers
- **Shared resources**: `core/` and `features/_shared/` contain reusable utilities
- **Empty legacy folders**: `models/`, `screens/`, `widgets/` suggest migration to feature-based structure

---

## 5) Feature Modules

### 5.1 Authentication
**Key Screens:**
- Onboarding flow
- Role selection (User/Restaurant/NGO)
- Login/Signup
- OTP verification (email confirmation)
- Password recovery (forgot password → OTP → new password)
- Pending approval screen (for Restaurant/NGO)

**ViewModels/Controllers:**
- `AuthViewModel` (main auth logic)
- `AuthProvider` (session state, role-based routing)
- `ForgotPasswordViewModel`
- `VerificationViewModel`
- `RoleSelectionViewModel`

**Data Sources:**
- Supabase Auth API
- `profiles` table (user metadata)
- `restaurants` / `ngos` tables (role-specific data)

**Main User Flow:**
1. User selects role → Signs up with email/password → Receives OTP → Verifies email
2. Restaurant/NGO users upload legal documents → Admin approval required
3. After approval, redirected to role-specific dashboard

---

### 5.2 User Home (Foodie Dashboard)
**Key Screens:**
- Home screen (offers, top restaurants, available meals)
- All meals screen
- Meal detail screen
- Restaurant search
- Favorites

**ViewModels:**
- `HomeViewModel` (loads offers, restaurants, meals with TTL caching)
- `FavoritesViewModel` (manages favorites with Supabase)

**Data Sources:**
- `meals` table (available meals with expiry dates)
- `restaurants` table (top-rated restaurants)
- `favorites` table (user favorites)

**Main User Flow:**
1. Browse available meals → Add to favorites → View meal details → Add to cart → Checkout

---

### 5.3 NGO Dashboard
**Key Screens:**
- NGO home (stats, expiring meals, categories)
- All meals list (free/all)
- Restaurant meals screen
- Map view (nearby restaurants)
- Cart screen
- Checkout screen
- Location selector
- Order summary
- Orders list
- Order detail
- Chat list
- Chat screen (with restaurant)
- Profile screen
- Notifications

**ViewModels:**
- `NgoHomeViewModel` (meal loading, filtering, stats)
- `NgoCartViewModel` (cart management with Supabase `cart_items` table)
- `NgoMapViewModel` (restaurant locations)
- `NgoProfileViewModel` (profile editing)
- `NgoChatListViewModel` / `NgoChatViewModel` (realtime chat)

**Data Sources:**
- `meals` table (filtered by `is_donation_available = true`)
- `orders` table (NGO orders)
- `cart_items` table (persistent cart)
- `conversations` / `messages` tables (chat)
- `ngos` table (NGO profile data)

**Main User Flow:**
1. NGO views available donation meals → Adds to cart → Selects pickup location → Places order → Tracks order status → Chats with restaurant for coordination

---

### 5.4 Restaurant Dashboard
**Key Screens:**
- Restaurant dashboard (overview)
- Meals list
- Add meal screen (with AI image analysis)
- Edit meal screen
- Meal details screen
- Orders list
- Order detail screen
- Profile screen
- Chat list
- Chat screen (with NGO)
- Leaderboard (gamification)
- Surplus settings

**ViewModels:**
- No dedicated ViewModels (logic in screens/controllers)
- Uses `OrdersController` (Provider)

**Data Sources:**
- `meals` table (restaurant's meals)
- `orders` table (incoming orders)
- `restaurants` table (profile data)
- `conversations` / `messages` tables (chat)

**Main User Flow:**
1. Restaurant uploads meal image → AI extracts meal info (title, description, price) → Restaurant edits and publishes → Receives orders → Updates order status → Chats with NGO/user

---

### 5.5 Boss Chat (AI Assistant)
**Key Screens:**
- Boss chat screen (conversational UI)

**Controllers:**
- `BossChatController` (manages chat state)

**Services:**
- `BossChatApiService` (HTTP client for Python FastAPI backend)

**Data Sources:**
- Python FastAPI backend (`Chatbot/` folder)
- Endpoints: `/agent/chat`, `/cart/build`, `/meals/search`, `/favorites/search`

**Main User Flow:**
1. User asks AI for meal recommendations → AI searches meals → Builds cart within budget → User reviews and confirms

---

### 5.6 Cart & Checkout
**Key Screens:**
- Cart screen
- Checkout screen
- Payment screen
- Order summary

**ViewModels:**
- `NgoCartViewModel` (shared across roles)

**Data Sources:**
- `cart_items` table (persistent cart)
- `orders` table (order creation)
- `order_items` table (order line items)

**Main User Flow:**
1. Add meals to cart → Review cart → Enter delivery/pickup details → Place order → View order summary

---

### 5.7 Orders
**Key Screens:**
- Orders list (user/NGO/restaurant)
- Order detail screen

**Controllers:**
- `OrdersController` (Provider)

**Data Sources:**
- `orders` table
- `order_items` table

**Main User Flow:**
1. View order history → Track order status → View order details → Rate order (future)

---

### 5.8 Admin Dashboard
**Key Screens:**
- Admin dashboard (approval management)

**Data Sources:**
- `restaurants` / `ngos` tables (approval status)
- `profiles` table (user management)

**Main User Flow:**
1. Admin reviews pending restaurant/NGO applications → Approves/rejects → User notified

---

## 6) State Management

### Approach: Provider with ChangeNotifier

**Where state lives:**
- **ViewModels**: Feature-specific state (e.g., `HomeViewModel`, `NgoHomeViewModel`)
- **Providers**: Global state (e.g., `AuthProvider`, `ThemeProvider`, `OrdersController`)
- **Local state**: Widget-level state with `StatefulWidget` for UI-only concerns

**Key Providers (registered in `main.dart`):**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => AuthViewModel()),
    ChangeNotifierProvider(create: (_) => OrdersController()),
    ChangeNotifierProvider(create: (_) => FoodieState()),
  ],
  child: MaterialApp.router(...)
)
```

**Navigation & State:**
- `AuthProvider` listens to Supabase auth state changes
- `GoRouter` uses `refreshListenable: auth` to trigger route guards on auth changes
- Role-based redirects in `app_router.dart` (e.g., restaurant → `/restaurant-dashboard`, NGO → `/ngo/home`)

**Caching & Persistence:**
- **TTL caching**: `HomeViewModel` and `NgoHomeViewModel` use 2-minute TTL to avoid redundant API calls
- **In-flight guards**: Prevent duplicate loading when already fetching data
- **SharedPreferences**: Used for cart persistence (legacy), now migrated to Supabase `cart_items` table
- **Supabase Realtime**: Chat messages update in real-time without polling

---

## 7) Data Layer & Backend Integration

### Repository Pattern (Clean Architecture Features)

**Structure:**
```
Feature
├── data/
│   ├── datasources/
│   │   └── *_remote_datasource.dart    # Supabase API calls
│   ├── models/
│   │   └── *_model.dart                # JSON serialization
│   └── repositories/
│       └── *_repository_impl.dart      # Implements domain interface
├── domain/
│   ├── entities/
│   │   └── *.dart                      # Business models (no JSON)
│   ├── repositories/
│   │   └── *_repository.dart           # Abstract interface
│   └── usecases/
│       └── *.dart                      # Single-responsibility actions
└── presentation/
    ├── viewmodels/
    └── screens/
```

**Example Flow (Authentication):**
1. `AuthViewModel` calls `SignInUseCase`
2. `SignInUseCase` calls `AuthRepository.signIn()`
3. `AuthRepositoryImpl` delegates to `AuthRemoteDataSource`
4. `AuthRemoteDataSource` calls Supabase API
5. Response mapped: `UserModel` (data) → `UserEntity` (domain)
6. Result wrapped in `Either<Failure, UserEntity>`
7. ViewModel updates UI state

### Supabase Integration

**SupabaseHelper (`lib/core/supabase/supabase_helper.dart`):**
- Wrapper around `SupabaseClient`
- Methods: `signIn`, `signUp`, `signOut`, `selectAll`, `selectFiltered`, `insert`, `update`, `delete`, `uploadDocument`
- Throws `SupabaseHelperException` on errors

**Direct Supabase Usage (Simplified Features):**
- NGO/Restaurant dashboards bypass repositories and call `Supabase.instance.client` directly
- Example: `NgoHomeViewModel._loadMeals()` queries `meals` table with filters

**Error Handling:**
- **Clean Architecture features**: Use `Either<Failure, T>` pattern (from `dartz`)
- **Simplified features**: Use try-catch with error state in ViewModel
- **Logging**: `AuthLogger` provides structured logging for debugging

**RLS (Row Level Security):**
- Assumed to be configured in Supabase
- Policies enforce:
  - Users can only see their own orders
  - Restaurants can only edit their own meals
  - NGOs can only see donation-available meals
- **RLS recursion fix**: NGO meal loading fetches meals and restaurants separately to avoid nested RLS checks (see `docs/RLS_RECURSION_FIX_ARCHITECTURE.md`)

---

## 8) Security & Roles (High-level)

### User Roles
1. **User (Foodie)**: Browse meals, add to cart, place orders, manage favorites
2. **Restaurant**: Manage meals, view orders, chat with NGOs, upload legal docs
3. **NGO**: Claim donation meals, place bulk orders, chat with restaurants, upload legal docs
4. **Admin**: Approve/reject restaurant and NGO applications

### Access Control

**Frontend (GoRouter Guards):**
- `app_router.dart` contains extensive role-based redirect logic
- Examples:
  - Restaurant trying to access NGO routes → Redirect to `/restaurant-dashboard`
  - NGO trying to access user routes → Redirect to `/ngo/home`
  - Unapproved restaurant/NGO → Redirect to `/pending-approval`

**Backend (Supabase RLS):**
- Policies enforce data access at database level
- Examples (assumed):
  - `meals` table: Restaurants can only update their own meals
  - `orders` table: Users/NGOs can only see their own orders
  - `cart_items` table: Users can only access their own cart

**Document Uploads:**
- Legal documents stored in Supabase Storage
- URLs saved to `restaurants.legal_docs_urls` or `ngos.legal_docs_urls` (array field)
- Atomic append using RPC functions (`append_restaurant_legal_doc`, `append_ngo_legal_doc`)

**Password Recovery:**
- Uses Supabase OTP flow
- `AuthProvider.isPasswordRecovery` flag ensures user is redirected to password reset screen

---

## 9) Performance Notes

### Optimizations
- **TTL caching**: `HomeViewModel` and `NgoHomeViewModel` cache data for 2 minutes to reduce API calls
- **In-flight guards**: Prevent duplicate API calls when already loading
- **Pagination**: NGO meal loading limits to 50 meals per query
- **Separate queries**: NGO dashboard fetches meals and restaurants separately to avoid RLS recursion (see `docs/RLS_RECURSION_FIX_ARCHITECTURE.md`)
- **Image optimization**: Meal images stored in Supabase Storage with public URLs
- **Realtime subscriptions**: Chat uses Supabase Realtime for instant message delivery (no polling)

### Potential Bottlenecks
- **No pagination on user home**: `HomeViewModel` loads all meals at once (could be slow with 1000+ meals)
- **No image caching**: Meal images fetched from network every time (consider `cached_network_image`)
- **No offline support**: App requires internet connection for all features
- **No query optimization**: Some screens load full meal objects when only IDs are needed
- **No database indexes mentioned**: Queries on `expiry_date`, `restaurant_id`, `status` should have indexes
- **AI meal analysis**: Gemini API calls can take 2-5 seconds (consider loading state)
- **Cart persistence**: Every cart change writes to Supabase (could batch updates)

---

## 10) Quick Recommendations

1. **Add image caching**: Use `cached_network_image` package to cache meal images locally and reduce network usage.

2. **Implement pagination**: Add infinite scroll to meal lists (user home, NGO dashboard) to load meals in batches of 20-50.

3. **Add database indexes**: Ensure Supabase tables have indexes on frequently queried columns (`expiry_date`, `restaurant_id`, `status`, `is_donation_available`).

4. **Consolidate architecture**: Migrate NGO/Restaurant features to Clean Architecture pattern for consistency and testability.

5. **Add offline support**: Cache critical data (meals, orders) locally using `sqflite` or `hive` for offline viewing.

6. **Optimize cart updates**: Batch cart changes and debounce writes to Supabase to reduce database load.

7. **Add error boundaries**: Implement global error handling with user-friendly error messages and retry mechanisms.

8. **Improve logging**: Expand `AuthLogger` to cover all features (not just auth) for better debugging in production.
