# Kathir Agent - Hugging Face Deployment Guide

## 📋 Overview

**Kathir Agent** is an AI-powered food ordering assistant built with:
- **FastAPI** - Web framework
- **LangChain + LangGraph** - AI agent framework
- **Google Gemini 2.0 Flash** - LLM (via OpenRouter)
- **Supabase** - Database
- **Sentence Transformers** - Semantic search embeddings

---

## 🔍 What I Discovered in Your Kathir Agent

### Project Structure
```
Kathir Agent/Kathir/
├── src/
│   ├── api/                    # FastAPI routes
│   │   ├── routes_agent.py     # AI chat endpoint
│   │   ├── routes_cart.py      # Cart management
│   │   ├── routes_favorites.py # Favorites
│   │   ├── routes_meals.py     # Meal search
│   │   └── routes_health.py    # Health check
│   ├── tools/                  # LangChain tools
│   │   ├── meals.py            # Semantic meal search
│   │   ├── cart.py             # Cart operations
│   │   ├── budget.py           # Budget optimization
│   │   └── favorites.py        # User favorites
│   ├── utils/                  # Utilities
│   │   ├── db_client.py        # Supabase client
│   │   ├── embeddings.py       # Vector embeddings
│   │   ├── auth.py             # Authentication
│   │   └── formatters.py       # Response formatting
│   ├── boss_agent.py           # LangGraph agent
│   └── prompts.py              # System prompts
├── static/                     # Web UI
│   ├── index.html
│   ├── style.css
│   └── app.js
├── main.py                     # FastAPI entry point
├── requirements.txt            # Dependencies
└── .env                        # Environment variables
```

### Key Features
1. **AI Agent Chat** - Natural language food ordering
2. **Semantic Search** - Vector-based meal discovery
3. **Cart Management** - Add/update/view cart
4. **Budget Optimization** - Build carts within budget
5. **Favorites System** - Save and search favorites
6. **Web UI** - Modern chat interface

### Technologies
- **LangGraph ReAct Agent** - Tool-calling AI agent
- **OpenRouter** - LLM API gateway
- **Gemini 2.0 Flash** - Fast, reliable tool-calling
- **Sentence Transformers** - Embeddings for semantic search
- **Supabase** - PostgreSQL with vector search

---

## 🚀 DEPLOYMENT TO HUGGING FACE SPACES

### Step 1: Prepare Your Project

#### 1.1 Create Hugging Face Account
1. Go to https://huggingface.co/
2. Sign up for a free account
3. Verify your email

#### 1.2 Create a New Space
1. Go to https://huggingface.co/spaces
2. Click "Create new Space"
3. Fill in details:
   - **Name**: `kathir-agent` (or your preferred name)
   - **License**: Apache 2.0 (recommended)
   - **SDK**: Select **"Docker"** (for full control)
   - **Hardware**: Start with **CPU basic** (free tier)
   - **Visibility**: Public or Private

#### 1.3 Prepare Files for Deployment

Create these files in your `Kathir Agent/Kathir/` directory:

**File 1: `Dockerfile`**
```dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 7860

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
```

**File 2: `README.md` (for Hugging Face Space)**
```markdown
---
title: Kathir Agent
emoji: 🍽️
colorFrom: green
colorTo: blue
sdk: docker
pinned: false
---

# Kathir Agent - AI Food Ordering Assistant

AI-powered food ordering assistant for Cairo with semantic search, cart management, and budget optimization.

## Features
- 🤖 Natural language food ordering
- 🔍 Semantic meal search
- 🛒 Smart cart management
- 💰 Budget optimization
- ⭐ Favorites system

## Usage
Visit the Space URL to access the chat interface!

## API Endpoints
- `/agent/chat` - Chat with AI agent
- `/meals/search` - Search meals
- `/cart/` - Cart operations
- `/docs` - API documentation
```

**File 3: `.env` (for Hugging Face Secrets)**
You'll add these as Space secrets (see Step 2.3)

---

### Step 2: Deploy to Hugging Face

#### 2.1 Initialize Git Repository (if not already)
```bash
cd "Kathir Agent/Kathir"
git init
git add .
git commit -m "Initial commit - Kathir Agent"
```

#### 2.2 Push to Hugging Face
```bash
# Add Hugging Face remote
git remote add space https://huggingface.co/spaces/YOUR_USERNAME/kathir-agent

# Push to Hugging Face
git push --force space main
```

