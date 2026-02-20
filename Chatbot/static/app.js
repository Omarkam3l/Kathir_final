// Configuration
const API_BASE_URL = 'http://localhost:8000';
const USE_AGENT = true; // Set to true to use AI agent, false for direct API calls
let messageCount = 0;
let sessionId = null; // Track conversation session

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    checkServerStatus();
    setupEventListeners();
    updateCartStats();
});

// Setup event listeners
function setupEventListeners() {
    const input = document.getElementById('messageInput');
    const sendButton = document.getElementById('sendButton');
    
    // Auto-resize textarea
    input.addEventListener('input', () => {
        input.style.height = 'auto';
        input.style.height = input.scrollHeight + 'px';
    });
    
    // Send on Enter (Shift+Enter for new line)
    input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });
}

// Check server status
async function checkServerStatus() {
    const statusDot = document.getElementById('statusDot');
    const statusText = document.getElementById('statusText');
    
    try {
        const response = await fetch(`${API_BASE_URL}/health`);
        if (response.ok) {
            statusDot.classList.add('online');
            statusText.textContent = 'Connected';
        } else {
            statusDot.classList.add('offline');
            statusText.textContent = 'Server Error';
        }
    } catch (error) {
        statusDot.classList.add('offline');
        statusText.textContent = 'Offline';
    }
}

// Send message
async function sendMessage() {
    const input = document.getElementById('messageInput');
    const message = input.value.trim();
    
    if (!message) return;
    
    // Add user message
    addMessage(message, 'user');
    input.value = '';
    input.style.height = 'auto';
    
    // Show loading
    const loadingId = addLoadingMessage();
    
    // Process message
    await processMessage(message, loadingId);
    
    // Update stats
    messageCount++;
    document.getElementById('messageCount').textContent = messageCount;
}

// Quick message
function sendQuickMessage(message) {
    document.getElementById('messageInput').value = message;
    sendMessage();
}

