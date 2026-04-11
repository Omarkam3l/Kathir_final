// =====================================================
// CREATE FREE ORDER - Supabase Edge Function
// =====================================================
// Creates an order without payment (100% discount)
// Used when promo code gives 100% discount
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  console.log('========================================')
  console.log('[FREE-ORDER] [START] Create free order request')
  console.log('[FREE-ORDER] [TIME] Timestamp:', new Date().toISOString())
  console.log('========================================')

  try {
    // 1. Authenticate user
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.log('[FREE-ORDER] [ERROR] [AUTH] Missing authorization header')
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      console.log('[FREE-ORDER] [ERROR] [AUTH] Authentication failed:', authError?.message)
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log('[FREE-ORDER] [AUTH] User authenticated:', user.id)

    // 2. Parse request body
    let requestBody
    try {
      requestBody = await req.json()
    } catch (e) {
      console.log('[FREE-ORDER] [ERROR] [PARSE] Failed to parse request body:', e.message)
      return new Response(JSON.stringify({ error: 'Invalid request body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { 
      delivery_method, 
      delivery_address, 
      delivery_latitude,
      delivery_longitude,
      phone_number,
      special_instructions,
      ngo_id,
      promo_code
    } = requestBody
    
    console.log('[FREE-ORDER] [REQUEST] Delivery method:', delivery_method)
    console.log('[FREE-ORDER] [REQUEST] Delivery address:', delivery_address)
    console.log('[FREE-ORDER] [REQUEST] Promo code:', promo_code)

    // 3. Fetch cart items from database
    console.log('[FREE-ORDER] [CART] Fetching cart items from database...')
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
      console.log('[FREE-ORDER] [ERROR] [CART] Error fetching cart:', cartError.message)
      console.log('[FREE-ORDER] [ERROR] [CART] Error details:', JSON.stringify(cartError))
      return new Response(JSON.stringify({ error: 'Failed to fetch cart', details: cartError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!cartItems || cartItems.length === 0) {
      console.log('[FREE-ORDER] [ERROR] [CART] Cart is empty')
      return new Response(JSON.stringify({ error: 'Cart is empty' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log('[FREE-ORDER] [CART] Found', cartItems.length, 'items in cart')

    // 4. Validate meal availability
    console.log('[FREE-ORDER] [VALIDATE] Checking meal availability...')
    for (const item of cartItems) {
      if (!item.meals) {
        console.log('[FREE-ORDER] [ERROR] [VALIDATE] Meal not found for cart item:', item.id)
        return new Response(JSON.stringify({ error: 'Some meals are no longer available' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      if (item.meals.quantity_available < item.quantity) {
        console.log('[FREE-ORDER] [ERROR] [VALIDATE] Insufficient quantity for meal:', item.meals.title)
        console.log('[FREE-ORDER] [ERROR] [VALIDATE] Available:', item.meals.quantity_available, 'Requested:', item.quantity)
        return new Response(JSON.stringify({ 
          error: `${item.meals.title} is out of stock (available: ${item.meals.quantity_available})` 
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    console.log('[FREE-ORDER] [VALIDATE] All meals are available')

    // 5. Calculate prices
    console.log('[FREE-ORDER] [CALCULATE] Calculating prices...')
    const subtotal = cartItems.reduce((sum, item) => {
      return sum + (item.meals.discounted_price * item.quantity)
    }, 0)

    const deliveryFee = delivery_method === 'delivery' ? 2.99 : 0
    const platformFee = delivery_method === 'donate' ? 0 : 1.5
    let totalBeforeDiscount = subtotal + deliveryFee + platformFee
    
    console.log('[FREE-ORDER] [CALCULATE] Subtotal:', subtotal.toFixed(2), 'EGP')
    console.log('[FREE-ORDER] [CALCULATE] Delivery Fee:', deliveryFee.toFixed(2), 'EGP')
    console.log('[FREE-ORDER] [CALCULATE] Platform Fee:', platformFee.toFixed(2), 'EGP')
    console.log('[FREE-ORDER] [CALCULATE] Total before discount:', totalBeforeDiscount.toFixed(2), 'EGP')
    
    // 6. Validate promo code (must be 100% discount)
    let discountAmount = 0
    let discountPercentage = 0
    
    if (promo_code && promo_code.trim() !== '') {
      console.log('[FREE-ORDER] [PROMO] Validating promo code:', promo_code)
      
      try {
        const { data: promoValidation, error: promoError } = await supabase
          .rpc('validate_promo_code', {
            p_code: promo_code.toUpperCase(),
            p_order_amount: totalBeforeDiscount
          })
        
        if (promoError) {
          console.log('[FREE-ORDER] [ERROR] [PROMO] Error validating promo code:', promoError.message)
          console.log('[FREE-ORDER] [ERROR] [PROMO] Error details:', JSON.stringify(promoError))
          return new Response(JSON.stringify({ error: 'Failed to validate promo code', details: promoError.message }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }
        
        console.log('[FREE-ORDER] [PROMO] Validation response:', JSON.stringify(promoValidation))
        
        if (promoValidation && promoValidation.length > 0) {
          const validation = promoValidation[0]
          
          if (validation.is_valid) {
            discountPercentage = validation.discount_percentage
            discountAmount = (totalBeforeDiscount * discountPercentage) / 100
            
            console.log('[FREE-ORDER] [PROMO] Promo code valid:', discountPercentage, '% discount')
            console.log('[FREE-ORDER] [PROMO] Discount amount:', discountAmount.toFixed(2), 'EGP')
          } else {
            console.log('[FREE-ORDER] [ERROR] [PROMO] Promo code invalid:', validation.message)
            return new Response(JSON.stringify({ error: validation.message }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }
        } else {
          console.log('[FREE-ORDER] [ERROR] [PROMO] No validation result returned')
          return new Response(JSON.stringify({ error: 'Promo code validation failed' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }
      } catch (e) {
        console.log('[FREE-ORDER] [ERROR] [PROMO] Exception validating promo code:', e.message)
        console.log('[FREE-ORDER] [ERROR] [PROMO] Stack:', e.stack)
        return new Response(JSON.stringify({ error: 'Failed to validate promo code', details: e.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    } else {
      console.log('[FREE-ORDER] [ERROR] [PROMO] No promo code provided')
      return new Response(JSON.stringify({ error: 'Promo code is required for free orders' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    
    const total = totalBeforeDiscount - discountAmount

    console.log('[FREE-ORDER] [CALCULATE] Discount:', discountPercentage, '%')
    console.log('[FREE-ORDER] [CALCULATE] Discount amount:', discountAmount.toFixed(2), 'EGP')
    console.log('[FREE-ORDER] [CALCULATE] Final total:', total.toFixed(2), 'EGP')

    // 7. Verify order is actually free
    if (total > 0.01) {
      console.log('[FREE-ORDER] [ERROR] [VALIDATE] Order is not free, total:', total)
      return new Response(JSON.stringify({ 
        error: 'This endpoint is only for free orders (100% discount)',
        total: total
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 8. Generate order number
    const timestamp = Date.now()
    const randomPart = Math.random().toString(36).substr(2, 9).toUpperCase()
    const orderNumber = `ORD-${timestamp}-${randomPart}`
    console.log('[FREE-ORDER] [ORDER] Generated order number:', orderNumber)

    // 9. Get restaurant_id
    const restaurantId = cartItems[0].meals.restaurant_id
    console.log('[FREE-ORDER] [ORDER] Restaurant ID:', restaurantId)

    // 10. Create order
    console.log('[FREE-ORDER] [ORDER] Creating free order...')
    const orderData = {
      user_id: user.id,
      restaurant_id: restaurantId,
      order_number: orderNumber,
      subtotal: subtotal,
      total_amount: total, // Final amount after discount (0 for 100% off)
      original_total: totalBeforeDiscount, // Original total before discount (for restaurant)
      delivery_fee: deliveryFee,
      service_fee: platformFee,
      promo_code: promo_code.toUpperCase(),
      discount_percentage: discountPercentage,
      discount_amount: discountAmount,
      status: 'pending',
      payment_status: 'paid', // Marked as paid (100% discount)
      payment_method: 'card', // Use 'card' as payment method (100% discount via promo)
      delivery_address: delivery_address || null,
      pickup_latitude: delivery_latitude ? parseFloat(delivery_latitude.toString()) : null,
      pickup_longitude: delivery_longitude ? parseFloat(delivery_longitude.toString()) : null,
      special_instructions: special_instructions || null,
      delivery_type: delivery_method || 'delivery',
    }

    console.log('[FREE-ORDER] [ORDER] Order data:', JSON.stringify(orderData, null, 2))

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert(orderData)
      .select()
      .single()

    if (orderError) {
      console.log('[FREE-ORDER] [ERROR] [ORDER] Failed to create order:', orderError.message)
      console.log('[FREE-ORDER] [ERROR] [ORDER] Error code:', orderError.code)
      console.log('[FREE-ORDER] [ERROR] [ORDER] Error details:', JSON.stringify(orderError))
      console.log('[FREE-ORDER] [ERROR] [ORDER] Order data that failed:', JSON.stringify(orderData))
      return new Response(JSON.stringify({ 
        error: 'Failed to create order', 
        details: orderError.message,
        code: orderError.code
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log('[FREE-ORDER] [ORDER] Order created successfully, ID:', order.id)

    // 11. Create order items
    console.log('[FREE-ORDER] [ITEMS] Creating order items...')
    const orderItemsToInsert = cartItems.map((item, index) => {
      const itemData = {
        order_id: order.id,
        meal_id: item.meal_id,
        quantity: item.quantity,
        unit_price: item.meals.discounted_price,
        meal_title: item.meals.title,
      }
      console.log('[FREE-ORDER] [ITEMS] Item', index + 1, ':', JSON.stringify(itemData))
      return itemData
    })

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItemsToInsert)

    if (itemsError) {
      console.log('[FREE-ORDER] [ERROR] [ITEMS] Failed to create order items:', itemsError.message)
      console.log('[FREE-ORDER] [ERROR] [ITEMS] Error details:', JSON.stringify(itemsError))
      return new Response(JSON.stringify({ 
        error: 'Failed to create order items', 
        details: itemsError.message 
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log('[FREE-ORDER] [ITEMS] Order items created successfully')

    // 12. Update meal quantities
    console.log('[FREE-ORDER] [INVENTORY] Updating meal quantities...')
    for (const item of cartItems) {
      const newQuantity = item.meals.quantity_available - item.quantity
      console.log('[FREE-ORDER] [INVENTORY] Meal:', item.meals.title, 'Old qty:', item.meals.quantity_available, 'New qty:', newQuantity)
      
      const { error: updateError } = await supabase
        .from('meals')
        .update({
          quantity_available: newQuantity,
          status: newQuantity <= 0 ? 'sold' : 'active',
        })
        .eq('id', item.meal_id)
      
      if (updateError) {
        console.log('[FREE-ORDER] [ERROR] [INVENTORY] Failed to update meal quantity:', updateError.message)
        // Don't fail the order if inventory update fails
      }
    }

    console.log('[FREE-ORDER] [INVENTORY] Meal quantities updated')

    // 13. Clear user's cart
    console.log('[FREE-ORDER] [CART] Clearing cart...')
    const { error: clearError } = await supabase
      .from('cart_items')
      .delete()
      .eq('user_id', user.id)

    if (clearError) {
      console.log('[FREE-ORDER] [ERROR] [CART] Failed to clear cart:', clearError.message)
      // Don't fail the order if cart clear fails
    } else {
      console.log('[FREE-ORDER] [CART] Cart cleared successfully')
    }

    console.log('========================================')
    console.log('[FREE-ORDER] [SUCCESS] Free order created successfully')
    console.log('[FREE-ORDER] [SUCCESS] Order ID:', order.id)
    console.log('[FREE-ORDER] [SUCCESS] Order Number:', order.order_number)
    console.log('[FREE-ORDER] [SUCCESS] Promo Code:', promo_code)
    console.log('[FREE-ORDER] [SUCCESS] Discount:', discountPercentage, '%')
    console.log('========================================')

    return new Response(
      JSON.stringify({
        success: true,
        order_id: order.id,
        order_number: order.order_number,
        total_amount: 0,
        discount_percentage: discountPercentage,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.log('[FREE-ORDER] [ERROR] [UNEXPECTED] Unexpected error occurred')
    console.log('[FREE-ORDER] [ERROR] [UNEXPECTED] Error message:', error.message)
    console.log('[FREE-ORDER] [ERROR] [UNEXPECTED] Error name:', error.name)
    console.log('[FREE-ORDER] [ERROR] [UNEXPECTED] Error stack:', error.stack)
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
