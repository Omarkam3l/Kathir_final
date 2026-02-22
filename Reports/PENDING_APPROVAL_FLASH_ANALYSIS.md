# Technical Report: Pending Approval Screen Flash Issue

**Date:** January 31, 2026  
**Issue:** Restaurant dashboard briefly shows "Pending approval" screen before displaying the actual dashboard, even when account is already approved  
**Severity:** Medium (UX degradation, no functional impact)  
**Status:** Root cause identified, solutions proposed

---

## Executive Summary

The application exhibits a race condition between router redirect logic and asynchronous profile data loading. When an approved restaurant user logs in or navigates to the dashboard, they briefly see the "Pending approval" screen before being redirected to the actual dashboard. This creates a jarring user experience and suggests a lack of account approval, even when the account is fully approved.

---

## Root Cause Analysis

### 1. **Async Profile Loading in AuthProvider**

The `AuthProvider` class loads user profile data asynchronously from Supabase:

```dart
// lib/features/authentication/presentation/blocs/auth_provider.dart
AuthProvider() {
  _loggedIn = _client.auth.currentSession != null;
  if (_loggedIn) {
    _syncUserProfile();  // ← ASYNC, no await
  }
  // ...
}
```

**Problem:** The constructor calls `_syncUserProfile()` without awaiting it. This means:
- `AuthProvider` is immediately marked as "ready"
- The router starts evaluating redirect logic
- Profile data (including `approval_status`) is still loading from the database

### 2. **Default Approval Status**

The `AuthUserView` getter returns user data with a fallback:

```dart
approvalStatus: (_userProfile?['approval_status'] as String?) ?? 'pending',
```

**Problem:** While `_userProfile` is `null` (during async load), the approval status defaults to `'pending'`, even for approved users.

### 3. **Router Redirect Logic**

The router's redirect function checks approval status synchronously:

```dart
// lib/features/_shared/router/app_router.dart
redirect: (context, state) {
  // ...
  if (user != null && user.needsApproval && !user.isApproved) {
    if (state.matchedLocation != '/pending-approval') {
      return '/pending-approval';  // ← Redirects to pending screen
    }
  }
  // ...
}
```

**Problem:** The router evaluates this logic immediately, before `_syncUserProfile()` completes. Since `approval_status` defaults to `'pending'`, the router redirects to `/pending-approval`.

### 4. **Subsequent Correction**

When `_syncUserProfile()` completes:
1. `_userProfile` is populated with actual data
2. `notifyListeners()` is called
3. Router re-evaluates redirect logic
4. User is now correctly identified as approved
5. Router redirects to `/restaurant-dashboard`

**Result:** The user sees the pending approval screen for 100-500ms (depending on network latency), then gets redirected to the dashboard.

---

## State Management & Async Loading Perspective

### The Core Problem: Synchronous Routing vs Asynchronous State

Modern Flutter routing (GoRouter) operates synchronously:
- It evaluates redirect logic immediately when navigation occurs
- It expects state to be available synchronously
- It cannot "wait" for async operations to complete

However, authentication state often requires async operations:
- Database queries for user profiles
- API calls for permissions/roles
- Token validation and refresh

This creates a fundamental mismatch:
```
Router needs: Synchronous state
Auth provides: Asynchronous state
Result: Race condition
```

### Why This Happens Regardless of State Management

This issue is **not specific to Provider** or any particular state management solution. It occurs because:

1. **Initialization Timing**: Any state management solution (Provider, Riverpod, Bloc, GetX) faces the same challenge - you cannot block app initialization waiting for async data
2. **Default Values**: To avoid null checks everywhere, developers use default/fallback values, which can be incorrect during loading
3. **Reactive Updates**: State management notifies listeners when data changes, but the initial evaluation happens before data is available

### The "Flash" Phenomenon

The visible "flash" occurs because:
1. **Frame 1**: Router evaluates with default/stale state → Shows wrong screen
2. **Frame 2-N**: Async operation completes → State updates → Listeners notified
3. **Frame N+1**: Router re-evaluates with correct state → Shows correct screen

The duration depends on:
- Network latency (database query time)
- Device performance
- State update propagation speed

---

## Impact Assessment

### User Experience
- **Confusion**: Users may think their account is still pending approval
- **Trust Issues**: Creates doubt about account status
- **Perceived Performance**: App feels slow or buggy
- **Accessibility**: Screen readers may announce the wrong state

### Technical Debt
- **Workarounds**: Developers may add artificial delays or loading screens
- **Testing Complexity**: Race conditions are hard to test reliably
- **Maintenance**: Future features may encounter similar issues

### Business Impact
- **User Retention**: Poor first impression after login
- **Support Tickets**: Users may contact support about "pending" status
- **Conversion**: Restaurant owners may abandon onboarding

---

## Solution Strategies

### Strategy 1: **Eager Profile Loading with Splash Screen** ⭐ RECOMMENDED