// Add message to chat
function addMessage(text, sender) {
    const chatMessages = document.getElementById('chatMessages');
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${sender}-message`;
    
    const avatar = sender === 'user' ? '👤' : '🤖';
    
    messageDiv.innerHTML = `
        <div class="message-avatar">${avatar}</div>
        <div class="message-content">
            <div class="message-text">
                <p>${escapeHtml(text)}</p>
            </div>
        </div>
    `;
    
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    
    return messageDiv;
}

// Add loading message
function addLoadingMessage() {
    const chatMessages = document.getElementById('chatMessages');
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message bot-message';
    messageDiv.id = 'loading-message';
    
    messageDiv.innerHTML = `
        <div class="message-avatar">🤖</div>
        <div class="message-content">
            <div class="message-text">
                <div class="loading">
                    <div class="loading-dot"></div>
                    <div class="loading-dot"></div>
                    <div class="loading-dot"></div>
                </div>
            </div>
        </div>
    `;
    
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    
    return 'loading-message';
}

// Remove loading message
function removeLoadingMessage(id) {
    const loadingMsg = document.getElementById(id);
    if (loadingMsg) {
        loadingMsg.remove();
    }
}

// Process message and call API
async function processMessage(message, loadingId) {
    const lowerMessage = message.toLowerCase();
    
    try {
        // Use AI agent if enabled
        if (USE_AGENT) {
            await handleAgentChat(message, loadingId);
            return;
        }
        
        // Otherwise use direct API calls (original behavior)
        // Determine intent and call appropriate API
        if (lowerMessage.includes('cart') && (lowerMessage.includes('show') || lowerMessage.includes('view') || lowerMessage.includes('my'))) {
            await handleGetCart(loadingId);
        } else if (lowerMessage.includes('build') && lowerMessage.includes('cart')) {
            await handleBuildCart(message, loadingId);
        } else if (lowerMessage.includes('favorite')) {
            await handleFavorites(message, loadingId);
        } else if (lowerMessage.includes('add to cart')) {
            await handleAddToCart(message, loadingId);
        } else {
            // Default to meal search
            await handleMealSearch(message, loadingId);
        }
    } catch (error) {
        removeLoadingMessage(loadingId);
        addBotMessage(`Sorry, I encountered an error: ${error.message}`);
    }
}

// Handle agent chat (AI-powered)
async function handleAgentChat(message, loadingId) {
    try {
        const response = await fetch(`${API_BASE_URL}/agent/chat`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                message: message,
                session_id: sessionId,
                user_id: '11111111-1111-1111-1111-111111111111'
            })
        });
        
        const data = await response.json();
        
        removeLoadingMessage(loadingId);
        
        if (data.ok) {
            // Store session ID for conversation continuity
            sessionId = data.session_id;
            
            // Parse JSON response from agent
            try {
                const agentResponse = JSON.parse(data.response);
                
                // Display based on action type
                if (agentResponse.action === 'search' && agentResponse.data && agentResponse.data.meals) {
                    // Display meal results
                    displayMealResults({
                        ok: true,
                        count: agentResponse.data.count || agentResponse.data.meals.length,
                        results: agentResponse.data.meals
                    });
                    // Also show the message
                    if (agentResponse.message) {
                        addBotMessage(agentResponse.message);
                    }
                } else if (agentResponse.action === 'cart' && agentResponse.data) {
                    // Display cart
                    displayCart({
                        ok: true,
                        count: agentResponse.data.count || agentResponse.data.items.length,
                        total: agentResponse.data.total,
                        items: agentResponse.data.items || []
                    });
                } else if (agentResponse.action === 'build' && agentResponse.data) {
                    // Display build cart result
                    displayBuildCartResult({
                        ok: true,
                        total: agentResponse.data.total,
                        remaining_budget: agentResponse.data.remaining_budget,
                        items: agentResponse.data.items || []
                    }, agentResponse.data.total + agentResponse.data.remaining_budget);
                } else {
                    // Default: just show the message
                    addBotMessage(agentResponse.message || data.response);
                }
            } catch (e) {
                // If not valid JSON, display as text
                addBotMessage(data.response);
            }
            
            // Update cart stats after agent response
            updateCartStats();
        } else {
            addBotMessage(`Error: ${data.error || 'Unknown error'}`);
        }
    } catch (error) {
        removeLoadingMessage(loadingId);
        addBotMessage(`Error communicating with agent: ${error.message}`);
    }
}

// Handle meal search
async function handleMealSearch(message, loadingId) {
    const params = parseSearchParams(message);
    
    try {
        const response = await fetch(`${API_BASE_URL}/meals/search?${new URLSearchParams(params)}`);
        const data = await response.json();
        
        removeLoadingMessage(loadingId);
        
        if (data.ok && data.count > 0) {
            displayMealResults(data);
        } else {
            addBotMessage(`I couldn't find any meals matching your criteria. Try adjusting your search!`);
        }
    } catch (error) {
        removeLoadingMessage(loadingId);
        addBotMessage(`Error searching for meals: ${error.message}`);
    }
}

// Parse search parameters from message
function parseSearchParams(message) {
    const params = {
        query: message,
        limit: 10
    };
    
    // Extract price
    const priceMatch = message.match(/under (\d+)|below (\d+)|max (\d+)/i);
    if (priceMatch) {
        params.max_price = priceMatch[1] || priceMatch[2] || priceMatch[3];
    }
    
    const minPriceMatch = message.match(/above (\d+)|over (\d+)|min (\d+)/i);
    if (minPriceMatch) {
        params.min_price = minPriceMatch[1] || minPriceMatch[2] || minPriceMatch[3];
    }
    
    // Extract category
    const categories = ['meals', 'desserts', 'meat', 'poultry', 'seafood', 'bakery', 'vegetables'];
    for (const cat of categories) {
        if (message.toLowerCase().includes(cat)) {
            if (cat === 'meat' || cat === 'poultry') {
                params.category = 'Meat & Poultry';
            } else {
                params.category = cat.charAt(0).toUpperCase() + cat.slice(1);
            }
            break;
        }
    }
    
    // Extract allergens
    const allergens = ['gluten', 'dairy', 'eggs', 'shellfish', 'fish', 'tree nuts', 'peanuts', 'soy', 'sesame'];
    const excludeAllergens = [];
    for (const allergen of allergens) {
        if (message.toLowerCase().includes(allergen) && 
            (message.toLowerCase().includes('free') || 
             message.toLowerCase().includes('without') || 
             message.toLowerCase().includes('no '))) {
            excludeAllergens.push(allergen);
        }
    }
    if (excludeAllergens.length > 0) {
        params.exclude_allergens = excludeAllergens;
    }
    
    return params;
}

