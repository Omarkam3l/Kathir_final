# Complete Supabase WhatsApp Setup Guide

## Overview
This guide provides the complete Supabase setup for WhatsApp integration with exact variable names matching your database schema.

## 📱 Phone Number Format - IMPORTANT

**All phone numbers are automatically formatted to WhatsApp-compatible format `201xxxxxxxxx`:**

- Users enter: `01012345678` or `1012345678`
- Stored as: `201012345678` (Egyptian country code + 10 digits)
- Database triggers automatically format phone numbers on insert/update
- Flutter app validates and formats phone numbers before submission

**Implementation:**
- Migration: `supabase/migrations/20260417_phone_number_formatting.sql`
- Flutter utility: `lib/core/utils/phone_formatter.dart`
- Applied to: `profiles.phone_number` and `restaurants.phone`

---

## 1. Database Schema Requirements

### Existing Tables (Verify These Columns Exist)

#### `profiles` table
```sql
- id (uuid, primary key)
- full_name (text)
- phone_number (text) -- Format: 201xxxxxxxxx (auto-formatted by trigger)
- email (text)
```

#### `restaurants` table
```sql
- id (uuid, primary key)
- profile_id (uuid, foreign key to profiles)
- name (text)
- phone (text) -- Format: 201xxxxxxxxx (auto-formatted by trigger)
- address_text (text)
```

#### `ngos` table
```sql
- id (uuid, primary key)
- profile_id (uuid, foreign key to profiles)
- name (text)
- address_text (text)
-- Note: NGO phone comes from profiles.phone_number via profile_id
```

#### `orders` table
```sql
- id (uuid, primary key)
- user_id (uuid, foreign key to profiles)
- restaurant_id (uuid, foreign key to restaurants)
- ngo_id (uuid, nullable, foreign key to ngos)
- delivery_type (text) -- 'delivery', 'pickup', 'donation'
- status (text) -- 'pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled'
- total_amount (numeric)
- delivery_address (text, nullable)
- estimated_ready_time (timestamp)
- created_at (timestamp)
```

#### `order_items` table
```sql
- id (uuid, primary key)
- order_id (uuid, foreign key to orders)
- meal_id (uuid, foreign key to meals)
- quantity (integer)
- price (numeric)
```

#### `meals` table
```sql
- id (uuid, primary key)
- name (text)
- price (numeric)
```

---

## 2. Create WhatsApp Queue Table

Run this migration to create the WhatsApp message queue:

```sql
-- Migration: Create WhatsApp message queue table
-- File: supabase/migrations/20260417_whatsapp_queue.sql

-- Create whatsapp_queue table
CREATE TABLE IF NOT EXISTS whatsapp_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  recipient_phone TEXT NOT NULL,
  recipient_type TEXT NOT NULL CHECK (recipient_type IN ('user', 'restaurant', 'ngo')),
  template_name TEXT NOT NULL,
  template_params JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'failed', 'delivered', 'read')),
  whatsapp_message_id TEXT,
  error_message TEXT,
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sent_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for performance
CREATE INDEX idx_whatsapp_queue_order_id ON whatsapp_queue(order_id);
CREATE INDEX idx_whatsapp_queue_status ON whatsapp_queue(status);
CREATE INDEX idx_whatsapp_queue_created_at ON whatsapp_queue(created_at);
CREATE INDEX idx_whatsapp_queue_recipient_type ON whatsapp_queue(recipient_type);

-- Enable RLS
ALTER TABLE whatsapp_queue ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Service role can manage whatsapp_queue"
  ON whatsapp_queue
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Create function to clean old messages (optional)
CREATE OR REPLACE FUNCTION clean_old_whatsapp_messages()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM whatsapp_queue
  WHERE created_at < NOW() - INTERVAL '30 days'
  AND status IN ('sent', 'delivered', 'read');
END;
$$;

COMMENT ON TABLE whatsapp_queue IS 'Queue for WhatsApp messages to be sent via Edge Function';
COMMENT ON COLUMN whatsapp_queue.recipient_type IS 'Type of recipient: user, restaurant, or ngo';
COMMENT ON COLUMN whatsapp_queue.template_name IS 'WhatsApp template name from Meta Business Manager';
COMMENT ON COLUMN whatsapp_queue.template_params IS 'JSON object with template variable values';
```