**Concept**: Load critical user data before showing any authenticated screens.

**Implementation**:
```dart
class AuthProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  AuthProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    _loggedIn = _client.auth.currentSession != null;
    if (_loggedIn) {
      await _syncUserProfile();  // ← AWAIT the profile load
    }
    _isInitialized = true;
    notifyListeners();
  }
}
```

**Router Changes**:
```dart
redirect: (context, state) {
  // Block navigation until auth is initialized
  if (!auth.isInitialized) {
    return '/splash';  // Show splash screen during initialization
  }
  
  // Now we can trust the approval status
  if (user != null && user.needsApproval && !user.isApproved) {
    if (state.matchedLocation != '/pending-approval') {
      return '/pending-approval';
    }
  }
  // ... rest of redirect logic
}
```

**Pros**:
- ✅ Eliminates race condition completely
- ✅ Clean separation of concerns
- ✅ Works with any state management solution
- ✅ Provides opportunity for branded splash screen

**Cons**:
- ⚠️ Slightly slower initial app load (but perceived as intentional)
- ⚠️ Requires splash screen implementation

---

### Strategy 2: **Optimistic State with Cache**

**Concept**: Cache the last known approval status locally and use it as the initial value.

**Implementation**:
```dart
class AuthProvider extends ChangeNotifier {
  static const _approvalStatusKey = 'cached_approval_status';
  
  AuthProvider() {
    _loggedIn = _client.auth.currentSession != null;
    if (_loggedIn) {
      _loadCachedApprovalStatus();  // Synchronous
      _syncUserProfile();  // Async update
    }
  }
  
  void _loadCachedApprovalStatus() {
    final cached = SharedPreferences.getInstance()
        .then((prefs) => prefs.getString(_approvalStatusKey));
    // Use cached value immediately
  }
  
  Future<void> _syncUserProfile() async {
    // ... existing code ...
    // Save approval status to cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_approvalStatusKey, approvalStatus);
  }
}
```

**Pros**:
- ✅ Fast initial render with likely-correct data
- ✅ No splash screen needed
- ✅ Graceful degradation if cache is stale

**Cons**:
- ⚠️ Still has race condition on first-ever login
- ⚠️ Cache invalidation complexity
- ⚠️ Potential for stale data if approval status changes

---

### Strategy 3: **Loading State with Skeleton UI**

**Concept**: Show a loading indicator or skeleton UI while approval status is being determined.

**Implementation**:
```dart
class AuthProvider extends ChangeNotifier {
  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;
  
  Future<void> _syncUserProfile() async {
    _isLoadingProfile = true;
    notifyListeners();
    
    try {
      // ... existing profile loading code ...
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }
}
```

**Router Changes**:
```dart
redirect: (context, state) {
  // Show loading screen while profile is loading
  if (auth.isLoadingProfile && state.matchedLocation != '/loading') {
    return '/loading';
  }
  
  // ... rest of redirect logic
}
```

**Pros**:
- ✅ Honest about loading state
- ✅ No incorrect information shown
- ✅ Simple to implement

**Cons**:
- ⚠️ Extra loading screen may feel slow
- ⚠️ Requires loading screen design
- ⚠️ Doesn't eliminate the underlying race condition

---

### Strategy 4: **Conditional Redirect with Guard**

**Concept**: Only check approval status after profile is confirmed loaded.

**Implementation**:
```dart
class AuthUserView {
  final bool isProfileLoaded;
  
  const AuthUserView({
    // ... existing fields ...
    this.isProfileLoaded = false,
  });
}
```

**Router Changes**:
```dart
redirect: (context, state) {
  final user = auth.user;
  
  // Only enforce approval check if profile is loaded
  if (user != null && user.isProfileLoaded) {
    if (user.needsApproval && !user.isApproved) {
      if (state.matchedLocation != '/pending-approval') {
        return '/pending-approval';
      }
    }
  }
  
  // ... rest of redirect logic
}
```

**Pros**:
- ✅ Minimal code changes
- ✅ Prevents incorrect redirects
- ✅ No additional screens needed

**Cons**:
- ⚠️ User might briefly see dashboard before redirect (if approval is revoked)
- ⚠️ Doesn't provide loading feedback
- ⚠️ Requires careful state management

---

## Recommended Implementation Plan

### Phase 1: Immediate Fix (Strategy 1 - Eager Loading)

**Why this approach:**
- Most robust solution
- Eliminates race condition at the source
- Provides best UX with branded splash screen
- Future-proof for additional initialization needs

**Implementation Steps:**

1. **Add initialization state to AuthProvider**
   ```dart
   bool _isInitialized = false;
   bool get isInitialized => _isInitialized;
   ```

2. **Make initialization async**
   ```dart
   Future<void> _initialize() async {
     _loggedIn = _client.auth.currentSession != null;
     if (_loggedIn) {
       await _syncUserProfile();
     }
     _isInitialized = true;
     notifyListeners();
   }
   ```

