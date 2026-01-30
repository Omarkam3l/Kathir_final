# 🔍 WHAT TO LOOK FOR IN LOGS

## Current Error (Not Helpful)

```
[2026-01-29T19:19:55.178] ERROR AUTH: signup.viewmodel.failed | 
role=SignUpRole.restaurant,email=mohamedelekhnawy324@gmail.com
error: signUpRestaurant failed
```

**Problem**: This is a generic wrapper error. We need the ACTUAL Supabase error.

---

## What You Should See After Deploying Migration

### ✅ Successful Signup Flow

```
[timestamp] INFO AUTH: signup.viewmodel.start | role=SignUpRole.restaurant, email=..., hasOrgName=true, hasPhone=true

[timestamp] INFO AUTH: signup.attempt | role=restaurant, email=...

[timestamp] INFO AUTH: signUpRestaurant.metadata | email=..., fullName=..., orgName=..., hasPhone=true, role=restaurant

[timestamp] INFO AUTH: signup.result | role=restaurant, email=..., userId=abc-123-def, hasSession=false, emailConfirmed=false

[timestamp] INFO AUTH: otp.requested | email=..., type=signup

[timestamp] INFO AUTH: signup.viewmodel.success | role=SignUpRole.restaurant, email=..., userId=abc-123-def, isVerified=false
```

**This means**: Signup succeeded, OTP email sent, waiting for verification.

---

## ❌ If Still Failing - Look For These Logs

### 1. Supabase Auth Error (Most Important)

```
[timestamp] ERROR AUTH: signUpRestaurant.authException | 
role=restaurant, 
email=..., 
orgName=..., 
statusCode=500, 
message=Database error saving new user
```

**What it tells us**:
- `statusCode=500` → Server error (database issue)
- `message=Database error saving new user` → Trigger failed

**Possible causes**:
- Migration not deployed
- Trigger has syntax error
- Constraint violation
- RLS policy blocking

### 2. Generic Error (Less Helpful)

```
[timestamp] ERROR AUTH: signUpRestaurant.failed | 
role=restaurant, 
email=..., 
orgName=..., 
errorType=PostgrestException
```

**What it tells us**:
- Error type (PostgrestException, AuthException, etc.)
- But not the specific message

### 3. User Already Exists

```
[timestamp] ERROR AUTH: signUpRestaurant.authException | 
statusCode=422, 
message=User already registered
```

**Fix**: Delete existing user or use different email

### 4. Invalid Email

```
[timestamp] ERROR AUTH: signUpRestaurant.authException | 
statusCode=422, 
message=Invalid email
```

**Fix**: Use valid email format

### 5. Weak Password

```
[timestamp] ERROR AUTH: signUpRestaurant.authException | 
statusCode=422, 
message=Password should be at least 6 characters
```

**Fix**: Use stronger password

### 6. Rate Limit

```
[timestamp] ERROR AUTH: signUpRestaurant.authException | 
statusCode=429, 
message=Email rate limit exceeded
```

**Fix**: Wait 1 hour or use different email

---

## 🎯 What to Share If Still Failing

### Required Information

1. **Complete log sequence** (from signup attempt to error):
   ```
   [timestamp] INFO AUTH: signup.viewmodel.start | ...
   [timestamp] INFO AUTH: signup.attempt | ...
   [timestamp] INFO AUTH: signUpRestaurant.metadata | ...
   [timestamp] ERROR AUTH: signUpRestaurant.authException | ...
   ```

2. **Verification query results**:
   ```sql
   -- Run in Supabase SQL Editor
   SELECT is_nullable, column_default
   FROM information_schema.columns
   WHERE table_name = 'restaurants' 
     AND column_name = 'restaurant_name';
   ```

3. **Trigger check**:
   ```sql
   SELECT tgname, tgenabled 
   FROM pg_trigger 
   WHERE tgname = 'on_auth_user_created';
   ```

