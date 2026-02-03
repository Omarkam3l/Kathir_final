// Supabase Edge Function for NGO Operations
// Deploy: supabase functions deploy ngo-operations

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ClaimMealRequest {
  meal_id: string
  ngo_id: string
  quantity?: number
}

interface GetNearbyMealsRequest {
  latitude: number
  longitude: number
  radius_km?: number
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      throw new Error('Unauthorized')
    }

    const { action } = await req.json()

    switch (action) {
      case 'claim_meal':
        return await claimMeal(req, supabaseClient, user.id)
      
      case 'get_nearby_meals':
        return await getNearbyMeals(req, supabaseClient)
      
      case 'get_ngo_stats':
        return await getNgoStats(supabaseClient, user.id)
      
      case 'calculate_impact':
        return await calculateImpact(supabaseClient, user.id)
      
      default:
        throw new Error('Invalid action')
    }
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

async function claimMeal(req: Request, supabase: any, userId: string) {
  const { meal_id, quantity = 1 }: ClaimMealRequest = await req.json()

  // Get meal details
  const { data: meal, error: mealError } = await supabase
    .from('meals')
    .select('*, restaurants(*)')
    .eq('id', meal_id)
    .single()

  if (mealError || !meal) {
    throw new Error('Meal not found')
  }

  // Check availability
  if (meal.quantity_available < quantity) {
    throw new Error('Insufficient quantity available')
  }

  // Check if meal is still active
  if (meal.status !== 'active') {
    throw new Error('Meal is no longer available')
  }

  // Check expiry
  if (new Date(meal.expiry_date) < new Date()) {
    throw new Error('Meal has expired')
  }

  // Create order
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .insert({
      user_id: userId,
      ngo_id: userId,
      restaurant_id: meal.restaurant_id,
      meal_id: meal.id,
      status: 'pending',
      delivery_type: 'donation',
      subtotal: meal.discounted_price || 0,
      total_amount: meal.discounted_price || 0,
    })
    .select()
    .single()

  if (orderError) {
    throw new Error('Failed to create order: ' + orderError.message)
  }

  // Update meal quantity
  const newQuantity = meal.quantity_available - quantity
  const newStatus = newQuantity === 0 ? 'reserved' : 'active'

  await supabase
    .from('meals')
    .update({
      quantity_available: newQuantity,
      status: newStatus,
    })
    .eq('id', meal_id)

  // Send notification to restaurant (implement later)
  // await sendNotification(meal.restaurant_id, 'NGO claimed your meal')

  return new Response(
    JSON.stringify({
      success: true,
      order,
      message: 'Meal claimed successfully',
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  )
}

async function getNearbyMeals(req: Request, supabase: any) {
  const { latitude, longitude, radius_km = 5 }: GetNearbyMealsRequest = await req.json()

  // Note: This is a simplified version. For production, use PostGIS extension
  // with proper geospatial queries
  
  const { data: meals, error } = await supabase
    .from('meals')
    .select(`
      *,
      restaurants (
        profile_id,
        restaurant_name,
        rating,
        address_text
      )
    `)
    .eq('is_donation_available', true)
    .eq('status', 'active')
    .gt('quantity_available', 0)
    .gt('expiry_date', new Date().toISOString())
    .order('expiry_date', { ascending: true })
    .limit(50)

  if (error) {
    throw new Error('Failed to fetch meals: ' + error.message)
  }

  // Filter by distance (simplified - in production use PostGIS)
  // For now, return all meals
  const nearbyMeals = meals

  return new Response(
    JSON.stringify({
      success: true,
      meals: nearbyMeals,
      count: nearbyMeals.length,
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  )
}

async function getNgoStats(supabase: any, ngoId: string) {
  // Get total meals claimed
  const { data: completedOrders, error: ordersError } = await supabase
    .from('orders')
    .select('id, total_amount')
    .eq('ngo_id', ngoId)
    .eq('status', 'completed')

  if (ordersError) {
    throw new Error('Failed to fetch orders: ' + ordersError.message)
  }

  // Get active orders
  const { data: activeOrders, error: activeError } = await supabase
    .from('orders')
    .select('id')
    .eq('ngo_id', ngoId)
    .in('status', ['pending', 'paid', 'processing'])

  if (activeError) {
    throw new Error('Failed to fetch active orders: ' + activeError.message)
  }

  const mealsClaimed = completedOrders?.length || 0
  const carbonSaved = mealsClaimed * 2.5 // Average 2.5kg CO2 per meal
  const activeOrdersCount = activeOrders?.length || 0
  const totalValue = completedOrders?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0

  return new Response(
    JSON.stringify({
      success: true,
      stats: {
        meals_claimed: mealsClaimed,
        carbon_saved_kg: carbonSaved,
        active_orders: activeOrdersCount,
        total_value_saved: totalValue,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  )
}

async function calculateImpact(supabase: any, ngoId: string) {
  // Get all completed orders
  const { data: orders, error } = await supabase
    .from('orders')
    .select(`
      id,
      created_at,
      total_amount,
      order_items (
        quantity,
        meal_id
      )
    `)
    .eq('ngo_id', ngoId)
    .eq('status', 'completed')

  if (error) {
    throw new Error('Failed to fetch orders: ' + error.message)
  }

  const totalMeals = orders?.length || 0
  const totalCO2Saved = totalMeals * 2.5 // kg
  const totalWaterSaved = totalMeals * 50 // liters
  const totalMoneySaved = orders?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0
  const peopleHelped = totalMeals * 3 // Assuming 3 people per meal

  // Calculate monthly trend
  const now = new Date()
  const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1)
  const thisMonthOrders = orders?.filter(
    (order) => new Date(order.created_at) >= lastMonth
  ).length || 0

  return new Response(
    JSON.stringify({
      success: true,
      impact: {
        total_meals: totalMeals,
        co2_saved_kg: totalCO2Saved,
        water_saved_liters: totalWaterSaved,
        money_saved: totalMoneySaved,
        people_helped: peopleHelped,
        this_month_meals: thisMonthOrders,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  )
}