// Display meal results
function displayMealResults(data) {
    const chatMessages = document.getElementById('chatMessages');
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message bot-message';
    
    let mealsHtml = '';
    data.results.forEach(meal => {
        const allergensHtml = meal.allergens && meal.allergens.length > 0
            ? `<div class="meal-allergens">
                ${meal.allergens.map(a => `<span class="allergen-badge">⚠️ ${a}</span>`).join('')}
               </div>`
            : '';
        
        const scoreHtml = meal.score 
            ? `<div class="meal-score">Relevance: ${(meal.score * 100).toFixed(0)}%</div>`
            : '';
        
        mealsHtml += `
            <div class="meal-card">
                <div class="meal-header">
                    <div class="meal-title">${escapeHtml(meal.title)}</div>
                    <div class="meal-price">${meal.price} EGP</div>
                </div>
                <div class="meal-category">${meal.category}</div>
                <div class="meal-description">${escapeHtml(meal.description || '')}</div>
                ${allergensHtml}
                ${scoreHtml}
            </div>
        `;
    });
    
    messageDiv.innerHTML = `
        <div class="message-avatar">🤖</div>
        <div class="message-content">
            <div class="message-text">
                <p><strong>Found ${data.count} meal${data.count !== 1 ? 's' : ''}:</strong></p>
                ${mealsHtml}
            </div>
        </div>
    `;
    
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Handle get cart
async function handleGetCart(loadingId) {
    try {
        const response = await fetch(`${API_BASE_URL}/cart/`);
        const data = await response.json();
        
        removeLoadingMessage(loadingId);
        
        if (data.ok) {
            displayCart(data);
            updateCartStats();
        } else {
            addBotMessage(`Error getting cart: ${data.error || 'Unknown error'}`);
        }
    } catch (error) {
        removeLoadingMessage(loadingId);
        addBotMessage(`Error fetching cart: ${error.message}`);
    }
}

// Display cart
function displayCart(data) {
    const chatMessages = document.getElementById('chatMessages');
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message bot-message';
    
    if (data.count === 0) {
        messageDiv.innerHTML = `
            <div class="message-avatar">🤖</div>
            <div class="message-content">
                <div class="message-text">
                    <p>Your cart is empty! 🛒</p>
                    <p>Try searching for meals and I can help you build a cart.</p>
                </div>
            </div>
        `;
    } else {
        let itemsHtml = '';
        data.items.forEach(item => {
            itemsHtml += `
                <div class="cart-item">
                    <strong>${escapeHtml(item.title)}</strong><br>
                    ${item.quantity}x @ ${item.unit_price} EGP = ${item.subtotal} EGP<br>
                    <small>Stock: ${item.available_stock} | ${escapeHtml(item.restaurant_name || 'N/A')}</small>
                </div>
            `;
        });
        
        messageDiv.innerHTML = `
            <div class="message-avatar">🤖</div>
            <div class="message-content">
                <div class="cart-summary">
                    <h4>🛒 Your Cart</h4>
                    ${itemsHtml}
                    <div class="cart-total">
                        Total: ${data.total} EGP (${data.total_quantity} portions)
                    </div>
                </div>
            </div>
        `;
    }
    
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Handle build cart
async function handleBuildCart(message, loadingId) {
    // Extract budget
    const budgetMatch = message.match(/(\d+)\s*(?:egp|pounds?)?/i);
    if (!budgetMatch) {
        removeLoadingMessage(loadingId);
        addBotMessage(`Please specify a budget amount. For example: "Build a cart with 500 EGP budget"`);
        return;
    }
    
    const budget = parseInt(budgetMatch[1]);
    
    // Get a restaurant ID first
    try {
        const searchResponse = await fetch(`${API_BASE_URL}/meals/search?limit=1`);
        const searchData = await searchResponse.json();
        
        if (!searchData.results || searchData.results.length === 0) {
            removeLoadingMessage(loadingId);
            addBotMessage(`No restaurants available at the moment.`);
            return;
        }
        
        const restaurantId = searchData.results[0].restaurant_id;
        
        const response = await fetch(`${API_BASE_URL}/cart/build`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                budget: budget,
                restaurant_id: restaurantId,
                target_meal_count: 5,
                max_qty_per_meal: 3
            })
        });
        
        const data = await response.json();
        
        removeLoadingMessage(loadingId);
        
        if (data.ok) {
            displayBuildCartResult(data, budget);
            updateCartStats();
        } else {
            addBotMessage(`Error building cart: ${data.error || 'Unknown error'}`);
        }
    } catch (error) {
        removeLoadingMessage(loadingId);
        addBotMessage(`Error building cart: ${error.message}`);
    }
}