**Alternative: Upload via Web Interface**
1. Go to your Space page
2. Click "Files" tab
3. Click "Add file" → "Upload files"
4. Upload all files from `Kathir Agent/Kathir/`

#### 2.3 Configure Environment Variables (Secrets)
1. Go to your Space settings
2. Click "Variables and secrets"
3. Add these secrets:

```
OPENROUTER_API_KEY=your_openrouter_key
HF_TOKEN=your_huggingface_token
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

#### 2.4 Wait for Build
- Hugging Face will automatically build your Docker container
- Check the "Logs" tab for build progress
- Build typically takes 5-10 minutes

#### 2.5 Access Your Deployed Agent
Once built, your agent will be available at:
```
https://huggingface.co/spaces/YOUR_USERNAME/kathir-agent
```

---

## 🔑 Getting API Keys

### 1. OpenRouter API Key (for Gemini)
1. Go to https://openrouter.ai/
2. Sign up for free account
3. Go to "Keys" section
4. Create new API key
5. Copy the key (starts with `sk-or-...`)

**Cost**: Gemini 2.0 Flash is very cheap (~$0.075 per 1M tokens)

### 2. Hugging Face Token (for Embeddings)
1. Go to https://huggingface.co/settings/tokens
2. Click "New token"
3. Name: "Kathir Agent"
4. Type: "Read"
5. Copy the token (starts with `hf_...`)

**Cost**: Free for inference API

### 3. Supabase Keys (Already have these)
You already have these from your existing Kathir project:
- `SUPABASE_URL` - Your project URL
- `SUPABASE_KEY` - Anon/public key
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key

---

## 📡 Getting the API Endpoint

Once deployed, your API will be available at:

### Base URL
```
https://YOUR_USERNAME-kathir-agent.hf.space
```

### API Endpoints

#### 1. Chat with Agent
```bash
POST https://YOUR_USERNAME-kathir-agent.hf.space/agent/chat
Content-Type: application/json

{
  "message": "Show me chicken dishes under 80 EGP",
  "user_id": "user-123",
  "thread_id": "optional-thread-id"
}
```

#### 2. Search Meals
```bash
GET https://YOUR_USERNAME-kathir-agent.hf.space/meals/search?query=chicken&max_price=80
```

#### 3. Get Cart
```bash
GET https://YOUR_USERNAME-kathir-agent.hf.space/cart/?user_id=user-123
```

#### 4. API Documentation
```
https://YOUR_USERNAME-kathir-agent.hf.space/docs
```

---

## 🔗 Integration with Flutter App

### Step 1: Add HTTP Package (Already have it)
Your `pubspec.yaml` already has `http: ^1.1.0`

### Step 2: Create Kathir Agent Service

Create `lib/features/kathir_agent/data/services/kathir_agent_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class KathirAgentService {
  // Replace with your Hugging Face Space URL
  static const String baseUrl = 'https://YOUR_USERNAME-kathir-agent.hf.space';
  
  final _supabase = Supabase.instance.client;
  
  /// Chat with Kathir Agent
  Future<Map<String, dynamic>> chat({
    required String message,
    String? threadId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final response = await http.post(
        Uri.parse('$baseUrl/agent/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'user_id': userId,
          'thread_id': threadId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to chat: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kathir Agent error: $e');
      rethrow;
    }
  }
  
  /// Search meals
  Future<List<dynamic>> searchMeals({
    required String query,
    double? maxPrice,
    double? minPrice,
    String? category,
  }) async {
    try {
      final queryParams = {
        'query': query,
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (category != null) 'category': category,
      };
      
      final uri = Uri.parse('$baseUrl/meals/search').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['meals'] ?? [];
      } else {
        throw Exception('Failed to search meals');
      }
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }
  
  /// Get cart
  Future<Map<String, dynamic>> getCart() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final response = await http.get(
        Uri.parse('$baseUrl/cart/?user_id=$userId'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get cart');
      }
    } catch (e) {
      print('❌ Cart error: $e');
      rethrow;
    }
  }
}
```

### Step 3: Add Icon to User Homepage

Update `lib/features/user_home/presentation/widgets/home_header_widget.dart`:

```dart
// Add Kathir Agent icon next to notifications
Row(
  children: [
    // Kathir Agent Icon
    IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.smart_toy,
          color: Colors.white,
          size: 20,
        ),
      ),
      onPressed: () {
        context.push('/kathir-agent');
      },
    ),
    const SizedBox(width: 8),
    // Notifications Icon
    IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {
        context.push('/notifications');
      },
    ),
  ],
)
```

---

## 🎨 UI Integration Steps

### 1. Remove Old Chatbot
```bash
# Delete or rename the old Chatbot folder
# Remove any references in your Flutter app
```

### 2. Create Kathir Agent Feature
```
lib/features/kathir_agent/
├── data/
│   ├── models/
│   │   ├── agent_message.dart
│   │   └── agent_response.dart
│   └── services/
│       └── kathir_agent_service.dart
├── presentation/
│   ├── screens/
│   │   └── kathir_agent_screen.dart
│   ├── widgets/
│   │   ├── agent_message_bubble.dart
│   │   ├── agent_meal_card.dart
│   │   └── agent_input_field.dart
│   └── viewmodels/
│       └── kathir_agent_viewmodel.dart
```

### 3. Add Route
In your router configuration:
```dart
GoRoute(
  path: '/kathir-agent',
  builder: (context, state) => const KathirAgentScreen(),
),
```

---

## 🧪 Testing Your Deployment

### Test 1: Health Check
```bash
curl https://YOUR_USERNAME-kathir-agent.hf.space/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-22T..."
}
```

### Test 2: Chat Endpoint
```bash
curl -X POST https://YOUR_USERNAME-kathir-agent.hf.space/agent/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Show me desserts under 50 EGP",
    "user_id": "test-user"
  }'
