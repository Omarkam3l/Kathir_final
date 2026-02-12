# Order Email Notifications System

## Overview
Comprehensive email notification system that automatically sends emails to users, restaurants, and NGOs when orders are placed.

## Features

### 1. User Purchases (Delivery/Pickup)
When a user places an order:
- ✅ **User receives**: Order confirmation invoice with itemized details
- ✅ **Restaurant receives**: New order notification with items to prepare

### 2. User Donates to NGO
When a user donates meals to an NGO:
- ✅ **User receives**: Order confirmation invoice
- ✅ **Restaurant receives**: New order notification
- ✅ **NGO receives**: Pickup notification with donation details

### 3. NGO Purchases
When an NGO places an order:
- ✅ **Restaurant receives**: New order notification
- ✅ **NGO receives**: Order confirmation

## Architecture

### Database Components

#### 1. Email Queue Table (`email_queue`)
Stores all emails to be sent with retry logic:
```sql
- id: UUID primary key
- order_id: Reference to orders table
- recipient_email: Email address
- recipient_type: 'user' | 'restaurant' | 'ngo'
- email_type: 'invoice' | 'new_order' | 'ngo_pickup' | 'ngo_confirmation'
- email_data: JSONB with order details
- status: 'pending' | 'sent' | 'failed'
- attempts: Retry counter (max 3)
- timestamps: created_at, updated_at, sent_at
```

#### 2. Database Trigger
Automatically queues emails when an order is created:
```sql
CREATE TRIGGER trigger_queue_order_emails
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION queue_order_emails();
```

#### 3. Helper Functions
- `queue_order_emails()`: Determines which emails to send based on order type
- `get_pending_emails()`: Retrieves emails to be processed
- `process_email_queue_item()`: Marks emails as sent/failed

### Edge Function

#### Location
`supabase/functions/send-order-emails/index.ts`

#### Functionality
- Fetches pending emails from queue
- Generates HTML email templates
- Sends emails via Resend API
- Updates email status in database
- Handles retries (max 3 attempts)

#### Email Templates
1. **Invoice Email** (to users)
   - Order confirmation
   - Itemized list with prices
   - Total amount
   - Delivery details
   - Track order button

2. **New Order Email** (to restaurants)
   - Customer name
   - Items to prepare
   - Delivery method
   - View order button

3. **NGO Pickup Email** (to NGOs)
   - Donor name
   - Restaurant details
   - Meals to pickup
   - Dashboard link

4. **NGO Confirmation Email** (to NGOs)
   - Order confirmation
   - Restaurant details
   - Order items
   - Dashboard link

## Setup Instructions

### 1. Apply Database Migration
```bash
cd supabase
supabase db push
```

This creates:
- `email_queue` table
- Trigger on `orders` table
- Helper functions

