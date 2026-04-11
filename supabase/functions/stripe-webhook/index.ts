// STRIPE WEBHOOK HANDLER
// Handles Stripe payment events and creates orders in Supabase
// =====================================================
// NOTE: This function must be publicly accessible (no auth required)
// Stripe webhooks cannot send authorization headers
// Security is handled by webhook signature verification

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

// Use service role key to bypass RLS policies
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

// CORS headers for webhook
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, stripe-signature',
}

serve(async (req) => {
  const requestId = `REQ-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`
  console.log('========================================')
  console.log('[WEBHOOK] [REQUEST] New request received')
  console.log('[WEBHOOK] [REQUEST] Request ID:', requestId)
  console.log('[WEBHOOK] [REQUEST] Method:', req.method)
  console.log('[WEBHOOK] [REQUEST] URL:', req.url)
  console.log('[WEBHOOK] [REQUEST] Timestamp:', new Date().toISOString())

  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    console.log('[WEBHOOK] [REQUEST] CORS preflight request')
    return new Response('ok', { headers: corsHeaders })
  }

  // Log all headers (excluding sensitive data)
  const headers = Object.fromEntries(req.headers.entries())
  console.log('[WEBHOOK] [REQUEST] Headers:', JSON.stringify({
    'content-type': headers['content-type'],
    'user-agent': headers['user-agent'],
    'stripe-signature': headers['stripe-signature'] ? '[PRESENT]' : '[MISSING]'
  }, null, 2))

  if (req.method !== 'POST') {
    console.log('[WEBHOOK] [ERROR] [REQUEST] Method not allowed:', req.method)
    console.log('[WEBHOOK] [ERROR] [REQUEST] Expected: POST')
    console.log('[WEBHOOK] [ERROR] [REQUEST] Returning 405 status')
    return new Response('Method not allowed', { 
      status: 405,
      headers: corsHeaders
    })
  }

  try {
    // Get the raw body for signature verification
    console.log('[WEBHOOK] [REQUEST] Reading request body...')
    const body = await req.text()
    console.log('[WEBHOOK] [REQUEST] Body length:', body.length, 'characters')
    console.log('[WEBHOOK] [REQUEST] Body preview:', body.substring(0, 200) + '...')
    
    const signature = req.headers.get('stripe-signature')

    if (!signature) {
      console.log('[WEBHOOK] [ERROR] [AUTH] Missing Stripe signature header')
      console.log('[WEBHOOK] [ERROR] [AUTH] Cannot verify webhook authenticity')
      console.log('[WEBHOOK] [ERROR] [AUTH] Returning 400 status')
      return new Response('Missing signature', { status: 400 })
    }

    console.log('[WEBHOOK] [AUTH] Stripe signature found')
    console.log('[WEBHOOK] [AUTH] Signature preview:', signature.substring(0, 50) + '...')
    console.log('[WEBHOOK] [AUTH] Verifying webhook signature...')
    console.log('[WEBHOOK] [AUTH] Using webhook secret:', STRIPE_WEBHOOK_SECRET ? '[SET]' : '[MISSING]')
    
    // Verify webhook signature (use async version for Deno)
    let event: Stripe.Event
    try {
      event = await stripe.webhooks.constructEventAsync(body, signature, STRIPE_WEBHOOK_SECRET)
      console.log('[WEBHOOK] [AUTH] Signature verified successfully')
      console.log('[WEBHOOK] [AUTH] Webhook is authentic')
      console.log('[WEBHOOK] [EVENT] Event ID:', event.id)
      console.log('[WEBHOOK] [EVENT] Event type:', event.type)
      console.log('[WEBHOOK] [EVENT] Event created:', new Date(event.created * 1000).toISOString())
      console.log('[WEBHOOK] [EVENT] Event livemode:', event.livemode)
    } catch (err) {
      console.log('[WEBHOOK] [ERROR] [AUTH] Signature verification failed')
      console.log('[WEBHOOK] [ERROR] [AUTH] Error message:', (err as Error).message)
      console.log('[WEBHOOK] [ERROR] [AUTH] Error stack:', (err as Error).stack)
      console.log('[WEBHOOK] [ERROR] [AUTH] This webhook is not from Stripe or signature is invalid')
      console.log('[WEBHOOK] [ERROR] [AUTH] Returning 400 status')
      return new Response(`Webhook signature verification failed: ${(err as Error).message}`, { status: 400 })
    }

    // Handle payment_intent.succeeded event
    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object as Stripe.PaymentIntent
      
      console.log('========================================')
      console.log('[WEBHOOK] [START] Processing payment_intent.succeeded')
      console.log('[WEBHOOK] [PAYMENT] PaymentIntent ID:', paymentIntent.id)
      console.log('[WEBHOOK] [PAYMENT] Amount (cents):', paymentIntent.amount)
      console.log('[WEBHOOK] [PAYMENT] Amount (EGP):', paymentIntent.amount / 100)
      console.log('[WEBHOOK] [PAYMENT] Currency:', paymentIntent.currency)
      console.log('[WEBHOOK] [PAYMENT] Status:', paymentIntent.status)
      console.log('[WEBHOOK] [PAYMENT] Customer ID:', paymentIntent.customer)
      console.log('[WEBHOOK] [PAYMENT] Created:', new Date(paymentIntent.created * 1000).toISOString())

      // Extract and validate metadata
      const metadata = paymentIntent.metadata
      console.log('[WEBHOOK] [METADATA] Raw metadata:', JSON.stringify(metadata, null, 2))
      console.log('[WEBHOOK] [METADATA] user_id:', metadata.user_id || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] restaurant_id:', metadata.restaurant_id || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] ngo_id:', metadata.ngo_id || '[NONE]')
      console.log('[WEBHOOK] [METADATA] delivery_method:', metadata.delivery_method || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] delivery_address:', metadata.delivery_address || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] phone_number:', metadata.phone_number || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] delivery_fee:', metadata.delivery_fee || '0')
      console.log('[WEBHOOK] [METADATA] service_fee:', metadata.service_fee || '0')
      console.log('[WEBHOOK] [METADATA] delivery_latitude:', metadata.delivery_latitude || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] delivery_longitude:', metadata.delivery_longitude || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] pickup_latitude:', metadata.pickup_latitude || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] pickup_longitude:', metadata.pickup_longitude || '[MISSING]')
      console.log('[WEBHOOK] [METADATA] special_instructions:', metadata.special_instructions || '[NONE]')
      console.log('[WEBHOOK] [METADATA] promo_code:', metadata.promo_code || '[NONE]')
      console.log('[WEBHOOK] [METADATA] discount_percentage:', metadata.discount_percentage || '0')
      console.log('[WEBHOOK] [METADATA] discount_amount:', metadata.discount_amount || '0')
      console.log('[WEBHOOK] [METADATA] original_total:', metadata.original_total || '[NONE]')

      if (!metadata.user_id) {
        console.log('[WEBHOOK] [ERROR] [VALIDATION] Missing user_id in metadata')
        console.log('[WEBHOOK] [ERROR] [VALIDATION] Cannot create order without user_id')
        return new Response('Missing user_id in metadata', { status: 400 })
      }

      if (!metadata.restaurant_id) {
        console.log('[WEBHOOK] [ERROR] [VALIDATION] Missing restaurant_id in metadata')
        console.log('[WEBHOOK] [ERROR] [VALIDATION] Cannot create order without restaurant_id')
        return new Response('Missing restaurant_id in metadata', { status: 400 })
      }

      // Parse order items
      console.log('[WEBHOOK] [ITEMS] Parsing order_items from metadata...')
      console.log('[WEBHOOK] [ITEMS] Raw order_items string:', metadata.order_items || '[MISSING]')
      
      let orderItems
      try {
        orderItems = JSON.parse(metadata.order_items || '[]')
        console.log('[WEBHOOK] [ITEMS] Successfully parsed order_items')
        console.log('[WEBHOOK] [ITEMS] Order items count:', orderItems.length)
        console.log('[WEBHOOK] [ITEMS] Order items details:', JSON.stringify(orderItems, null, 2))
        
        if (orderItems.length === 0) {
          console.log('[WEBHOOK] [ERROR] [VALIDATION] No items in order')
          return new Response('Order must contain at least one item', { status: 400 })
        }

        // Validate each item
        orderItems.forEach((item: any, index: number) => {
          console.log(`[WEBHOOK] [ITEMS] [${index}] meal_id:`, item.meal_id || '[MISSING]')
          console.log(`[WEBHOOK] [ITEMS] [${index}] quantity:`, item.quantity || '[MISSING]')
          console.log(`[WEBHOOK] [ITEMS] [${index}] price:`, item.price || '[MISSING]')
          console.log(`[WEBHOOK] [ITEMS] [${index}] customizations:`, item.customizations || '[NONE]')
        })
      } catch (err) {
        console.log('[WEBHOOK] [ERROR] [PARSE] Failed to parse order_items:', (err as Error).message)
        console.log('[WEBHOOK] [ERROR] [PARSE] Error stack:', (err as Error).stack)
        return new Response('Invalid order_items format', { status: 400 })
      }

      // Check if order already exists
      console.log('[WEBHOOK] [CHECK] Checking for existing order with payment_intent_id:', paymentIntent.id)
      const { data: existingOrder, error: checkError } = await supabase
        .from('orders')
        .select('id, order_number, status, payment_status, created_at')
        .eq('stripe_payment_intent_id', paymentIntent.id)
        .single()

      if (checkError && checkError.code !== 'PGRST116') {
        console.log('[WEBHOOK] [ERROR] [CHECK] Error checking for existing order:', checkError.message)
        console.log('[WEBHOOK] [ERROR] [CHECK] Error details:', JSON.stringify(checkError, null, 2))
      }

      if (existingOrder) {
        console.log('[WEBHOOK] [CHECK] Order already exists')
        console.log('[WEBHOOK] [CHECK] Existing order ID:', existingOrder.id)
        console.log('[WEBHOOK] [CHECK] Existing order number:', existingOrder.order_number)
        console.log('[WEBHOOK] [CHECK] Existing order status:', existingOrder.status)
        console.log('[WEBHOOK] [CHECK] Existing order payment_status:', existingOrder.payment_status)
        console.log('[WEBHOOK] [CHECK] Existing order created_at:', existingOrder.created_at)
        return new Response(JSON.stringify({ 
          success: true, 
          message: 'Order already processed',
          order_id: existingOrder.id,
          order_number: existingOrder.order_number
        }), {
          headers: { 'Content-Type': 'application/json' },
          status: 200
        })
      }

      console.log('[WEBHOOK] [CHECK] No existing order found - proceeding with creation')

      // Generate order number
      const timestamp = Date.now()
      const randomPart = Math.random().toString(36).substr(2, 9).toUpperCase()
      const orderNumber = `ORD-${timestamp}-${randomPart}`
      console.log('[WEBHOOK] [ORDER] Generated order number:', orderNumber)
      console.log('[WEBHOOK] [ORDER] Timestamp:', timestamp)
      console.log('[WEBHOOK] [ORDER] Random part:', randomPart)

      // Prepare order data - using exact column names from orders table
      // Accept both delivery_* and pickup_* keys for coordinates (backward compatibility)
      const latitude = metadata.pickup_latitude || metadata.delivery_latitude
      const longitude = metadata.pickup_longitude || metadata.delivery_longitude
      
      // Map delivery_method to delivery_type for database
      // CRITICAL: Database constraint requires 'pickup', 'delivery', or 'donation' (NOT 'donate')
      let deliveryType = metadata.delivery_method || metadata.delivery_type || 'delivery'
      console.log('[WEBHOOK] [ORDER] Raw delivery_method from metadata:', deliveryType)
      
      // Map 'donate' to 'donation' for database constraint
      if (deliveryType === 'donate') {
        deliveryType = 'donation'
        console.log('[WEBHOOK] [ORDER] Mapped "donate" to "donation" for database')
      }
      
      console.log('[WEBHOOK] [ORDER] Final delivery_type for database:', deliveryType)
      
      const orderData = {
        user_id: metadata.user_id,
        restaurant_id: metadata.restaurant_id,
        ngo_id: metadata.ngo_id && metadata.ngo_id.trim() !== '' ? metadata.ngo_id : null,
        order_number: orderNumber,
        total_amount: paymentIntent.amount / 100,
        original_total: metadata.original_total ? parseFloat(metadata.original_total) : (paymentIntent.amount / 100),
        delivery_fee: parseFloat(metadata.delivery_fee || '0'),
        service_fee: parseFloat(metadata.service_fee || '0'),
        promo_code: metadata.promo_code || null,
        discount_percentage: metadata.discount_percentage ? parseFloat(metadata.discount_percentage) : 0,
        discount_amount: metadata.discount_amount ? parseFloat(metadata.discount_amount) : 0,
        status: 'pending',
        payment_status: 'paid',
        payment_method: 'card',
        stripe_payment_intent_id: paymentIntent.id,
        delivery_address: metadata.delivery_address || null,
        pickup_latitude: latitude ? parseFloat(latitude) : null,
        pickup_longitude: longitude ? parseFloat(longitude) : null,
        special_instructions: metadata.special_instructions || null,
        delivery_type: deliveryType,
      }

      console.log('[WEBHOOK] [ORDER] Prepared order data:')
      console.log('[WEBHOOK] [ORDER] user_id:', orderData.user_id)
      console.log('[WEBHOOK] [ORDER] restaurant_id:', orderData.restaurant_id)
      console.log('[WEBHOOK] [ORDER] ngo_id:', orderData.ngo_id)
      console.log('[WEBHOOK] [ORDER] order_number:', orderData.order_number)
      console.log('[WEBHOOK] [ORDER] total_amount:', orderData.total_amount)
      console.log('[WEBHOOK] [ORDER] original_total:', orderData.original_total)
      console.log('[WEBHOOK] [ORDER] delivery_fee:', orderData.delivery_fee)
      console.log('[WEBHOOK] [ORDER] service_fee:', orderData.service_fee)
      console.log('[WEBHOOK] [ORDER] promo_code:', orderData.promo_code)
      console.log('[WEBHOOK] [ORDER] discount_percentage:', orderData.discount_percentage)
      console.log('[WEBHOOK] [ORDER] discount_amount:', orderData.discount_amount)
      console.log('[WEBHOOK] [ORDER] status:', orderData.status)
      console.log('[WEBHOOK] [ORDER] payment_status:', orderData.payment_status)
      console.log('[WEBHOOK] [ORDER] payment_method:', orderData.payment_method)
      console.log('[WEBHOOK] [ORDER] stripe_payment_intent_id:', orderData.stripe_payment_intent_id)
      console.log('[WEBHOOK] [ORDER] delivery_address:', orderData.delivery_address)
      console.log('[WEBHOOK] [ORDER] pickup_latitude:', orderData.pickup_latitude)
      console.log('[WEBHOOK] [ORDER] pickup_longitude:', orderData.pickup_longitude)
      console.log('[WEBHOOK] [ORDER] delivery_type:', orderData.delivery_type)
      console.log('[WEBHOOK] [ORDER] special_instructions:', orderData.special_instructions)

      // Create order
      console.log('[WEBHOOK] [INSERT] Attempting to insert order into database...')
      console.log('[WEBHOOK] [INSERT] Using service role key for authentication')
      console.log('[WEBHOOK] [INSERT] Target table: orders')
      
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single()

      if (orderError) {
        console.log('[WEBHOOK] [ERROR] [INSERT] Failed to create order')
        console.log('[WEBHOOK] [ERROR] [INSERT] Error message:', orderError.message)
        console.log('[WEBHOOK] [ERROR] [INSERT] Error code:', orderError.code)
        console.log('[WEBHOOK] [ERROR] [INSERT] Error details:', orderError.details)
        console.log('[WEBHOOK] [ERROR] [INSERT] Error hint:', orderError.hint)
        console.log('[WEBHOOK] [ERROR] [INSERT] Full error object:', JSON.stringify(orderError, null, 2))
        console.log('[WEBHOOK] [ERROR] [INSERT] Order data that failed:', JSON.stringify(orderData, null, 2))
        return new Response(`Failed to create order: ${orderError.message}`, { status: 500 })
      }

      if (!order) {
        console.log('[WEBHOOK] [ERROR] [INSERT] Order creation returned no data')
        console.log('[WEBHOOK] [ERROR] [INSERT] This should not happen - no error but no data')
        return new Response('Order creation failed - no data returned', { status: 500 })
      }

      console.log('[WEBHOOK] [SUCCESS] [INSERT] Order created successfully')
      console.log('[WEBHOOK] [SUCCESS] [INSERT] Order ID:', order.id)
      console.log('[WEBHOOK] [SUCCESS] [INSERT] Order number:', order.order_number)
      console.log('[WEBHOOK] [SUCCESS] [INSERT] Order status:', order.status)
      console.log('[WEBHOOK] [SUCCESS] [INSERT] Order payment_status:', order.payment_status)
      console.log('[WEBHOOK] [SUCCESS] [INSERT] Full order object:', JSON.stringify(order, null, 2))

      // Create order items
      console.log('[WEBHOOK] [ITEMS] [INSERT] Preparing order items for insertion...')
      const orderItemsToInsert = orderItems.map((item: any, index: number) => {
        const itemData = {
          order_id: order.id,
          meal_id: item.meal_id,
          quantity: item.quantity,
          price_at_time: item.price,
          customizations: item.customizations || null,
        }
        console.log(`[WEBHOOK] [ITEMS] [INSERT] [${index}] Prepared item:`, JSON.stringify(itemData, null, 2))
        return itemData
      })

      console.log('[WEBHOOK] [ITEMS] [INSERT] Total items to insert:', orderItemsToInsert.length)
      console.log('[WEBHOOK] [ITEMS] [INSERT] Attempting to insert order items...')
      console.log('[WEBHOOK] [ITEMS] [INSERT] Target table: order_items')

      const { data: insertedItems, error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItemsToInsert)
        .select()

      if (itemsError) {
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Failed to create order items')
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Error message:', itemsError.message)
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Error code:', itemsError.code)
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Error details:', itemsError.details)
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Error hint:', itemsError.hint)
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Full error object:', JSON.stringify(itemsError, null, 2))
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Items data that failed:', JSON.stringify(orderItemsToInsert, null, 2))
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Order was created but items failed')
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Order ID:', order.id)
        console.log('[WEBHOOK] [ERROR] [ITEMS] [INSERT] Manual intervention may be required')
        return new Response(`Order created but items failed: ${itemsError.message}`, { status: 500 })
      }

      console.log('[WEBHOOK] [SUCCESS] [ITEMS] [INSERT] Order items created successfully')
      console.log('[WEBHOOK] [SUCCESS] [ITEMS] [INSERT] Items inserted:', insertedItems?.length || 0)
      console.log('[WEBHOOK] [SUCCESS] [ITEMS] [INSERT] Items details:', JSON.stringify(insertedItems, null, 2))

      console.log('[WEBHOOK] [SUCCESS] [COMPLETE] Order processing complete')
      console.log('[WEBHOOK] [SUCCESS] [COMPLETE] Order ID:', order.id)
      console.log('[WEBHOOK] [SUCCESS] [COMPLETE] Order Number:', order.order_number)
      console.log('[WEBHOOK] [SUCCESS] [COMPLETE] Total Amount:', order.total_amount, 'EGP')
      console.log('[WEBHOOK] [SUCCESS] [COMPLETE] Items Count:', insertedItems?.length || 0)
      console.log('========================================')

      return new Response(JSON.stringify({ 
        success: true,
        order_id: order.id,
        order_number: order.order_number,
        total_amount: order.total_amount,
        items_count: insertedItems?.length || 0
      }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      })
    }

    // Handle other event types
    console.log('[WEBHOOK] [EVENT] Event type not handled:', event.type)
    console.log('[WEBHOOK] [EVENT] Supported events: payment_intent.succeeded')
    console.log('[WEBHOOK] [EVENT] Returning success acknowledgment')
    return new Response(JSON.stringify({ received: true, event_type: event.type }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200
    })

  } catch (error) {
    console.log('[WEBHOOK] [ERROR] [UNEXPECTED] Unexpected error occurred')
    console.log('[WEBHOOK] [ERROR] [UNEXPECTED] Error message:', (error as Error).message)
    console.log('[WEBHOOK] [ERROR] [UNEXPECTED] Error name:', (error as Error).name)
    console.log('[WEBHOOK] [ERROR] [UNEXPECTED] Error stack:', (error as Error).stack)
    console.log('[WEBHOOK] [ERROR] [UNEXPECTED] Full error object:', JSON.stringify(error, null, 2))
    console.log('[WEBHOOK] [ERROR] [UNEXPECTED] Returning 500 status')
    return new Response(`Webhook error: ${(error as Error).message}`, { status: 500 })
  }
})