```

### Test 3: Meal Search
```bash
curl "https://YOUR_USERNAME-kathir-agent.hf.space/meals/search?query=chicken&max_price=80"
```

---

## 💰 Cost Estimation

### Hugging Face Spaces
- **CPU Basic**: FREE (2 vCPU, 16GB RAM)
- **CPU Upgrade**: $0.03/hour (~$22/month)
- **GPU T4**: $0.60/hour (~$432/month)

**Recommendation**: Start with FREE CPU tier

### OpenRouter (Gemini 2.0 Flash)
- **Input**: $0.075 per 1M tokens
- **Output**: $0.30 per 1M tokens
- **Estimated**: ~$5-10/month for moderate usage

### Hugging Face Inference API
- **FREE** for embeddings (rate-limited)
- **Pro**: $9/month (unlimited)

**Total Estimated Cost**: $0-20/month

---

## 🔧 Troubleshooting

### Issue 1: Build Fails
**Solution**: Check Dockerfile syntax and requirements.txt

### Issue 2: Port Error
**Solution**: Hugging Face Spaces use port 7860 (already configured)

### Issue 3: Environment Variables Not Working
**Solution**: Make sure secrets are added in Space settings, not in code

### Issue 4: Slow Response
**Solution**: Upgrade to CPU Upgrade or GPU hardware

### Issue 5: CORS Errors
**Solution**: CORS is already configured in main.py (`allow_origins=["*"]`)

---

## 📊 Monitoring & Logs

### View Logs
1. Go to your Space page
2. Click "Logs" tab
3. Monitor real-time logs

### Check Usage
1. Go to Space settings
2. View "Usage" tab
3. Monitor API calls and compute time

---

## 🚀 Next Steps

1. ✅ Deploy to Hugging Face Spaces
2. ✅ Get API endpoint URL
3. ✅ Test endpoints with curl/Postman
4. ✅ Integrate with Flutter app
5. ✅ Add Kathir Agent icon to homepage
6. ✅ Create chat UI in Flutter
7. ✅ Test end-to-end flow
8. ✅ Monitor usage and costs

---

## 📝 Summary

**What You Have:**
- Complete AI agent with FastAPI backend
- LangGraph ReAct agent with tool-calling
- Semantic search with embeddings
- Cart and budget optimization
- Web UI included

**What You Need:**
1. Hugging Face account (free)
2. OpenRouter API key (cheap)
3. Deploy to Hugging Face Spaces (free tier available)
4. Integrate API with Flutter app

**Deployment Time**: ~30 minutes
**Cost**: $0-20/month

---

## 🎯 Quick Start Commands

```bash
# 1. Navigate to Kathir Agent folder
cd "Kathir Agent/Kathir"

# 2. Create Dockerfile (copy from above)

# 3. Initialize git
git init
git add .
git commit -m "Initial commit"

# 4. Push to Hugging Face
git remote add space https://huggingface.co/spaces/YOUR_USERNAME/kathir-agent
git push --force space main

# 5. Add secrets in Hugging Face UI

# 6. Wait for build

# 7. Test your API
curl https://YOUR_USERNAME-kathir-agent.hf.space/health
```

---

**Need help with any step? Let me know!** 🚀