---

## 3. Create Database Function to Queue WhatsApp Messages

```sql
-- Migration: Create function to queue WhatsApp messages
-- File: supabase/migrations/20260417_whatsapp_functions.sql

-- Function to queue WhatsApp message
CREATE OR REPLACE FUNCTION queue_whatsapp_message(
  p_order_id UUID,
  p_recipient_phone TEXT,
  p_recipient_type TEXT,
  p_template_name TEXT,
  p_template_params JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_message_id UUID;
BEGIN
  -- Insert into queue
  INSERT INTO whatsapp_queue (
    order_id,
    recipient_phone,
    recipient_type,
    template_name,
    template_params,
    status
  ) VALUES (
    p_order_id,
    p_recipient_phone,
    p_recipient_type,
    p_template_name,
    p_template_params,
    'queued'
  )
  RETURNING id INTO v_message_id;
  
  RETURN v_message_id;
END;
$$;

-- Function to send WhatsApp messages for new order
CREATE OR REPLACE FUNCTION send_order_whatsapp_messages()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_phone TEXT;
  v_user_name TEXT;
  v_restaurant_phone TEXT;
  v_restaurant_name TEXT;
  v_ngo_phone TEXT;
  v_ngo_name TEXT;
  v_order_items TEXT;
  v_delivery_address TEXT;
  v_estimated_time TEXT;
BEGIN
  -- Only send for new orders
  IF TG_OP = 'INSERT' THEN
    
    -- Get user details
    SELECT 
      p.phone_number,
      p.full_name
    INTO v_user_phone, v_user_name
    FROM profiles p
    WHERE p.id = NEW.user_id;
    
    -- Get restaurant details
    SELECT 
      r.phone,
      r.name
    INTO v_restaurant_phone, v_restaurant_name
    FROM restaurants r
    WHERE r.id = NEW.restaurant_id;
    
    -- Build order items list
    SELECT STRING_AGG(
      m.name || ' x' || oi.quantity || ' (' || oi.price || ' EGP)',
      E'\n'
    )
    INTO v_order_items
    FROM order_items oi
    JOIN meals m ON m.id = oi.meal_id
    WHERE oi.order_id = NEW.id;
    
    -- Get delivery address or pickup instructions
    IF NEW.delivery_type = 'delivery' THEN
      v_delivery_address := COALESCE(NEW.delivery_address, 'Not specified');
    ELSIF NEW.delivery_type = 'pickup' THEN
      v_delivery_address := 'Pickup at: ' || v_restaurant_name;
    ELSIF NEW.delivery_type = 'donation' THEN
      v_delivery_address := 'Donation pickup at: ' || v_restaurant_name;
    END IF;
    
    -- Format estimated time
    v_estimated_time := TO_CHAR(NEW.estimated_ready_time, 'HH24:MI DD/MM/YYYY');
    
    -- 1. Queue message to USER
    IF v_user_phone IS NOT NULL AND v_user_phone != '' THEN
      PERFORM queue_whatsapp_message(
        NEW.id,
        v_user_phone,
        'user',
        'order_confirmation_user',
        jsonb_build_object(
          'customer_name', v_user_name,
          'order_id', NEW.id::TEXT,
          'order_items', v_order_items,
          'total_amount', NEW.total_amount::TEXT,
          'delivery_address', v_delivery_address,
          'estimated_time', v_estimated_time,
        )
      );
    END IF;
    
    -- 2. Queue message to RESTAURANT
    IF v_restaurant_phone IS NOT NULL AND v_restaurant_phone != '' THEN
      PERFORM queue_whatsapp_message(
        NEW.id,
        v_restaurant_phone,
        'restaurant',
        'new_order_restaurant',
        jsonb_build_object(
          'order_id', NEW.id::TEXT,
          'customer_name', v_user_name,
          'customer_phone', v_user_phone,
          'order_items', v_order_items,
          'total_amount', NEW.total_amount::TEXT,
          'delivery_type', NEW.delivery_type,
          'address_or_instructions', v_delivery_address,
          'requested_time', v_estimated_time,
        )
      );
    END IF;
    
    -- 3. Queue message to NGO (if donation order)
    IF NEW.delivery_type = 'donation' AND NEW.ngo_id IS NOT NULL THEN
      -- Get NGO details (phone from profiles via profile_id)
      SELECT 
        p.phone_number,
        n.name
      INTO v_ngo_phone, v_ngo_name
      FROM ngos n
      JOIN profiles p ON p.id = n.profile_id
      WHERE n.id = NEW.ngo_id;
      
      IF v_ngo_phone IS NOT NULL AND v_ngo_phone != '' THEN
        PERFORM queue_whatsapp_message(
          NEW.id,
          v_ngo_phone,
          'ngo',
          'donation_pickup_ngo',
          jsonb_build_object(
            'order_id', NEW.id::TEXT,
            'restaurant_name', v_restaurant_name,
            'restaurant_phone', v_restaurant_phone,
            'donated_items', v_order_items,
            'pickup_address', v_delivery_address,
            'ready_time', v_estimated_time,
          )
        );
      END IF;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to send WhatsApp messages on new order
DROP TRIGGER IF EXISTS on_order_created_send_whatsapp ON orders;
CREATE TRIGGER on_order_created_send_whatsapp
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION send_order_whatsapp_messages();

COMMENT ON FUNCTION queue_whatsapp_message IS 'Queue a WhatsApp message to be sent via Edge Function';
COMMENT ON FUNCTION send_order_whatsapp_messages IS 'Automatically queue WhatsApp messages when new order is created';
```

