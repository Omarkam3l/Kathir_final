// =====================================================
// CREATE PAYMENT INTENT - Supabase Edge Function
// =====================================================
// Creates a Stripe PaymentIntent with server-side price calculation
// This ensures prices cannot be manipulated by the client
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  console.log('========================================')
  console.log('🚀 CREATE PAYMENT INTENT')
  console.log('Timestamp:', new Date().toISOString())
  console.log('========================================')

  try {
    // 1. Authenticate user
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      console.error('❌ Authentication failed:', authError)
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log('✅ User authenticated:', user.id)

    // 2. Parse request body
    const { 
      delivery_method, 
      delivery_address, 
      delivery_latitude,
      delivery_longitude,
      phone_number,
      special_instructions,
      ngo_id,
      promo_code
    } = await req.json()
    console.log('📦 Request data:', { 
      delivery_method, 
      delivery_address, 
      delivery_latitude,
      delivery_longitude,
      phone_number,
      ngo_id,
      promo_code
    })

    // 3. Fetch cart items from database (NEVER trust frontend prices)
    console.log('🛒 Fetching cart items from database...')
    const { data: cartItems, error: cartError } = await supabase
      .from('cart_items')
      .select(`
        id,
        quantity,
        meal_id,
        meals (
          id,
          title,
          discounted_price,
          quantity_available,
          restaurant_id,
          restaurants (
            restaurant_name
          )
        )
      `)
      .eq('user_id', user.id)

    if (cartError) {
      console.error('❌ Error fetching cart:', cartError)
      return new Response(JSON.stringify({ error: 'Failed to fetch cart' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 4. Validate cart is not empty
    if (!cartItems || cartItems.length === 0) {
      console.log('⚠️ Cart is empty')
      return new Response(JSON.stringify({ error: 'Cart is empty' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log(`✅ Found ${cartItems.length} items in cart`)

    // 5. Validate meal availability
    for (const item of cartItems) {
      if (!item.meals) {
        console.error(`❌ Meal not found for cart item ${item.id}`)
        return new Response(JSON.stringify({ error: 'Some meals are no longer available' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      if (item.meals.quantity_available < item.quantity) {
        console.error(`❌ Insufficient quantity for meal: ${item.meals.title}`)
        return new Response(JSON.stringify({ 
          error: `${item.meals.title} is out of stock (available: ${item.meals.quantity_available})` 
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    console.log('✅ All meals are available')

    // 6. Calculate prices SERVER-SIDE (CRITICAL SECURITY)
    console.log('💰 Calculating prices on server...')
    const subtotal = cartItems.reduce((sum, item) => {
      return sum + (item.meals.discounted_price * item.quantity)
    }, 0)

    const deliveryFee = delivery_method === 'delivery' ? 2.99 : 0
    const platformFee = delivery_method === 'donate' ? 0 : 1.5
    let totalBeforeDiscount = subtotal + deliveryFee + platformFee
    
    // 6a. Validate and apply promo code discount
    let discountAmount = 0
    let discountPercentage = 0
    let promoCodeApplied = null
    
    if (promo_code && promo_code.trim() !== '') {
      console.log('🎟️ Validating promo code:', promo_code)
      
      try {
        const { data: promoValidation, error: promoError } = await supabase
          .rpc('validate_promo_code', {
            p_code: promo_code.toUpperCase(),
            p_order_amount: totalBeforeDiscount
          })
        
        if (promoError) {
          console.error('❌ Error validating promo code:', promoError)
        } else if (promoValidation && promoValidation.length > 0) {
          const validation = promoValidation[0]
          
          if (validation.is_valid) {
            discountPercentage = validation.discount_percentage
            discountAmount = (totalBeforeDiscount * discountPercentage) / 100
            promoCodeApplied = promo_code.toUpperCase()
            
            console.log(`✅ Promo code valid: ${discountPercentage}% discount`)
            console.log(`   Discount amount: ${discountAmount.toFixed(2)} EGP`)
          } else {
            console.log(`⚠️ Promo code invalid: ${validation.message}`)
          }
        }
      } catch (error) {
        console.error('❌ Error checking promo code:', error)
        // Continue without discount if validation fails
      }
    }
    
    const total = totalBeforeDiscount - discountAmount

    console.log(`  Subtotal: ${subtotal.toFixed(2)} EGP`)
    console.log(`  Delivery Fee: ${deliveryFee.toFixed(2)} EGP`)
    console.log(`  Platform Fee: ${platformFee.toFixed(2)} EGP`)
    if (discountAmount > 0) {
      console.log(`  Discount (${discountPercentage}%): -${discountAmount.toFixed(2)} EGP`)
    }
    console.log(`  Total: ${total.toFixed(2)} EGP`)

    // 7. Validate delivery requirements
    if (delivery_method === 'delivery' && (!delivery_address || delivery_address.trim() === '')) {
      console.log('❌ Delivery address required')
      return new Response(JSON.stringify({ error: 'Delivery address is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (delivery_method === 'donate' && (!ngo_id || ngo_id.trim() === '')) {
      console.log('❌ NGO selection required')
      return new Response(JSON.stringify({ error: 'Please select an NGO for donation' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 8. Get or create Stripe customer
    console.log('👤 Getting/creating Stripe customer...')
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('stripe_customer_id, email, full_name')
      .eq('id', user.id)
      .single()

    if (profileError) {
      console.error('❌ Error fetching profile:', profileError)
      return new Response(JSON.stringify({ error: 'Failed to fetch user profile' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    let customerId = profile.stripe_customer_id

    if (!customerId) {
      console.log('  Creating new Stripe customer...')
      const customer = await stripe.customers.create({
        email: profile.email,
        name: profile.full_name,
        metadata: {
          supabase_user_id: user.id,
        },
      })
      customerId = customer.id
      console.log(`  ✅ Created customer: ${customerId}`)

      // Save customer ID to database
      await supabase
        .from('profiles')
        .update({ stripe_customer_id: customerId })
        .eq('id', user.id)
      
      console.log('  ✅ Saved customer ID to database')
    } else {
      console.log(`  ✅ Using existing customer: ${customerId}`)
    }

    // 9. Create PaymentIntent with metadata
    console.log('💳 Creating Stripe PaymentIntent...')
    
    // Get restaurant_id from first cart item (assuming single restaurant order)
    const restaurantId = cartItems[0].meals.restaurant_id
    console.log(`  Restaurant ID: ${restaurantId}`)
    
    // Prepare order items for metadata
    const orderItems = cartItems.map(item => ({
      meal_id: item.meal_id,
      quantity: item.quantity,
      price: item.meals.discounted_price,
      title: item.meals.title,
    }))
    console.log(`  Order items prepared: ${orderItems.length} items`)
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(total * 100), // Convert EGP to cents
      currency: 'egp',
      customer: customerId,
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        user_id: user.id,
        restaurant_id: restaurantId,
        delivery_method,
        delivery_address: delivery_address || '',
        delivery_latitude: delivery_latitude?.toString() || '',
        delivery_longitude: delivery_longitude?.toString() || '',
        phone_number: phone_number || '',
        special_instructions: special_instructions || '',
        ngo_id: ngo_id || '',
        delivery_fee: deliveryFee.toFixed(2),
        service_fee: platformFee.toFixed(2),
        original_total: totalBeforeDiscount.toFixed(2),
        promo_code: promoCodeApplied || '',
        discount_percentage: discountPercentage.toString(),
        discount_amount: discountAmount.toFixed(2),
        order_items: JSON.stringify(orderItems),
      },
      description: `Kathir Order - ${cartItems.length} items from ${cartItems[0].meals.restaurants.restaurant_name}`,
    })

    console.log(`✅ PaymentIntent created: ${paymentIntent.id}`)
    console.log(`   Amount: ${paymentIntent.amount / 100} EGP`)
    console.log(`   Status: ${paymentIntent.status}`)
    console.log(`   Metadata includes: user_id, restaurant_id, order_items, delivery info, promo code`)

    // 10. Create ephemeral key for customer (needed for mobile SDK)
    console.log('🔑 Creating ephemeral key...')
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: '2023-10-16' }
    )
    console.log('✅ Ephemeral key created')

    // 11. Return response to frontend
    console.log('========================================')
    console.log('✅ SUCCESS - Returning client secret')
    console.log('========================================')

    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        customerId: customerId,
        ephemeralKey: ephemeralKey.secret,
        amount: total,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('❌ ERROR:', error)
    console.error('Stack:', error.stack)
    return new Response(
      JSON.stringify({ 
        error: error.message || 'Internal server error',
        details: error.toString(),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
