-- =====================================================
-- RLS POLICY ANALYSIS SCRIPT
-- Run this to see all RLS policies and identify recursion issues
-- =====================================================

-- 1. List all tables with RLS enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Get all RLS policies with their full definitions
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 3. Detailed view of policies with formatted output
SELECT 
    tablename as "Table",
    policyname as "Policy Name",
    cmd as "Command",
    CASE 
        WHEN qual IS NOT NULL THEN 'USING: ' || qual
        ELSE 'No USING clause'
    END as "Using Expression",
    CASE 
        WHEN with_check IS NOT NULL THEN 'WITH CHECK: ' || with_check
        ELSE 'No WITH CHECK clause'
    END as "With Check Expression"
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- 4. Find policies that reference other tables (potential recursion sources)
SELECT 
    p.tablename as "Policy Table",
    p.policyname as "Policy Name",
    p.cmd as "Command",
    p.qual as "Using Expression"
FROM pg_policies p
WHERE schemaname = 'public'
AND (
    -- Look for common table references in USING clauses
    qual LIKE '%orders%' OR
    qual LIKE '%order_items%' OR
    qual LIKE '%order_status_history%' OR
    qual LIKE '%meals%' OR
    qual LIKE '%profiles%' OR
    qual LIKE '%cart_items%' OR
    qual LIKE '%EXISTS%' OR
    qual LIKE '%IN (%'
)
ORDER BY p.tablename, p.policyname;

-- 5. Identify circular dependencies between orders, order_items, and order_status_history
SELECT 
    'ORDERS -> ORDER_ITEMS' as "Dependency Type",
    p.policyname as "Policy Name",
    p.cmd as "Command",
    p.qual as "Expression"
FROM pg_policies p
WHERE schemaname = 'public'
AND p.tablename = 'orders'
AND (p.qual LIKE '%order_items%' OR p.with_check LIKE '%order_items%')

UNION ALL

SELECT 
    'ORDER_ITEMS -> ORDERS' as "Dependency Type",
    p.policyname as "Policy Name",
    p.cmd as "Command",
    p.qual as "Expression"
FROM pg_policies p
WHERE schemaname = 'public'
AND p.tablename = 'order_items'
AND (p.qual LIKE '%orders%' OR p.with_check LIKE '%orders%')

UNION ALL

SELECT 
    'ORDER_STATUS_HISTORY -> ORDERS' as "Dependency Type",
    p.policyname as "Policy Name",
    p.cmd as "Command",
    p.qual as "Expression"
FROM pg_policies p
WHERE schemaname = 'public'
AND p.tablename = 'order_status_history'
AND (p.qual LIKE '%orders%' OR p.with_check LIKE '%orders%')

UNION ALL

SELECT 
    'ORDERS -> ORDER_STATUS_HISTORY' as "Dependency Type",
    p.policyname as "Policy Name",
    p.cmd as "Command",
    p.qual as "Expression"
FROM pg_policies p
WHERE schemaname = 'public'
AND p.tablename = 'orders'
AND (p.qual LIKE '%order_status_history%' OR p.with_check LIKE '%order_status_history%');

-- 6. Count policies per table
SELECT 
    tablename as "Table",
    COUNT(*) as "Policy Count",
    COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) as "SELECT Policies",
    COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) as "INSERT Policies",
    COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) as "UPDATE Policies",
    COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) as "DELETE Policies"
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY "Policy Count" DESC, tablename;

-- 7. Find duplicate or overlapping policies (same table, same command)
SELECT 
    tablename as "Table",
    cmd as "Command",
    COUNT(*) as "Number of Policies",
    STRING_AGG(policyname, ', ') as "Policy Names"
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename, cmd
HAVING COUNT(*) > 1
ORDER BY tablename, cmd;

-- 8. Specific analysis for orders-related tables
SELECT 
    '=== ORDERS TABLE POLICIES ===' as "Analysis Section"
UNION ALL
SELECT policyname || ' (' || cmd || '): ' || COALESCE(qual, 'No USING clause')
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'orders'

UNION ALL
SELECT ''
UNION ALL
SELECT '=== ORDER_ITEMS TABLE POLICIES ==='
UNION ALL
SELECT policyname || ' (' || cmd || '): ' || COALESCE(qual, 'No USING clause')
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'order_items'

UNION ALL
SELECT ''
UNION ALL
SELECT '=== ORDER_STATUS_HISTORY TABLE POLICIES ==='
UNION ALL
SELECT policyname || ' (' || cmd || '): ' || COALESCE(qual, 'No USING clause')
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'order_status_history';

-- 9. Check for policies using security definer functions (can bypass RLS)
SELECT 
    p.proname as "Function Name",
    pg_get_functiondef(p.oid) as "Function Definition"
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND pg_get_functiondef(p.oid) LIKE '%SECURITY DEFINER%'
ORDER BY p.proname;

-- 10. Summary of potential recursion risks
SELECT 
    'RECURSION RISK SUMMARY' as "Report",
    '' as "Details"
UNION ALL
SELECT 
    'Tables with RLS enabled',
    COUNT(DISTINCT tablename)::text
FROM pg_policies
WHERE schemaname = 'public'
UNION ALL
SELECT 
    'Total RLS policies',
    COUNT(*)::text
FROM pg_policies
WHERE schemaname = 'public'
UNION ALL
SELECT 
    'Policies with EXISTS clauses',
    COUNT(*)::text
FROM pg_policies
WHERE schemaname = 'public'
AND qual LIKE '%EXISTS%'
UNION ALL
SELECT 
    'Policies with subqueries (IN)',
    COUNT(*)::text
FROM pg_policies
WHERE schemaname = 'public'
AND qual LIKE '%IN (%'
UNION ALL
SELECT 
    'Order-related circular dependencies',
    COUNT(*)::text
FROM pg_policies
WHERE schemaname = 'public'
AND (
    (tablename = 'orders' AND (qual LIKE '%order_items%' OR qual LIKE '%order_status_history%'))
    OR
    (tablename = 'order_items' AND qual LIKE '%orders%')
    OR
    (tablename = 'order_status_history' AND qual LIKE '%orders%')
);