---

## 4. Create Edge Function to Send WhatsApp Messages

Create file: `supabase/functions/send-whatsapp/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const WHATSAPP_API_URL = 'https://graph.facebook.com/v22.0';
const PHONE_NUMBER_ID = Deno.env.get('WHATSAPP_PHONE_NUMBER_ID')!;
const ACCESS_TOKEN = Deno.env.get('WHATSAPP_ACCESS_TOKEN')!;

interface WhatsAppMessage {
  id: string;
  order_id: string;
  recipient_phone: string;
  recipient_type: string;
  template_name: string;
  template_params: Record<string, string>;
}

serve(async (req) => {
  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get pending messages from queue
    const { data: messages, error: fetchError } = await supabaseClient
      .from('whatsapp_queue')
      .select('*')
      .eq('status', 'queued')
      .lt('attempts', 3)
      .order('created_at', { ascending: true })
      .limit(10);

    if (fetchError) {
      console.error('Error fetching messages:', fetchError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch messages' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!messages || messages.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No messages to send' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const results = [];

    // Process each message
    for (const message of messages as WhatsAppMessage[]) {
      try {
        // Format phone number (ensure it starts with country code)
        let phone = message.recipient_phone.replace(/\D/g, '');
        if (!phone.startsWith('20')) {
          phone = '20' + phone;
        }

        // Build template parameters array
        const params = message.template_params;
        const parameterArray = Object.keys(params)
          .sort()
          .map(key => ({
            type: 'text',
            text: params[key]
          }));

        // Send WhatsApp message
        const response = await fetch(
          `${WHATSAPP_API_URL}/${PHONE_NUMBER_ID}/messages`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${ACCESS_TOKEN}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              messaging_product: 'whatsapp',
              to: phone,
              type: 'template',
              template: {
                name: message.template_name,
                language: { code: 'en_US' },
                components: [
                  {
                    type: 'body',
                    parameters: parameterArray,
                  },
                ],
              },
            }),
          }
        );

        const result = await response.json();

        if (response.ok && result.messages) {
          // Update message status to sent
          await supabaseClient
            .from('whatsapp_queue')
            .update({
              status: 'sent',
              whatsapp_message_id: result.messages[0].id,
              sent_at: new Date().toISOString(),
              attempts: message.attempts + 1,
            })
            .eq('id', message.id);

          results.push({
            id: message.id,
            status: 'sent',
            whatsapp_id: result.messages[0].id,
          });
        } else {
          // Update message status to failed
          await supabaseClient
            .from('whatsapp_queue')
            .update({
              status: 'failed',
              error_message: JSON.stringify(result),
              attempts: message.attempts + 1,
            })
            .eq('id', message.id);

          results.push({
            id: message.id,
            status: 'failed',
            error: result,
          });
        }
      } catch (error) {
        console.error(`Error sending message ${message.id}:`, error);
        
        // Update attempts
        await supabaseClient
          .from('whatsapp_queue')
          .update({
            error_message: error.message,
            attempts: message.attempts + 1,
          })
          .eq('id', message.id);

        results.push({
          id: message.id,
          status: 'error',
          error: error.message,
        });
      }
    }

    return new Response(
      JSON.stringify({
        processed: messages.length,
        results,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Function error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

---

## 5. Set Environment Variables in Supabase

Go to Supabase Dashboard → Project Settings → Edge Functions → Add the following secrets:

```bash
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id_from_meta
WHATSAPP_ACCESS_TOKEN=your_access_token_from_meta
```

---

## 6. Deploy Edge Function

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Deploy the function
supabase functions deploy send-whatsapp
```

