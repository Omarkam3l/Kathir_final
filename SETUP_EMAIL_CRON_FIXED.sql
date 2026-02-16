-- =====================================================
-- SETUP EMAIL CRON - FIXED VERSION
-- =====================================================
-- This sets up automatic email sending every minute
-- =====================================================

-- Step 1: Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;  -- Required for HTTP requests

-- Step 2: Unschedule any existing email jobs
SELECT cron.unschedule('send-order-emails-job');
SELECT cron.unschedule('email-notification-job');

-- Step 3: Create the cron job with correct URL
SELECT cron.schedule(
  'send-order-emails-job',           -- Job name
  '* * * * *',                        -- Every minute
  $$
  SELECT
    net.http_post(
      url := 'https://kapqefuchyqqprhneeiw.supabase.co/functions/v1/send-order-emails',
      headers := jsonb_build_object(
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImthcHFlZnVjaHlxcXByaG5lZWl3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTM1MjE2MCwiZXhwIjoyMDgwOTI4MTYwfQ.RkVNwFFL0MswYlQ74EfaUHCQSLcOpULFuqDbW_F7Acc',
        'Content-Type', 'application/json'
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- Step 4: Verify the job was created
SELECT * FROM cron.job WHERE jobname = 'send-order-emails-job';

-- Step 5: Check job run history
SELECT * FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-order-emails-job')
ORDER BY start_time DESC 
LIMIT 5;

-- =====================================================
-- VERIFICATION
-- =====================================================

DO $$
BEGIN
  -- Check if pg_net extension exists
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RAISE NOTICE '✅ pg_net extension is installed';
  ELSE
    RAISE NOTICE '❌ pg_net extension is NOT installed - run: CREATE EXTENSION pg_net;';
  END IF;
  
  -- Check if pg_cron extension exists
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    RAISE NOTICE '✅ pg_cron extension is installed';
  ELSE
    RAISE NOTICE '❌ pg_cron extension is NOT installed - run: CREATE EXTENSION pg_cron;';
  END IF;
  
  -- Check if job exists
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'send-order-emails-job') THEN
    RAISE NOTICE '✅ Cron job is scheduled';
  ELSE
    RAISE NOTICE '❌ Cron job is NOT scheduled';
  END IF;
END;
$$;

-- =====================================================
-- MONITORING QUERIES
-- =====================================================

-- View all cron jobs
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  database
FROM cron.job;

-- View recent job runs
SELECT 
  jobid,
  runid,
  status,
  return_message,
  start_time,
  end_time
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-order-emails-job')
ORDER BY start_time DESC
LIMIT 10;

-- Check pending emails
SELECT COUNT(*) as pending_emails
FROM email_queue
WHERE status = 'pending';

-- =====================================================
-- TROUBLESHOOTING
-- =====================================================

/*
ERROR: schema "net" does not exist
→ Solution: Run CREATE EXTENSION pg_net;

ERROR: extension "pg_net" is not available
→ Solution: Contact Supabase support or use alternative method

ALTERNATIVE: Use Supabase's built-in HTTP wrapper
→ Some Supabase projects don't have pg_net enabled
→ Use external cron service instead (GitHub Actions, Vercel Cron, etc.)
*/

-- =====================================================
-- DISABLE CRON (if needed)
-- =====================================================

-- To stop the cron job:
-- SELECT cron.unschedule('send-order-emails-job');
