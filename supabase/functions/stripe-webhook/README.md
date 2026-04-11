# Stripe Webhook Function

This function handles Stripe webhook events and creates orders in the database when payments succeed.

## Deployment

**IMPORTANT**: This function must be deployed with JWT verification disabled because Stripe webhooks cannot send JWT tokens.

```bash
supabase functions deploy stripe-webhook --no-verify-jwt
```

## Configuration Required

### Supabase Environment Variables
Set these in Supabase Dashboard > Settings > Edge Functions:

```bash
STRIPE_SECRET_KEY=sk_test_... or sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
```

### Stripe Webhook Configuration
1. Go to Stripe Dashboard > Webhooks
2. Add endpoint: `https://your-project.supabase.co/functions/v1/stripe-webhook`
3. Select event: `payment_intent.succeeded`
4. Copy the signing secret and add to Supabase env vars

## Security

- JWT verification is disabled (safe because Stripe signature verification is used)
- Every webhook is verified using Stripe's signature before processing
- Service role key is used to bypass RLS policies (server-side only)

## Logging

All logs use structured format: `[WEBHOOK] [CATEGORY] [SUBCATEGORY] Message`

Categories:
- `[REQUEST]` - Incoming requests
- `[AUTH]` - Signature verification
- `[EVENT]` - Stripe event details
- `[PAYMENT]` - Payment intent information
- `[METADATA]` - Payment metadata
- `[ITEMS]` - Order items
- `[CHECK]` - Duplicate checking
- `[ORDER]` - Order creation
- `[INSERT]` - Database operations
- `[SUCCESS]` - Successful operations
- `[ERROR]` - Errors
- `[COMPLETE]` - Final summary

## Testing

### Test Endpoint Accessibility
```powershell
./test_webhook_manual.ps1
```
Expected: 400 Bad Request (missing signature)

### Test with Stripe CLI
```bash
stripe listen --forward-to https://your-project.supabase.co/functions/v1/stripe-webhook
stripe trigger payment_intent.succeeded
```

## Troubleshooting

See: `docs/WEBHOOK_LOGGING_GUIDE.md` and `docs/STRIPE_WEBHOOK_SETUP_COMPLETE.md`
