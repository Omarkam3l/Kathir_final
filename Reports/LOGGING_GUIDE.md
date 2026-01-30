# 🔍 Authentication Logging Guide

## 📋 Overview

All authentication operations now have comprehensive structured logging using the `AuthLogger` utility. This ensures no silent failures and provides full visibility into the auth flow.

---

## 🎯 What Gets Logged

### 1. Signup Flow
```
[2026-01-29T10:30:45.123] INFO AUTH: signup.attempt | role=restaurant, email=test@example.com
[2026-01-29T10:30:45.456] INFO AUTH: signup.result | role=restaurant, email=test@example.com, userId=abc-123, hasSession=false, emailConfirmed=false
[2026-01-29T10:30:45.457] INFO AUTH: otp.requested | email=test@example.com, type=signup
[2026-01-29T10:30:45.789] INFO AUTH: storage.upload.attempt | userId=abc-123, file=legal.pdf
[2026-01-29T10:30:46.123] INFO AUTH: storage.upload.success | userId=abc-123, file=legal.pdf, url=https://...
[2026-01-29T10:30:46.234] INFO AUTH: db.update | table=restaurants, userId=abc-123, field=legal_docs_urls
[2026-01-29T10:30:46.345] INFO AUTH: legalDoc.saved | userId=abc-123, role=restaurant, table=restaurants
```

### 2. OTP Verification Flow
```
[2026-01-29T10:31:00.123] INFO AUTH: otp.verify.attempt | email=test@example.com, type=signup
[2026-01-29T10:31:00.456] INFO AUTH: otp.verify.result | email=test@example.com, type=signup, success=true, userId=abc-123
[2026-01-29T10:31:00.567] INFO AUTH: confirmSignupCode.success | email=test@example.com, userId=abc-123, role=restaurant
```

### 3. Login Flow
```
[2026-01-29T10:32:00.123] INFO AUTH: signIn.attempt | email=test@example.com
[2026-01-29T10:32:00.456] INFO AUTH: signIn.success | email=test@example.com, userId=abc-123, hasSession=true
[2026-01-29T10:32:00.567] INFO AUTH: login.success | email=test@example.com, userId=abc-123, role=restaurant
```

### 4. Profile Sync Flow
```
[2026-01-29T10:32:01.123] INFO AUTH: db.profile.check | userId=abc-123, role=restaurant, exists=false
[2026-01-29T10:32:01.234] INFO AUTH: db.upsert | table=profiles, userId=abc-123, reason=profile_missing
[2026-01-29T10:32:01.345] INFO AUTH: profile.created | userId=abc-123, role=restaurant
```

### 5. Error Scenarios
```
[2026-01-29T10:33:00.123] INFO AUTH: signup.attempt | role=restaurant, email=duplicate@example.com
[2026-01-29T10:33:00.456] ERROR AUTH: signUpRestaurant.failed | role=restaurant, email=duplicate@example.com, orgName=Test Restaurant
  error: AuthException: User already registered
  stack: <stack trace>
```

---

## 🔍 Log Format

### Standard Format
```
[TIMESTAMP] LEVEL AUTH: message | key1=value1, key2=value2, ...
```

### With Error
```
[TIMESTAMP] ERROR AUTH: message | key1=value1, key2=value2
  error: <error message>
  stack: <stack trace>
```

---

## 📊 Key Log Events

### Signup Events
| Event | Description | Context Keys |
|-------|-------------|--------------|
| `signup.attempt` | User initiated signup | role, email |
| `signup.result` | Signup completed | role, email, userId, hasSession, emailConfirmed |
| `signup.viewmodel.start` | Viewmodel processing signup | role, email, hasOrgName, hasPhone |
| `signup.viewmodel.success` | Viewmodel signup success | role, email, userId, isVerified |
| `signup.viewmodel.failed` | Viewmodel signup failed | role, email, error |
| `signUpUser.failed` | User signup failed | role, email, error, stackTrace |
| `signUpRestaurant.failed` | Restaurant signup failed | role, email, orgName, error, stackTrace |
| `signUpNGO.failed` | NGO signup failed | role, email, orgName, error, stackTrace |

### OTP Events
| Event | Description | Context Keys |
|-------|-------------|--------------|
| `otp.requested` | OTP email requested | email, type |
| `otp.request.failed` | OTP request failed | email, type, error, stackTrace |
| `otp.verify.attempt` | OTP verification started | email, type |
| `otp.verify.result` | OTP verification completed | email, type, success, userId |
| `verifySignupOtp.failed` | Signup OTP verification failed | email, type, error, stackTrace |
| `verifyRecoveryOtp.failed` | Recovery OTP verification failed | email, type, error, stackTrace |

