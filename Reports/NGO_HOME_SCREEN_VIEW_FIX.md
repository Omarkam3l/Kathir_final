# NGO Home Screen View Fix - Direct Implementation

## Problem
SQL queries return data correctly, but the View loads instantly without displaying any data. This indicates the ViewModel is not properly triggering UI updates or the initial load is not happening.

## Root Cause
The `loadIfNeeded()` is being called in `initState`, but the ViewModel might not be properly initialized or the loading state is completing before the UI can react.

---

## Fix 1: Update ngo_home_viewmodel.dart

Replace the entire `loadIfNeeded()` and `loadData()` methods:

```dart
/// Smart load: only fetch if data is missing or stale
Future<void> loadIfNeeded() async {
  // Always load on first call
  if (_lastFetchTime == null) {
    debugPrint('🔄 First load - fetching data...');
    await loadData();
    return;
  }
  
  // Skip if data exists and is fresh
  if (meals.isNotEmpty && !_isDataStale) {
    debugPrint('✓ Using cached data (${meals.length} meals)');
    return;
  }
  
  // Skip if already loading (in-flight guard)
  if (isLoading) {
    debugPrint('⏳ Already loading, skipping...');
    return;
  }
  
  debugPrint('🔄 Data stale or empty - fetching...');
  await loadData();
}

Future<void> loadData({bool forceRefresh = false}) async {
  debugPrint('📊 loadData called - forceRefresh: $forceRefresh, hasListeners: $hasListeners');
  
  // Skip if data is fresh and not forcing refresh
  if (!forceRefresh && meals.isNotEmpty && !_isDataStale) {
    debugPrint('✓ Data is fresh, skipping load');
    return;
  }
  
  isLoading = true;
  error = null;
  
  // CRITICAL: Notify immediately to show loading state
  if (hasListeners) {
    notifyListeners();
  }

  try {
    debugPrint('🔄 Starting data fetch...');
    await Future.wait([
      _loadStats(),
      _loadMeals(),
    ]);
    _lastFetchTime = DateTime.now();
    debugPrint('✅ Data fetch complete - ${meals.length} meals loaded');
  } catch (e) {
    error = e.toString();
    debugPrint('❌ Data fetch failed: $e');
  } finally {
    isLoading = false;
    if (hasListeners) {
      debugPrint('🔔 Notifying listeners - meals: ${meals.length}, error: $error');
      notifyListeners();
    }
  }
}
```

---

## Fix 2: Update ngo_home_screen.dart

Replace the `initState` method:

```dart
@override
void initState() {
  super.initState();
  debugPrint('🏠 NGO Home Screen - initState called');
  
  // Use addPostFrameCallback to ensure Provider is ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      debugPrint('🔄 Post-frame callback - loading data...');
      final viewModel = context.read<NgoHomeViewModel>();
      debugPrint('📊 ViewModel state - isLoading: ${viewModel.isLoading}, meals: ${viewModel.meals.length}');
      viewModel.loadIfNeeded();
    }
  });
}
```

---

## Fix 3: Add Debug Widget in ngo_home_screen.dart

Add this debug section right after the `_buildHeader` in the CustomScrollView slivers list (for temporary debugging):

```dart
// DEBUG: Add this temporarily after _buildHeader
SliverToBoxAdapter(
  child: Container(
    padding: const EdgeInsets.all(16),
    color: Colors.yellow.withOpacity(0.3),
    child: Consumer<NgoHomeViewModel>(
      builder: (context, vm, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('isLoading: ${vm.isLoading}'),
          Text('meals.length: ${vm.meals.length}'),
          Text('filteredMeals.length: ${vm.filteredMeals.length}'),
          Text('expiringMeals.length: ${vm.expiringMeals.length}'),
          Text('error: ${vm.error ?? "none"}'),
          Text('hasListeners: ${vm.hasListeners}'),
          ElevatedButton(
            onPressed: () => vm.loadData(forceRefresh: true),
            child: Text('Force Reload'),
          ),
        ],
      ),
    ),
  ),
),
```

---

## Fix 4: Ensure Provider is Properly Set Up

In your main.dart or wherever you set up the NGO routes, ensure the ViewModel is provided:

```dart
// Example route setup with Provider
GoRoute(
  path: '/ngo-home',
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => NgoHomeViewModel(),
    child: const NgoHomeScreen(),
  ),
),
```

If using a different routing approach, ensure the ViewModel is created BEFORE the screen:

```dart
// Alternative: Create ViewModel in parent widget
class NgoHomeWrapper extends StatelessWidget {
  const NgoHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        debugPrint('🏗️ Creating NgoHomeViewModel');
        return NgoHomeViewModel();
      },
      child: const NgoHomeScreen(),
    );
  }
}
```

---

## Fix 5: Check Supabase RLS Policies

Run this SQL to verify NGO users can read meals:

```sql
-- Test as NGO user
SELECT 
  id, 
  title, 
  quantity_available,
  status,
  is_donation_available
FROM meals 
WHERE is_donation_available = true 
  AND status = 'active' 
  AND quantity_available > 0
LIMIT 5;

-- Check RLS policies on meals table
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual
FROM pg_policies 
WHERE tablename = 'meals';
```

If no policies allow NGO users to read meals, add this policy:

```sql
-- Allow NGOs to view all active donation meals
CREATE POLICY "NGOs can view donation meals"
ON public.meals FOR SELECT
TO authenticated
USING (
  is_donation_available = true 
  AND status = 'active'
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'ngo'
  )
);
```

---

## Fix 6: Add Explicit Error Boundary

Wrap the Consumer in ngo_home_screen.dart with error handling:

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: Consumer<NgoHomeViewModel>(
        builder: (context, viewModel, _) {
          // Add explicit error display
          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${viewModel.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadData(forceRefresh: true),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadData(forceRefresh: true),
            child: CustomScrollView(
              slivers: [
                _buildHeader(isDark, viewModel),
                _buildSearchBar(isDark, viewModel),
                _buildStatsBar(isDark, viewModel),
                _buildFilterChips(isDark, viewModel),
                if (viewModel.expiringMeals.isNotEmpty)
                  _buildExpiringSoonSection(isDark, viewModel),
                _buildNearbySurplusHeader(isDark),
                viewModel.isLoading
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    : viewModel.filteredMeals.isEmpty
                        ? _buildEmptyState()
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => NgoMealCard(
                                  meal: viewModel.filteredMeals[index],
                                  isDark: isDark,
                                  onClaim: () => viewModel.claimMeal(
                                    viewModel.filteredMeals[index],
                                    context,
                                  ),
                                ),
                                childCount: viewModel.filteredMeals.length,
                              ),
                            ),
                          ),
              ],
            ),
          );
        },
      ),
    ),
    bottomNavigationBar: const NgoBottomNav(currentIndex: 0),
  );
}
```

---

## Fix 7: Force Initial State in ViewModel Constructor

Add this to the NgoHomeViewModel class:

```dart
class NgoHomeViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  bool isLoading = false; // CHANGED: Start as false, not true
  String? error;
  
  // ... rest of the code

  // Add constructor to log initialization
  NgoHomeViewModel() {
    debugPrint('🏗️ NgoHomeViewModel created');
    debugPrint('📊 Initial state - isLoading: $isLoading, meals: ${meals.length}');
  }
```

---

## Fix 8: Alternative - Use FutureBuilder Instead

If Provider is still not working, replace the entire body with FutureBuilder:

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  final viewModel = context.watch<NgoHomeViewModel>();

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: FutureBuilder(
        future: viewModel.meals.isEmpty ? viewModel.loadIfNeeded() : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && viewModel.meals.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadData(forceRefresh: true),
            child: CustomScrollView(
              slivers: [
                _buildHeader(isDark, viewModel),
                _buildSearchBar(isDark, viewModel),
                _buildStatsBar(isDark, viewModel),
                _buildFilterChips(isDark, viewModel),
                if (viewModel.expiringMeals.isNotEmpty)
                  _buildExpiringSoonSection(isDark, viewModel),
                _buildNearbySurplusHeader(isDark),
                viewModel.isLoading
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    : viewModel.filteredMeals.isEmpty
                        ? _buildEmptyState()
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => NgoMealCard(
                                  meal: viewModel.filteredMeals[index],
                                  isDark: isDark,
                                  onClaim: () => viewModel.claimMeal(
                                    viewModel.filteredMeals[index],
                                    context,
                                  ),
                                ),
                                childCount: viewModel.filteredMeals.length,
                              ),
                            ),
                          ),
              ],
            ),
          );
        },
      ),
    ),
    bottomNavigationBar: const NgoBottomNav(currentIndex: 0),
  );
}
```

---

## Testing Steps

1. **Hot Restart** (not hot reload) the app
2. Check console for debug messages:
   ```
   🏠 NGO Home Screen - initState called
   🔄 Post-frame callback - loading data...
   📊 ViewModel state - isLoading: false, meals: 0
   🔄 First load - fetching data...
   📊 loadData called - forceRefresh: false, hasListeners: true
   🔄 Starting data fetch...
   ✅ Stats loaded: Orders=X, Claimed=Y, Carbon=Zkg
   ✅ Loaded 15 meals, 3 expiring soon
   ✅ Data fetch complete - 15 meals loaded
   🔔 Notifying listeners - meals: 15, error: null
   ```

3. If you see the debug widget (yellow box), check the values
4. Click "Force Reload" button to manually trigger data load
5. Check if meals appear after force reload

---

## Quick Diagnostic

If data still doesn't appear, add this temporary test button in your app:

```dart
// Add anywhere in your UI temporarily
ElevatedButton(
  onPressed: () async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('meals')
        .select('id, title')
        .eq('is_donation_available', true)
        .eq('status', 'active')
        .limit(5);
    debugPrint('🧪 Direct query result: $res');
    debugPrint('🧪 Result length: ${(res as List).length}');
  },
  child: Text('Test Direct Query'),
),
```

This will confirm if the issue is with Supabase connection or the ViewModel logic.

---

## Most Likely Solution

Based on the symptoms (instant load, no data), the issue is likely:

1. **ViewModel not triggering initial load** - Fixed by changing `isLoading = false` in constructor
2. **Provider not properly connected** - Fixed by ensuring ChangeNotifierProvider wraps the screen
3. **RLS policies blocking NGO users** - Fixed by adding the SELECT policy for NGOs

Apply fixes 1, 2, 5, and 7 first. These are the most critical changes.
