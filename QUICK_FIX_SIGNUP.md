# Quick Fix for Signup/OTP Issue

## The Problem
Restaurant signup is failing and OTP emails are not being sent.

## Most Likely Causes

### 1. Email Typo ⚠️
**Error log shows:** `a7mademad@oegmail.com`
- Should be: `@gmail.com` not `@oegmail.com`
- **Fix:** Correct the email address

### 2. Supabase Email Confirmation Enabled
By default, Supabase requires email confirmation which sends an OTP.

## Immediate Solutions

### Option A: Disable Email Confirmation (For Testing)

**Steps:**
1. Open Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Go to: **Authentication** → **Settings**
4. Scroll to **Email Auth** section
5. Find **"Enable email confirmations"**
6. **Toggle it OFF**
7. Save changes

**Result:** Users can signup immediately without OTP verification.

⚠️ **Note:** Re-enable this for production!

### Option B: Configure Email Provider

**For Production Use:**

1. Go to: **Authentication** → **Settings** → **SMTP Settings**
2. Enable **Custom SMTP**
3. Configure with one of these providers:

**SendGrid (Recommended):**
```
Host: smtp.sendgrid.net
Port: 587
Username: apikey
Password: <your-sendgrid-api-key>
```

**Gmail (For Testing Only):**
```
Host: smtp.gmail.com
Port: 587
Username: your-email@gmail.com
Password: <app-specific-password>
```

### Option C: Check Rate Limits

Supabase free tier limits:
- **3-4 emails per hour** per email address

**Solution:**
- Wait 1 hour
- Use different email addresses
- Upgrade to paid plan

## Testing the Fix

### Test 1: Correct Email
Try signup with: `a7mademad@gmail.com` (not `@oegmail.com`)

### Test 2: Check Supabase Logs
1. Dashboard → **Logs** → **Auth Logs**
2. Look for signup attempts
3. Check for email sending errors

### Test 3: Verify User Creation
1. Dashboard → **Authentication** → **Users**
2. Check if user was created
3. If yes, issue is only with email sending

## Code Changes Made

Enhanced error logging in `auth_viewmodel.dart`:
- Now shows detailed error cause
- Better debugging information
- Helps identify exact failure point

## Verification Steps

After applying fix:

1. ✅ Clear app data/cache
2. ✅ Restart app
3. ✅ Try signup with correct email
4. ✅ Check email inbox (and spam folder)
5. ✅ Verify OTP arrives within 2-3 minutes

## If Still Not Working

### Check Environment Variables

Verify `.env` file:
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Check Supabase Project Status
- Project not paused
- No billing issues
- Service is operational

### Check Network
- Internet connection stable
- No firewall blocking Supabase
- No VPN interfering

## Recommended Approach

**For Development:**
```
1. Disable email confirmation in Supabase
2. Test signup flow
3. Verify user creation works
4. Re-enable email confirmation
5. Configure SMTP provider
6. Test email delivery
```

**For Production:**
```
1. Keep email confirmation enabled
2. Configure reliable SMTP (SendGrid)
3. Test with multiple email providers
4. Monitor delivery rates
5. Set up email templates
```

## Support

If issue persists after trying these fixes:
1. Check Supabase status page
2. Review Supabase logs for detailed errors
3. Contact Supabase support with:
   - Project ID
   - Timestamp of failed attempt
   - Email address used
   - Error logs

## Summary

**Most likely fix:** 
1. Correct email typo (`@gmail.com` not `@oegmail.com`)
2. Disable email confirmation in Supabase for testing
3. Configure SMTP for production

**Next run will show more detailed error** thanks to improved logging.
