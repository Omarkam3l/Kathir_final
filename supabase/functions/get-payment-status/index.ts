// =====================================================
// GET PAYMENT STATUS - Supabase Edge Function
// =====================================================
// Allows frontend to poll for order creation status
// after payment is completed
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Authenticate user
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 2. Get payment intent ID from request
    const { payment_intent_id } = await req.json()

    if (!payment_intent_id) {
      return new Response(JSON.stringify({ error: 'Missing payment_intent_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log('🔍 Checking status for PaymentIntent:', payment_intent_id)

    // 3. Check if order was created by webhook
    const { data: orders, error: orderError } = await supabase
      .from('orders')
      .select('id, order_number, status, payment_status, total_amount')
      .eq('stripe_payment_intent_id', payment_intent_id)
      .eq('user_id', user.id) // Security: ensure user owns this order

    if (orderError) {
      console.error('❌ Error querying orders:', orderError)
      return new Response(JSON.stringify({ error: 'Database error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 4. If orders exist, return them
    if (orders && orders.length > 0) {
      console.log(`✅ Found ${orders.length} order(s)`)
      
      return new Response(JSON.stringify({
        status: 'completed',
        orders: orders.map(o => ({
          order_id: o.id,
          order_number: o.order_number,
          total_amount: o.total_amount,
        })),
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 5. No orders yet - check PaymentIntent status from Stripe
    console.log('⏳ No orders yet, checking Stripe status...')
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id)

    console.log('Stripe PaymentIntent status:', paymentIntent.status)

    return new Response(JSON.stringify({
      status: paymentIntent.status, // 'processing', 'succeeded', 'requires_action', etc.
      orders: [],
      message: paymentIntent.status === 'succeeded' 
        ? 'Payment confirmed, order is being created...'
        : 'Payment is being processed...',
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ ERROR:', error)
    return new Response(JSON.stringify({ 
      error: error.message || 'Internal server error' 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