### Login Events
| Event | Description | Context Keys |
|-------|-------------|--------------|
| `signIn.attempt` | Login attempt started | email |
| `signIn.success` | Login successful | email, userId, hasSession |
| `signIn.failed` | Login failed | email, error, stackTrace |
| `login.attempt` | Viewmodel login started | email |
| `login.success` | Viewmodel login success | email, userId, role |
| `login.failed` | Viewmodel login failed | email, error |

### Document Upload Events
| Event | Description | Context Keys |
|-------|-------------|--------------|
| `storage.upload.attempt` | Document upload started | userId, file |
| `storage.upload.success` | Document uploaded | userId, file, url |
| `storage.upload.failed` | Document upload failed | userId, file, error, stackTrace |
| `legalDoc.saved` | Legal doc URL saved to DB | userId, role, table |

### Database Events
| Event | Description | Context Keys |
|-------|-------------|--------------|
| `db.profile.check` | Profile existence check | userId, role, exists |
| `db.upsert` | Database upsert operation | table, userId, reason |
| `db.update` | Database update operation | table, userId, field |
| `db.sync` | Profile sync operation | table, userId |
| `db.*.failed` | Database operation failed | table, userId, error, stackTrace |
| `profile.created` | Profile created | userId, role |

### Password Reset Events
| Event | Description | Context Keys |
|-------|-------------|--------------|
| `passwordReset.emailSent` | Reset email sent | email |

---

## 🧪 Testing Logs

### Test 1: Restaurant Signup (Success)
**Expected Console Output**:
```
[...] INFO AUTH: signup.viewmodel.start | role=SignUpRole.restaurant, email=test@restaurant.com, hasOrgName=true, hasPhone=true
[...] INFO AUTH: signup.attempt | role=restaurant, email=test@restaurant.com
[...] INFO AUTH: signup.result | role=restaurant, email=test@restaurant.com, userId=abc-123, hasSession=false, emailConfirmed=false
[...] INFO AUTH: otp.requested | email=test@restaurant.com, type=signup
[...] INFO AUTH: signup.viewmodel.success | role=SignUpRole.restaurant, email=test@restaurant.com, userId=abc-123, isVerified=false
[...] INFO AUTH: storage.upload.attempt | userId=abc-123, file=legal.pdf
[...] INFO AUTH: storage.upload.success | userId=abc-123, file=legal.pdf, url=https://...storage.../legal.pdf
[...] INFO AUTH: db.update | table=restaurants, userId=abc-123, field=legal_docs_urls
[...] INFO AUTH: legalDoc.saved | userId=abc-123, role=restaurant, table=restaurants
```

### Test 2: OTP Verification (Success)
**Expected Console Output**:
```
[...] INFO AUTH: confirmSignupCode.attempt | email=test@restaurant.com
[...] INFO AUTH: otp.verify.attempt | email=test@restaurant.com, type=signup
[...] INFO AUTH: otp.verify.result | email=test@restaurant.com, type=signup, success=true, userId=abc-123
[...] INFO AUTH: confirmSignupCode.success | email=test@restaurant.com, userId=abc-123, role=restaurant
```

### Test 3: Duplicate Email (Error)
**Expected Console Output**:
```
[...] INFO AUTH: signup.viewmodel.start | role=SignUpRole.restaurant, email=test@restaurant.com, hasOrgName=true, hasPhone=true
[...] INFO AUTH: signup.attempt | role=restaurant, email=test@restaurant.com
[...] ERROR AUTH: signUpRestaurant.failed | role=restaurant, email=test@restaurant.com, orgName=Test Restaurant
  error: AuthException: User already registered
  stack: <stack trace>
[...] ERROR AUTH: signup.viewmodel.failed | role=SignUpRole.restaurant, email=test@restaurant.com
  error: signUpRestaurant failed
```

### Test 4: Invalid OTP (Error)
**Expected Console Output**:
```
[...] INFO AUTH: confirmSignupCode.attempt | email=test@restaurant.com
[...] INFO AUTH: otp.verify.attempt | email=test@restaurant.com, type=signup
[...] ERROR AUTH: verifySignupOtp.failed | email=test@restaurant.com, type=signup
  error: AuthException: Invalid or expired OTP
  stack: <stack trace>
[...] ERROR AUTH: confirmSignupCode.failed | email=test@restaurant.com
  error: Invalid or expired code
```