---

## 7. Set Up Cron Job (Optional - for automatic processing)

In Supabase Dashboard → Database → Extensions → Enable `pg_cron`

Then run:

```sql
-- Schedule Edge Function to run every minute
SELECT cron.schedule(
  'process-whatsapp-queue',
  '* * * * *', -- Every minute
  $$
  SELECT net.http_post(
    url := 'https://your-project-ref.supabase.co/functions/v1/send-whatsapp',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  $$
);
```

---

## 8. Testing the Integration

### Test 1: Create a Test Order

```sql
-- Insert a test order (replace UUIDs with real ones from your database)
INSERT INTO orders (
  user_id,
  restaurant_id,
  delivery_type,
  status,
  total_amount,
  delivery_address,
  estimated_ready_time
) VALUES (
  'user-uuid-here',
  'restaurant-uuid-here',
  'delivery',
  'pending',
  85.00,
  '123 Test Street, Cairo',
  NOW() + INTERVAL '30 minutes'
);
```

### Test 2: Check WhatsApp Queue

```sql
-- View queued messages
SELECT * FROM whatsapp_queue ORDER BY created_at DESC LIMIT 10;
```

### Test 3: Manually Trigger Edge Function

```bash
curl -X POST \
  'https://your-project-ref.supabase.co/functions/v1/send-whatsapp' \
  -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY'
```

---

## 9. Monitoring & Troubleshooting

### Check Message Status

```sql
-- View all messages
SELECT 
  id,
  order_id,
  recipient_type,
  template_name,
  status,
  attempts,
  error_message,
  created_at,
  sent_at
FROM whatsapp_queue
ORDER BY created_at DESC
LIMIT 20;

-- Count by status
SELECT status, COUNT(*) 
FROM whatsapp_queue 
GROUP BY status;

-- View failed messages
SELECT * 
FROM whatsapp_queue 
WHERE status = 'failed'
ORDER BY created_at DESC;
```

### Retry Failed Messages

```sql
-- Reset failed messages to retry
UPDATE whatsapp_queue
SET status = 'queued', attempts = 0
WHERE status = 'failed' AND attempts < 3;
```

### View Edge Function Logs

```bash
supabase functions logs send-whatsapp
```

---

## 10. Variable Name Reference

### Database Column Names (Exact)
- `profiles.phone_number` - User phone
- `restaurants.phone` - Restaurant phone
- `orders.delivery_type` - Order type
- `orders.total_amount` - Order total
- `orders.delivery_address` - Delivery address
- `orders.estimated_ready_time` - Ready time
- `order_items.quantity` - Item quantity
- `order_items.price` - Item price
- `meals.name` - Meal name

### Template Parameter Names (Exact)
- `customer_name` - User's full name
- `order_id` - Order UUID
- `order_items` - Formatted list of items
- `total_amount` - Total price
- `delivery_address` - Address or pickup info
- `estimated_time` - Formatted time
- `tracking_url` - Order tracking link
- `restaurant_name` - Restaurant name
- `restaurant_phone` - Restaurant phone
- `dashboard_url` - Dashboard link

---

## Summary Checklist

- [ ] Run migration to create `whatsapp_queue` table
- [ ] Run migration to create queue functions and trigger
- [ ] Create Edge Function `send-whatsapp/index.ts`
- [ ] Set environment variables in Supabase
- [ ] Deploy Edge Function
- [ ] Set up cron job (optional)
- [ ] Create 4 templates in Meta Business Manager
- [ ] Test with a real order
- [ ] Monitor queue and logs

---

**Last Updated:** April 17, 2026
**Status:** Production Ready