### 2. Set Up Resend Account
1. Sign up at [resend.com](https://resend.com)
2. Verify your domain (e.g., kathir.app)
3. Get your API key

### 3. Configure Supabase Secrets
```bash
# Set Resend API key
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxx

# Verify secrets
supabase secrets list
```

### 4. Deploy Edge Function
```bash
# Deploy the function
supabase functions deploy send-order-emails

# Test the function
supabase functions invoke send-order-emails
```

### 5. Set Up Cron Job (Optional)
For automatic email processing every minute:

```sql
-- In Supabase Dashboard > Database > Extensions
-- Enable pg_cron extension

-- Create cron job
SELECT cron.schedule(
  'process-order-emails',
  '* * * * *',  -- Every minute
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/send-order-emails',
    headers := '{"Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb
  );
  $$
);
```

## Email Flow Diagram

```
Order Created
     |
     v
[Database Trigger]
     |
     v
[queue_order_emails()]
     |
     +-- Determine buyer type (user/ngo)
     +-- Determine delivery type (delivery/pickup/donate)
     +-- Insert emails into queue
     |
     v
[Email Queue Table]
     |
     v
[Edge Function - Cron/Manual]
     |
     +-- Fetch pending emails
     +-- Generate HTML templates
     +-- Send via Resend API
     +-- Update status
     |
     v
[Emails Delivered]
```

## Testing

### 1. Test Email Queue
```sql
-- Check pending emails
SELECT * FROM email_queue WHERE status = 'pending';

-- Check sent emails
SELECT * FROM email_queue WHERE status = 'sent';

-- Check failed emails
SELECT * FROM email_queue WHERE status = 'failed';
```

### 2. Test Edge Function Manually
```bash
# Invoke function
curl -X POST \
  'https://your-project.supabase.co/functions/v1/send-order-emails' \
  -H 'Authorization: Bearer YOUR_ANON_KEY'
```

### 3. Test Order Creation
Create a test order in your app and verify:
1. Emails are queued in `email_queue` table
2. Edge function processes them
3. Recipients receive emails
4. Status updates to 'sent'

## Monitoring

### Check Email Queue Status
```sql
-- Summary of email statuses
SELECT 
  status,
  COUNT(*) as count,
  MAX(created_at) as latest
FROM email_queue
GROUP BY status;

-- Failed emails with errors
SELECT 
  recipient_email,
  email_type,
  error_message,
  attempts,
  created_at
FROM email_queue
WHERE status = 'failed'
ORDER BY created_at DESC;
```

### Retry Failed Emails
```sql
-- Reset failed emails for retry (if needed)
UPDATE email_queue
SET 
  status = 'pending',
  attempts = 0,
  error_message = NULL
WHERE status = 'failed'
  AND attempts < 3;
```

## Customization

### Update Email Templates
Edit the template functions in `send-order-emails/index.ts`:
- `generateInvoiceEmail()`
- `generateNewOrderEmail()`
- `generateNgoPickupEmail()`
- `generateNgoConfirmationEmail()`

### Change Email Provider
Replace Resend API calls with your preferred provider:
- SendGrid
- Mailgun
- AWS SES
- Postmark

### Modify Email Logic
Update `queue_order_emails()` function in the migration to:
- Add more email types
- Change recipient logic
- Add conditional sending

## Troubleshooting

### Emails Not Sending
1. Check email queue: `SELECT * FROM email_queue WHERE status = 'pending'`
2. Verify Resend API key is set
3. Check Edge Function logs in Supabase Dashboard
4. Verify domain is verified in Resend

### Emails Going to Spam
1. Verify domain in Resend
2. Set up SPF, DKIM, DMARC records
3. Use professional email templates
4. Avoid spam trigger words

### High Failure Rate
1. Check error messages in `email_queue`
2. Verify recipient emails are valid
3. Check Resend API limits
4. Review Edge Function logs

## Security Considerations

1. **Email Queue RLS**: Only service role can access
2. **Edge Function**: Uses service role key
3. **API Keys**: Stored as Supabase secrets
4. **Email Data**: Sanitized before sending
5. **Retry Limit**: Max 3 attempts to prevent spam

## Performance

- **Queue Processing**: Batches of 10 emails per invocation
- **Retry Logic**: Exponential backoff (handled by cron frequency)
- **Database Indexes**: On status and created_at for fast queries
- **Edge Function**: Runs in <1 second for 10 emails

## Cost Estimation

### Resend Pricing (as of 2024)
- Free tier: 3,000 emails/month
- Pro: $20/month for 50,000 emails
- Additional: $1 per 1,000 emails

### Supabase
- Edge Function invocations: Included in free tier
- Database operations: Minimal impact

## Future Enhancements

1. **Email Preferences**: Allow users to opt-out
2. **SMS Notifications**: Add SMS for urgent orders
3. **Push Notifications**: Mobile app notifications
4. **Email Analytics**: Track open rates, clicks
5. **Localization**: Multi-language support
6. **Rich Templates**: Add images, branding
7. **Order Updates**: Status change notifications

## Support

For issues or questions:
- Check Supabase Dashboard logs
- Review email_queue table
- Test Edge Function manually
- Verify Resend API status

## Migration Files

1. `20260206_order_email_notifications.sql` - Database schema and triggers
2. `send-order-emails/index.ts` - Edge Function for sending emails

Apply migrations in order and deploy Edge Function after database setup.