3. **Create splash screen**
   ```dart
   class AuthSplashScreen extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         body: Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               // App logo
               CircularProgressIndicator(),
               SizedBox(height: 16),
               Text('Loading your account...'),
             ],
           ),
         ),
       );
     }
   }
   ```

4. **Update router redirect logic**
   ```dart
   redirect: (context, state) {
     if (!auth.isInitialized) {
       return '/auth-splash';
     }
     // ... existing redirect logic (now safe to use)
   }
   ```

### Phase 2: Optimization (Strategy 2 - Add Caching)

Once the immediate issue is fixed, add caching for even faster subsequent loads:

1. Add `shared_preferences` dependency
2. Cache approval status after successful load
3. Use cached value as initial state
4. Update cache when approval status changes

### Phase 3: Monitoring

Add analytics to track:
- Time to profile load
- Frequency of approval status changes
- User navigation patterns after login

---

## Best Practices for Async State in Routing

### 1. **Separate Loading from Loaded State**
```dart
enum AuthState { uninitialized, loading, authenticated, unauthenticated }
```

### 2. **Use Explicit Loading Indicators**
Never rely on default values that could be misinterpreted as real data.

### 3. **Await Critical Data**
For data that affects routing decisions, always await before allowing navigation.

### 4. **Cache When Appropriate**
For data that changes infrequently (like approval status), caching provides better UX.

### 5. **Provide Feedback**
Always show loading states to users - silence creates anxiety.

### 6. **Test Race Conditions**
Use network throttling and delays to test async behavior:
```dart
// In tests
await Future.delayed(Duration(seconds: 2));
```

### 7. **Document Async Boundaries**
Clearly document which operations are async and what the default states mean.

---

## Testing Strategy

### Unit Tests
```dart
test('AuthProvider initializes with correct approval status', () async {
  final provider = AuthProvider();
  
  // Should not be initialized immediately
  expect(provider.isInitialized, false);
  
  // Wait for initialization
  await Future.delayed(Duration(milliseconds: 100));
  
  // Should now be initialized with correct status
  expect(provider.isInitialized, true);
  expect(provider.user?.approvalStatus, 'approved');
});
```

### Integration Tests
```dart
testWidgets('No flash of pending approval screen for approved users', (tester) async {
  // Setup: Mock approved user
  await tester.pumpWidget(MyApp());
  
  // Should show splash screen first
  expect(find.byType(AuthSplashScreen), findsOneWidget);
  
  // Wait for initialization
  await tester.pumpAndSettle();
  
  // Should go directly to dashboard, never showing pending screen
  expect(find.byType(RestaurantDashboardScreen), findsOneWidget);
  expect(find.byType(PendingApprovalScreen), findsNothing);
});
```

### Manual Testing Checklist
- [ ] Fresh login with approved account
- [ ] Fresh login with pending account
- [ ] App restart with active session (approved)
- [ ] App restart with active session (pending)
- [ ] Slow network conditions (throttled)
- [ ] Offline → online transition
- [ ] Approval status change while app is open

---

## Migration Path

### Step 1: Add Feature Flag
```dart
class FeatureFlags {
  static const useEagerProfileLoading = true;
}
```

### Step 2: Implement New Flow
Add new initialization logic alongside existing code.

### Step 3: A/B Test
Roll out to subset of users, monitor metrics.

### Step 4: Full Rollout
Once validated, remove old code and feature flag.

### Step 5: Cleanup
Remove any workarounds or temporary fixes.

---

## Conclusion

The "pending approval flash" issue is a classic race condition between synchronous routing logic and asynchronous state loading. While it doesn't affect functionality, it significantly degrades user experience and creates confusion.

**The recommended solution** is to implement eager profile loading with a splash screen (Strategy 1). This approach:
- Completely eliminates the race condition
- Provides the best user experience
- Is maintainable and future-proof
- Works with any state management solution

**Implementation effort**: ~4-6 hours
**Risk level**: Low (additive change, easy to rollback)
**User impact**: High positive (eliminates confusion)

The fix should be prioritized as a high-impact UX improvement that requires minimal development effort.

---

## Additional Resources

### Related Patterns
- **Initialization Pattern**: Separate app initialization from app rendering
- **Loading State Pattern**: Explicit loading states in state machines
- **Optimistic UI**: Show cached data while fetching fresh data

### Further Reading
- GoRouter documentation on async redirects
- Flutter state management best practices
- Race condition prevention in reactive systems

### Code References
- `lib/features/authentication/presentation/blocs/auth_provider.dart` (lines 45-75)
- `lib/features/_shared/router/app_router.dart` (lines 76-80)
- `lib/features/restaurant_dashboard/presentation/screens/restaurant_dashboard_screen.dart`

---

**Report prepared by:** Senior Mobile Application Engineer  
**Review status:** Ready for technical review  
**Next steps:** Discuss with team, prioritize implementation
