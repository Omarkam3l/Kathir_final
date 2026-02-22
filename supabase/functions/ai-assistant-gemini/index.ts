// =====================================================
// AI SMART ASSISTANT - Supabase Edge Function (Gemini)
// =====================================================
// Google Gemini-powered assistant for Kathir app
// Features:
// - Natural language understanding
// - Function calling for database queries
// - Budget-aware recommendations
// - Cart management
// - Personalized suggestions
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface ChatRequest {
  message: string
  session_id?: string
  user_id: string
  budget?: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }
  
  console.log('🤖 AI Assistant (OpenRouter - Dual Model) function invoked')
  
  try {
    // Parse request
    const { message, session_id, user_id, budget }: ChatRequest = await req.json()
    
    console.log('📝 User message:', message)
    console.log('👤 User ID:', user_id)
    console.log('💰 Budget:', budget)
    
    // Initialize Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    // Get or create session
    let sessionId = session_id
    if (!sessionId) {
      const { data, error } = await supabase.rpc('get_or_create_ai_session', {
        p_user_id: user_id
      })
      
      if (error) throw error
      sessionId = data
      
      // Update budget if provided
      if (budget) {
        await supabase
          .from('ai_chat_sessions')
          .update({ budget_limit: budget })
          .eq('id', sessionId)
      }
    }
    
    console.log('💬 Session ID:', sessionId)
    
    // Get user context
    const { data: userContext, error: contextError } = await supabase.rpc(
      'get_user_context_for_ai',
      { p_user_id: user_id }
    )
    
    if (contextError) {
      console.error('Error fetching user context:', contextError)
    }
    
    console.log('👤 User context:', userContext)
    
    // Get session context
    const { data: session } = await supabase
      .from('ai_chat_sessions')
      .select('*')
      .eq('id', sessionId)
      .single()
    
    // Get conversation history
    const { data: history } = await supabase
      .from('ai_chat_messages')
      .select('role, content')
      .eq('session_id', sessionId)
      .order('created_at', { ascending: true })
      .limit(20)
    
    // Save user message
    await supabase
      .from('ai_chat_messages')
      .insert({
        session_id: sessionId,
        role: 'user',
        content: message
      })
    
    // Build system prompt
    const systemPrompt = buildSystemPrompt(userContext, session)
    
    // Build conversation for Gemini
    const conversationHistory = (history || []).map((msg: any) => ({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }]
    }))
    
    console.log('🔧 Calling OpenRouter with dual model strategy...')
    
    // Call OpenRouter with dual model strategy
    const aiResponse = await callOpenRouterWithFunctions(
      systemPrompt,
      conversationHistory,
      message,
      supabase,
      user_id,
      sessionId,
      session
    )
    
    const finalResponse = aiResponse.response
    const suggestions = aiResponse.suggestions || []
    
    console.log('🤖 Assistant response:', finalResponse)
    
    // Save assistant response
    const { data: savedMessage } = await supabase
      .from('ai_chat_messages')
      .insert({
        session_id: sessionId,
        role: 'assistant',
        content: finalResponse,
        metadata: { suggestions: suggestions.map((s: any) => s.id) }
      })
      .select()
      .single()
    
    // Save suggestions if any
    if (suggestions.length > 0) {
      const suggestionsToInsert = suggestions.map((meal: any) => ({
        session_id: sessionId,
        message_id: savedMessage.id,
        meal_id: meal.id,
        quantity: meal.suggested_quantity || 1,
        price: meal.effective_price,
        reason: meal.reason
      }))
      
      await supabase
        .from('ai_suggestions')
        .insert(suggestionsToInsert)
    }
    
    console.log('✅ AI Assistant response complete')
    
    return new Response(
      JSON.stringify({
        success: true,
        session_id: sessionId,
        message: finalResponse,
        suggestions: suggestions,
        budget_remaining: session?.budget_limit 
          ? session.budget_limit - (session.current_spending || 0)
          : null
      }),
      {
        status: 200,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        }
      }
    )
    
  } catch (error) {
    console.error('❌ AI Assistant error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      {
        status: 500,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        }
      }
    )
  }
})

function buildSystemPrompt(userContext: any, session: any): string {
  const budget = session?.budget_limit || 0
  const spent = session?.current_spending || 0
  const remaining = budget - spent
  
  return `You are Kathir AI, a food rescue assistant. Help users find discounted meals.

USER: ${userContext?.user_name || 'User'} | Budget: ${remaining} EGP | Points: ${userContext?.loyalty_points || 0}

WHEN TO USE FUNCTIONS:
- User wants meals/food/desserts/categories → CALL search_meals
- User asks "build cart", "find meals", "show me" → CALL search_meals  
- User mentions budget/price → CALL search_meals with max_price
- User asks about orders/history → CALL get_user_orders
- User asks about cart → CALL get_cart_contents

EXAMPLES:
"build my cart with desserts" → search_meals(category: "Desserts")
"meals under 50 EGP" → search_meals(max_price: 50)
"show me pizza" → search_meals(query: "pizza")
"my orders" → get_user_orders()

Be brief. Always call functions when user wants meal info.`
}