4. **User existence check**:
   ```sql
   SELECT id, email, created_at, email_confirmed_at
   FROM auth.users 
   WHERE email = 'mohamedelekhnawy324@gmail.com';
   ```

---

## 🔬 Advanced Debugging

### Check Postgres Logs in Supabase

1. Go to Supabase Dashboard
2. Click **Logs** (left sidebar)
3. Select **Postgres Logs**
4. Filter by last 5 minutes
5. Look for errors related to:
   - `handle_new_user`
   - `profiles`
   - `restaurants`
   - `NOT NULL constraint`

### Example Postgres Error

```
ERROR: null value in column "restaurant_name" violates not-null constraint
DETAIL: Failing row contains (abc-123-def, null, ...).
CONTEXT: SQL statement "INSERT INTO public.restaurants ..."
PL/pgSQL function handle_new_user() line 45
```

**This tells us**: Migration not deployed (restaurant_name still NOT NULL)

---

## 📊 Log Interpretation Guide

### Log Level Meanings

- **INFO**: Normal operation, everything working
- **WARN**: Something unusual but not critical
- **ERROR**: Operation failed, needs attention

### Key Log Events

| Event | What It Means |
|-------|---------------|
| `signup.attempt` | Starting signup process |
| `signUpRestaurant.metadata` | Sending data to Supabase |
| `signup.result` | Supabase response received |
| `otp.requested` | OTP email triggered |
| `signUpRestaurant.authException` | Supabase error (MOST IMPORTANT) |
| `signUpRestaurant.failed` | Generic error wrapper |

### Status Codes

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 200 | Success | - |
| 400 | Bad Request | Invalid input data |
| 401 | Unauthorized | Not authenticated |
| 403 | Forbidden | RLS policy blocking |
| 422 | Unprocessable | Validation error, duplicate email |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Server Error | Database error, trigger failed |

---

## 🧪 Test Scenarios

### Scenario 1: First Time Signup (Should Work)

**Input**:
- Email: new-email@example.com (never used before)
- Password: password123 (6+ characters)
- Organization: Test Restaurant
- Phone: +1234567890

**Expected Logs**:
```
INFO: signup.attempt
INFO: signUpRestaurant.metadata
INFO: signup.result | hasSession=false
INFO: otp.requested | type=signup
```

**Expected Outcome**: OTP email sent, navigate to verification screen

### Scenario 2: Duplicate Email (Should Fail Gracefully)

**Input**:
- Email: existing@example.com (already registered)

**Expected Logs**:
```
INFO: signup.attempt
INFO: signUpRestaurant.metadata
ERROR: signUpRestaurant.authException | statusCode=422, message=User already registered
```

**Expected Outcome**: Error message shown to user

### Scenario 3: After Migration (Should Work)

**Input**:
- Email: test@example.com
- Organization: "" (empty string)

**Expected Logs**:
```
INFO: signup.attempt
INFO: signUpRestaurant.metadata | orgName=
INFO: signup.result | userId=...
INFO: otp.requested
```

**Expected Outcome**: Signup succeeds even with empty org name (trigger uses default)

---

## 🎯 Quick Checklist

Before sharing logs, verify:

- [ ] Migration deployed in Supabase
- [ ] Verification queries run successfully
- [ ] Using valid email format
- [ ] Password is 6+ characters
- [ ] Email not already registered (or deleted existing user)
- [ ] Not hitting rate limit (wait 1 hour if needed)
- [ ] Copied COMPLETE log sequence (not just error line)
- [ ] Checked Postgres logs in Supabase Dashboard

---

## 📞 What to Share

If still failing after migration:

1. **Complete log sequence** (all lines from signup to error)
2. **statusCode and message** from `authException` log
3. **Verification query results** (restaurant_name nullable check)
4. **Trigger check result** (exists and enabled)
5. **Postgres logs** (if available)
6. **Migration deployment result** (success messages or errors)

---

**Remember**: The most important log is `signUpRestaurant.authException` with `statusCode` and `message`. This tells us exactly what Supabase is complaining about.

