# Signup & OTP Issue Troubleshooting

## Error Details
```
ERROR AUTH: signup.viewmodel.failed | role=SignUpRole.restaurant, email=a7mademad@oegmail.com
error: signUpRestaurant failed
```

## Issue
- Restaurant signup is failing
- OTP email is not being sent
- Error occurs during signup process

## Common Causes & Solutions

### 1. Supabase Email Configuration ⚠️

**Check Supabase Dashboard:**
1. Go to: Authentication → Email Templates
2. Verify email provider is configured
3. Check if email confirmation is enabled

**Settings to verify:**
- Authentication → Settings → Email Auth
  - ✅ Enable email confirmations
  - ✅ Enable email change confirmations
  - ✅ Secure email change enabled

**Email Provider:**
- Default: Supabase built-in (limited to 3-4 emails/hour)
- Production: Configure SMTP (SendGrid, AWS SES, etc.)

### 2. Email Rate Limiting

**Supabase Free Tier Limits:**
- 3-4 emails per hour per email address
- If you've been testing, you may have hit the limit

**Solution:**
- Wait 1 hour before trying again
- Use different email addresses for testing
- Configure custom SMTP provider

### 3. Email Typo in Error Log

**Notice:** `a7mademad@oegmail.com` (should be `@gmail.com`?)
- Typo in email domain: `oegmail` instead of `gmail`
- This would cause email delivery to fail

**Solution:**
- Verify the correct email address
- Check for typos in the signup form

### 4. Supabase Auth Settings

**Check these settings in Supabase Dashboard:**

```
Authentication → Settings → Auth Providers
- Email: ✅ Enabled
- Confirm email: ✅ Enabled (or disabled for testing)
```

**For Development/Testing:**
You can temporarily disable email confirmation:
1. Go to: Authentication → Settings
2. Find "Enable email confirmations"
3. Toggle OFF for testing
4. ⚠️ Remember to re-enable for production!

### 5. Network/Firewall Issues

**Check:**
- Internet connection
- Firewall blocking Supabase
- VPN interfering with requests
- Corporate network restrictions

### 6. Supabase Project Status

**Verify:**
- Project is active (not paused)
- No service outages
- API keys are correct in `.env`

## Quick Fixes to Try

### Fix 1: Disable Email Confirmation (Testing Only)

In Supabase Dashboard:
```
Authentication → Settings → Email Auth
→ Disable "Enable email confirmations"
```

This allows immediate signup without OTP verification.

### Fix 2: Check Email in Spam/Junk

- Check spam folder
- Check junk folder
- Add `noreply@mail.app.supabase.io` to contacts

### Fix 3: Use Different Email

Try with a different email provider:
- Gmail
- Outlook
- Yahoo
- Temporary email service (for testing)

### Fix 4: Configure Custom SMTP

For production, configure a reliable email provider:

**Recommended Providers:**
1. **SendGrid** (Free tier: 100 emails/day)
2. **AWS SES** (Very cheap, reliable)
3. **Mailgun** (Free tier: 5,000 emails/month)
4. **Postmark** (Free tier: 100 emails/month)

**Configuration in Supabase:**
```
Authentication → Settings → SMTP Settings
- Enable Custom SMTP
- Enter provider credentials
```

## Debugging Steps

### Step 1: Check Supabase Logs

In Supabase Dashboard:
```
Logs → Auth Logs
```
Look for:
- Signup attempts
- Email sending attempts
- Error messages

### Step 2: Test with Simple Email

Try signup with a simple, known-good email:
```
test@gmail.com
```

### Step 3: Check Network Tab

In browser DevTools:
1. Open Network tab
2. Attempt signup
3. Look for failed requests
4. Check response errors

### Step 4: Verify Environment Variables

Check `.env` file:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Make sure:
- No extra spaces
- Correct URL format
- Valid anon key

## Code Verification

The signup code looks correct:
```dart
final res = await client.auth.signUp(
  email: email,
  password: password,
  data: {
    'full_name': fullName,
    'role': UserRole.restaurant.wireValue,
    'organization_name': orgName,
    'phone_number': phone,
  },
  emailRedirectTo: kIsWeb
    ? Uri.base.toString()
    : 'io.supabase.flutter://login-callback/'
);
```

## Recommended Solution

### For Immediate Testing:

1. **Disable email confirmation in Supabase:**
   - Dashboard → Authentication → Settings
   - Disable "Enable email confirmations"
   - This allows instant signup without OTP

2. **Fix the email typo:**
   - Use `@gmail.com` instead of `@oegmail.com`

3. **Try again with correct email**

### For Production:

1. **Keep email confirmation enabled**
2. **Configure custom SMTP provider** (SendGrid recommended)
3. **Test thoroughly with multiple email providers**
4. **Monitor email delivery rates**

## Additional Checks

### Check if user was created despite error:

In Supabase Dashboard:
```
Authentication → Users
```
Look for the email address - if it exists, the signup succeeded but email failed.

### Check database triggers:

If you have database triggers on user creation, they might be failing:
```sql
-- Check for triggers
SELECT * FROM pg_trigger WHERE tgname LIKE '%user%';
```

## Next Steps

1. ✅ Verify email address is correct (fix typo)
2. ✅ Check Supabase email settings
3. ✅ Temporarily disable email confirmation for testing
4. ✅ Try with different email address
5. ✅ Check Supabase logs for detailed error
6. ✅ Configure SMTP for production

## Contact Support

If issue persists:
- Check Supabase status: https://status.supabase.com/
- Supabase Discord: https://discord.supabase.com/
- Supabase GitHub Issues: https://github.com/supabase/supabase/issues