async function callOpenRouterWithFunctions(
  systemPrompt: string,
  history: any[],
  userMessage: string,
  supabase: any,
  userId: string,
  sessionId: string,
  session: any
) {
  // OpenRouter uses OpenAI-compatible API with function calling
  const tools = [
    {
      type: 'function',
      function: {
        name: 'search_meals',
        description: 'REQUIRED when user wants to find/search/build meals, food, desserts, or mentions categories/budget/price. Returns available meals matching criteria.',
        parameters: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Meal name/keyword (pizza, chicken, etc)'
            },
            category: {
              type: 'string',
              description: 'Category: Main Course, Dessert, Beverage, Appetizer, Bakery, Fast Food, Fruits & Veg, Vegan'
            },
            max_price: {
              type: 'number',
              description: 'Max price in EGP'
            },
            min_price: {
              type: 'number',
              description: 'Min price in EGP'
            },
            limit: {
              type: 'number',
              description: 'Results limit (default: 10)'
            }
          }
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'get_user_orders',
        description: 'Get order history when user asks about orders/history',
        parameters: {
          type: 'object',
          properties: {
            limit: {
              type: 'number',
              description: 'Number of orders (default: 5)'
            }
          }
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'get_cart_contents',
        description: 'Get cart when user asks about cart contents',
        parameters: {
          type: 'object',
          properties: {}
        }
      }
    }
  ]
  
  // Build messages array
  const messages = [
    {
      role: 'system',
      content: systemPrompt
    },
    ...history.map((msg: any) => ({
      role: msg.role,
      content: msg.parts[0].text
    })),
    {
      role: 'user',
      content: userMessage
    }
  ]
  
  // Use specialized FREE models for each task
  // Call 1 (Function calling): Nvidia Nemotron - best at structured tasks
  // Call 2 (Response generation): OpenAI GPT OSS 120B - best at natural language
  const FUNCTION_CALLING_MODEL = 'nvidia/nemotron-3-nano-30b-a3b:free'
  const RESPONSE_MODEL = 'openai/gpt-oss-120b:free'
  
  console.log(`🔍 Calling OpenRouter with ${FUNCTION_CALLING_MODEL} for function calling...`)
  
  // First API call to get function calls (using Nemotron - best for function calling)
  const initialResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://kathir.app',
      'X-Title': 'Kathir AI Assistant'
    },
    body: JSON.stringify({
      model: FUNCTION_CALLING_MODEL,
      messages: messages,
      tools: tools,
      tool_choice: 'auto',
      temperature: 0.3,
      max_tokens: 500
    })
  })
  
  const initialData = await initialResponse.json()
  console.log('🔍 OpenRouter response:', JSON.stringify(initialData, null, 2))
  
  if (initialData.error) {
    throw new Error(`OpenRouter error: ${initialData.error.message}`)
  }
  
  const choice = initialData.choices?.[0]
  const message = choice?.message
  
  // Check for function calls
  const toolCalls = message?.tool_calls
  
  if (toolCalls && toolCalls.length > 0) {
    console.log('🔧 Processing', toolCalls.length, 'function call(s)...')
    
    const toolMessages = []
    let suggestions: any[] = []
    
    for (const toolCall of toolCalls) {
      const functionName = toolCall.function.name
      const functionArgs = JSON.parse(toolCall.function.arguments || '{}')
      
      console.log(`📞 ${functionName}(${JSON.stringify(functionArgs)})`)
      
      const functionResult = await executeFunction(
        functionName,
        functionArgs,
        supabase,
        userId,
        sessionId,
        session
      )
      
      console.log(`✅ Result: ${functionResult.meals?.length || 0} meals`)
      
      if (functionName === 'search_meals' && functionResult.meals) {
        suggestions = functionResult.meals
      }
      
      toolMessages.push({
        role: 'tool',
        tool_call_id: toolCall.id,
        content: JSON.stringify(functionResult)
      })
    }
    
    // Second API call with function results (using GPT OSS 120B - best for natural language)
    console.log(`💬 Calling OpenRouter with ${RESPONSE_MODEL} for response generation...`)
    
    const finalResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://kathir.app',
        'X-Title': 'Kathir AI Assistant'
      },
      body: JSON.stringify({
        model: RESPONSE_MODEL,
        messages: [
          ...messages,
          message,
          ...toolMessages
        ],
        temperature: 0.7,
        max_tokens: 500
      })
    })
    
    const finalData = await finalResponse.json()
    const finalText = finalData.choices?.[0]?.message?.content || 'Found some meals for you!'
    
    return {
      response: finalText,
      suggestions: suggestions
    }
  } else {
    // No function calls - check if we should have called one
    const lowerMsg = userMessage.toLowerCase()
    const shouldSearch = lowerMsg.includes('meal') || lowerMsg.includes('food') || 
                        lowerMsg.includes('dessert') || lowerMsg.includes('cart') ||
                        lowerMsg.includes('budget') || lowerMsg.includes('find')
    
    if (shouldSearch) {
      console.log('⚠️ No function call but message suggests search needed')
      const result = await searchMeals({}, supabase, session)
      return {
        response: message?.content || 'Here are some meals for you:',
        suggestions: result.meals || []
      }
    }
    
    const responseText = message?.content || 'How can I help you find meals today?'
    return {
      response: responseText,
      suggestions: []
    }
  }
}

