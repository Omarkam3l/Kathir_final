# 🧪 Testing Instructions - Restaurant Orders

**Status:** Ready for Testing  
**Date:** February 11, 2026

---

## 🎯 What We Fixed

The restaurant orders screen was showing empty even though 10 orders exist in the database. We've made the following fixes:

1. ✅ Fixed circular reference query error
2. ✅ Added comprehensive debug logging
3. ✅ Added visual debug info bar
4. ✅ Improved error handling

---

## 🚀 How to Test

### Step 1: Restart the App

```bash
# Hot restart (or press Shift+F5 in VS Code)
flutter run
```

### Step 2: Navigate to Orders Screen

1. Login as restaurant user
2. Tap "Orders" tab in bottom navigation

### Step 3: Check the Debug Info Bar

You should see a blue info box below the header that shows:

```
ℹ️ Loaded X orders | Filter: all | Loading: false
```

**What to look for:**
- If X = 10: ✅ Data loaded successfully!
- If X = 0: ❌ Data not loading (check console)

### Step 4: Check Console Logs

Look for these emoji markers in your console:

```
🔍 Loading orders for restaurant: [uuid]
📡 Executing query...
✅ Loaded 10 orders
📊 Filter: all
📦 First order: [order-id] - Status: pending
🎨 UI State - isLoading: false, orders count: 10
🎨 Building orders list with 10 orders
🎨 Building order card 0: [order-id]
🎨 Building order card 1: [order-id]
...
```

---

## ✅ Expected Results

### If Everything Works:

1. **Orders List Screen:**
   - See 10 order cards displayed
   - Each card shows: order code, customer name, status, amount, time
   - Debug info bar shows "Loaded 10 orders"
   - Console shows all debug messages with ✅ emoji

2. **Filters Work:**
   - Tap "Active" → Shows only active orders
   - Tap "Pending" → Shows only pending orders
   - Tap "All" → Shows all orders again

3. **Order Details:**
   - Tap any order card
   - See full order details
   - See customer info
   - See order items
   - See status buttons

4. **Pickup Verification:**
   - Tap "Verify Pickup" floating button
   - See QR scanner screen
   - Can enter OTP manually

---

## ❌ If Orders Still Don't Show

### Scenario A: Debug Info Shows "Loaded 0 orders"

**Problem:** Data not loading from database

**Check:**
1. Look for ❌ emoji in console
2. Look for error messages
3. Click bug icon (🐛) in app bar
4. Check if restaurant record exists
5. Check if orders have correct restaurant_id

**Solution:**
- Share console error messages
- Share debug screen info

### Scenario B: Debug Info Shows "Loaded 10 orders" but No Cards

**Problem:** UI not rendering

**Check:**
1. Look for 🎨 emoji in console
2. Check if "Building orders list" message appears
3. Check if "Building order card" messages appear
4. Look for any error in ActiveOrderCard

**Solution:**
- Share console logs
- Check if any error appears in red

### Scenario C: App Crashes or Freezes

**Problem:** Code error

**Check:**
1. Look for red error screen
2. Look for stack trace in console
3. Check if any null pointer exceptions

**Solution:**
- Share error message
- Share stack trace

---

## 🐛 Debug Tools Available

### 1. Debug Info Bar (NEW!)
**Location:** Orders screen, below header  
**Shows:** Order count, filter, loading state

### 2. Debug Screen
**Access:** Orders screen → Bug icon (🐛) in app bar  
**Shows:** User info, restaurant record, orders list

### 3. Console Logs
**Access:** Terminal or Debug Console  
**Shows:** Step-by-step execution with emoji markers

### 4. Refresh Button
**Location:** Orders screen, top right  
**Action:** Reload orders from database

---

## 📸 What to Share

If orders still don't show, please share:

1. **Screenshot of Orders Screen**
   - Show the debug info bar
   - Show if orders appear or not

2. **Console Logs**
   - Copy all messages with 🔍 📡 ✅ 📊 📦 🎨 emojis
   - Copy any ❌ error messages

3. **Debug Screen Info**
   - Click bug icon (🐛)
   - Click copy button
   - Share the copied text

---

## 🎉 Success Criteria

The issue is FIXED when:

- ✅ Orders list shows 10 order cards
- ✅ Debug info bar shows "Loaded 10 orders"
- ✅ Console shows all ✅ success messages
- ✅ Can tap order to see details
- ✅ Filters work correctly
- ✅ Can verify pickup with QR/OTP

---

## 🔄 After Testing

### If Orders Display Correctly:

We'll remove the debug info bar to clean up the UI:

```dart
// Remove this blue debug box
Container(
  padding: const EdgeInsets.all(8),
  child: Text('Loaded ${_orders.length} orders | Filter: $_selectedFilter'),
)
```

### If Orders Still Don't Display:

We'll investigate further based on:
- Console logs you share
- Debug screen info
- Error messages

---

## 📞 Quick Reference

**Files Modified:**
- `lib/features/restaurant_dashboard/presentation/screens/restaurant_orders_screen.dart`
- `lib/features/restaurant_dashboard/presentation/widgets/active_order_card.dart`

**Documentation:**
- `docs/restaurant_order_workflow_status.md` - Complete workflow status
- `docs/restaurant_orders_troubleshooting.md` - Troubleshooting guide
- `TESTING_INSTRUCTIONS.md` - This file

**Debug Tools:**
- Debug info bar (blue box on orders screen)
- Debug screen (bug icon in app bar)
- Console logs (terminal)

---

**Ready to Test!** 🚀

Run the app and check if orders now display on the orders screen.