// Display build cart result
function displayBuildCartResult(data, budget) {
    const chatMessages = document.getElementById('chatMessages');
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message bot-message';
    
    let itemsHtml = '';
    if (data.items && data.items.length > 0) {
        data.items.forEach(item => {
            itemsHtml += `
                <div class="cart-item">
                    <strong>${escapeHtml(item.title)}</strong><br>
                    ${item.quantity}x @ ${item.unit_price} EGP = ${item.subtotal} EGP
                </div>
            `;
        });
    }
    
    messageDiv.innerHTML = `
        <div class="message-avatar">🤖</div>
        <div class="message-content">
            <div class="cart-summary">
                <h4>✨ Cart Built Successfully!</h4>
                <p>Budget: ${budget} EGP</p>
                ${itemsHtml}
                <div class="cart-total">
                    Total: ${data.total} EGP<br>
                    Remaining: ${data.remaining_budget} EGP
                </div>
            </div>
        </div>
    `;
    
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Handle favorites
async function handleFavorites(message, loadingId) {
    const userId = '11111111-1111-1111-1111-111111111111'; // Default test user
    
    try {
        const response = await fetch(`${API_BASE_URL}/favorites/search?user_id=${userId}&limit=10`);
        const data = await response.json();
        
        removeLoadingMessage(loadingId);
        
        if (data.ok && data.count > 0) {
            displayMealResults(data);
        } else {
            addBotMessage(`You don't have any favorite meals yet!`);
        }
    } catch (error) {
        removeLoadingMessage(loadingId);
        addBotMessage(`Error fetching favorites: ${error.message}`);
    }
}

// Add bot message
function addBotMessage(text) {
    const chatMessages = document.getElementById('chatMessages');
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message bot-message';
    
    messageDiv.innerHTML = `
        <div class="message-avatar">🤖</div>
        <div class="message-content">
            <div class="message-text">
                <p>${escapeHtml(text)}</p>
            </div>
        </div>
    `;
    
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Update cart stats
async function updateCartStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/cart/`);
        const data = await response.json();
        
        if (data.ok) {
            document.getElementById('cartCount').textContent = data.count;
            document.getElementById('cartTotal').textContent = `${data.total} EGP`;
        }
    } catch (error) {
        console.error('Error updating cart stats:', error);
    }
}

// Utility: Escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