async function executeFunction(
  functionName: string,
  args: any,
  supabase: any,
  userId: string,
  sessionId: string,
  session: any
) {
  switch (functionName) {
    case 'search_meals':
      return await searchMeals(args, supabase, session)
    
    case 'get_user_orders':
      return await getUserOrders(args, supabase, userId)
    
    case 'get_cart_contents':
      return await getCartContents(supabase, userId)
    
    default:
      return { error: 'Unknown function' }
  }
}

async function searchMeals(args: any, supabase: any, session: any) {
  const { query, category, max_price, min_price, limit = 10 } = args
  
  // Parse category keywords to actual categories
  let actualCategory = category
  if (query) {
    const q = query.toLowerCase()
    if (q.includes('dessert') || q.includes('sweet')) actualCategory = 'Desserts'
    else if (q.includes('meal') || q.includes('main')) actualCategory = 'Meals'
    else if (q.includes('drink') || q.includes('beverage')) actualCategory = 'Beverages'
    else if (q.includes('seafood')) actualCategory = 'Meals'  // Seafood is usually meals
  }
  
  // Normalize category names (handle both singular and plural)
  if (actualCategory) {
    const cat = actualCategory.toLowerCase()
    if (cat === 'dessert') actualCategory = 'Desserts'
    else if (cat === 'meal' || cat === 'main course') actualCategory = 'Meals'
    else if (cat === 'beverage' || cat === 'drink') actualCategory = 'Beverages'
    else if (cat === 'appetizer') actualCategory = 'Appetizers'
    else if (cat === 'bakery') actualCategory = 'Bakery'
  }
  
  // Adjust max_price based on budget if set
  let adjustedMaxPrice = max_price
  if (session?.budget_limit && !max_price) {
    const remaining = session.budget_limit - (session.current_spending || 0)
    adjustedMaxPrice = remaining > 0 ? remaining : session.budget_limit
  }
  
  console.log(`🔍 Searching: query="${query}", category="${actualCategory}", max=${adjustedMaxPrice}`)
  
  const { data: meals, error } = await supabase.rpc('ai_search_meals', {
    p_query: query || null,
    p_category: actualCategory || null,
    p_max_price: adjustedMaxPrice || null,
    p_min_price: min_price || null,
    p_restaurant_id: null,
    p_limit: limit
  })
  
  if (error) {
    console.error('❌ Search error:', error)
    return { error: error.message, meals: [] }
  }
  
  console.log(`✅ Found ${meals?.length || 0} meals`)
  
  // Add suggested quantities based on budget
  const mealsWithSuggestions = (meals || []).map((meal: any) => {
    let suggestedQuantity = 1
    let reason = `${meal.title} from ${meal.restaurant_name}`
    
    if (session?.budget_limit) {
      const remaining = session.budget_limit - (session.current_spending || 0)
      const maxQuantity = Math.floor(remaining / meal.effective_price)
      suggestedQuantity = Math.max(1, Math.min(maxQuantity, 3)) // 1-3 items
      
      if (meal.effective_price < meal.original_price) {
        const discount = Math.round(((meal.original_price - meal.effective_price) / meal.original_price) * 100)
        reason += ` (${discount}% off)`
      }
    }
    
    return {
      ...meal,
      suggested_quantity: suggestedQuantity,
      reason: reason
    }
  })
  
  return {
    meals: mealsWithSuggestions,
    count: mealsWithSuggestions.length,
    search_params: { query, category: actualCategory, max_price: adjustedMaxPrice, min_price }
  }
}

async function getUserOrders(args: any, supabase: any, userId: string) {
  const { limit = 5 } = args
  
  const { data: orders, error } = await supabase
    .from('orders')
    .select(`
      id,
      order_number,
      total_amount,
      status,
      delivery_type,
      created_at,
      restaurant:restaurants!orders_restaurant_id_fkey(restaurant_name)
    `)
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit)
  
  if (error) {
    console.error('Error fetching orders:', error)
    return { error: error.message }
  }
  
  return {
    orders: orders,
    count: orders.length
  }
}

async function getCartContents(supabase: any, userId: string) {
  const { data: cartItems, error } = await supabase
    .from('cart_items')
    .select(`
      id,
      quantity,
      meal:meals(
        id,
        title,
        discounted_price,
        image_url,
        restaurant:restaurants!meals_restaurant_id_fkey(restaurant_name)
      )
    `)
    .eq('user_id', userId)
  
  if (error) {
    console.error('Error fetching cart:', error)
    return { error: error.message }
  }
  
  const total = cartItems.reduce((sum: number, item: any) => {
    return sum + (item.quantity * item.meal.discounted_price)
  }, 0)
  
  return {
    items: cartItems,
    count: cartItems.length,
    total: total
  }
}