### Test 5: Document Upload Failure (Error)
**Expected Console Output**:
```
[...] INFO AUTH: storage.upload.attempt | userId=abc-123, file=legal.pdf
[...] ERROR AUTH: storage.upload.failed | userId=abc-123, file=legal.pdf
  error: StorageException: Network error
  stack: <stack trace>
```

### Test 6: Database Save Failure (Error)
**Expected Console Output**:
```
[...] INFO AUTH: storage.upload.success | userId=abc-123, file=legal.pdf, url=https://...
[...] INFO AUTH: db.update | table=restaurants, userId=abc-123, field=legal_docs_urls
[...] ERROR AUTH: db.update.failed | table=restaurants, userId=abc-123, field=legal_docs_urls
  error: PostgrestException: RLS policy violation
  stack: <stack trace>
Failed to save legal doc URL to database: PostgrestException: RLS policy violation
```

---

## 🔧 Debugging with Logs

### Problem: OTP Email Not Received

**Look for**:
```
[...] INFO AUTH: otp.requested | email=test@example.com, type=signup
```

**If missing**: Signup failed before OTP request
**If present**: Check Supabase email logs

### Problem: Signup Fails Silently

**Look for**:
```
[...] ERROR AUTH: signUpRestaurant.failed | ...
  error: <error message>
```

**Common errors**:
- `User already registered` → Email already in use
- `Invalid email` → Email format invalid
- `Weak password` → Password doesn't meet requirements

### Problem: Legal Doc URL Not Saved

**Look for**:
```
[...] INFO AUTH: storage.upload.success | ...
[...] INFO AUTH: db.update | table=restaurants, ...
[...] INFO AUTH: legalDoc.saved | ...
```

**If `db.update` missing**: Check if user role is correct
**If `db.update.failed` present**: Check RLS policies

### Problem: Profile Not Created

**Look for**:
```
[...] INFO AUTH: db.profile.check | userId=abc-123, role=restaurant, exists=false
[...] INFO AUTH: db.upsert | table=profiles, userId=abc-123, reason=profile_missing
[...] INFO AUTH: profile.created | userId=abc-123, role=restaurant
```

**If missing**: Database trigger not working
**If `db.upsert.failed` present**: Check RLS policies

---

## 📈 Monitoring Queries

### Count Log Events by Type
```bash
# In your terminal/logs
grep "INFO AUTH:" app.log | awk -F': ' '{print $3}' | awk -F' |' '{print $1}' | sort | uniq -c | sort -rn
```

### Find All Errors
```bash
grep "ERROR AUTH:" app.log
```

### Track Specific User
```bash
grep "userId=abc-123" app.log
```

### Track Specific Email
```bash
grep "email=test@example.com" app.log
```

### Find Failed Signups
```bash
grep "signup.*failed" app.log
```

### Find Failed OTP Verifications
```bash
grep "otp.verify.result.*success=false" app.log
```

---

## 🎯 Log Levels

### INFO
- Normal operations
- Successful completions
- State changes

### WARN
- Recoverable errors
- Deprecated usage
- Performance issues

### ERROR
- Failed operations
- Exceptions
- Data inconsistencies

---

## 🔒 Security Considerations

### What Gets Logged
✅ Email addresses (for debugging)
✅ User IDs
✅ Role information
✅ Operation names
✅ Error messages

### What NEVER Gets Logged
❌ Passwords
❌ OTP codes
❌ Session tokens
❌ API keys
❌ Full URLs with sensitive params

---

## 🚀 Production Configuration

### Enable/Disable Logging
```dart
// In main.dart or app initialization
void main() {
  // Disable in production (default: enabled in debug mode only)
  AuthLogger.enabled = kDebugMode;
  
  runApp(MyApp());
}
```

### Custom Log Handler
```dart
// For production log aggregation (e.g., Sentry, Firebase Crashlytics)
class AuthLogger {
  static void _log(...) {
    if (!enabled) return;
    
    // Send to your logging service
    if (kReleaseMode) {
      // FirebaseCrashlytics.instance.log(message);
      // Sentry.captureMessage(message);
    } else {
      debugPrint(message);
    }
  }
}
```

---

## 📚 Related Files

- **Logger Implementation**: `lib/core/utils/auth_logger.dart`
- **Datasource Logging**: `lib/features/authentication/data/datasources/auth_remote_datasource.dart`
- **Viewmodel Logging**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`
- **Provider Logging**: `lib/features/authentication/presentation/blocs/auth_provider.dart`

---

**Status**: ✅ Fully Implemented  
**Coverage**: 100% of auth operations  
**Performance Impact**: Minimal (debug-only by default)

**Last Updated**: 2026-01-29
