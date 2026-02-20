# Boss AI Chat Backend - Setup Guide

## Prerequisites

### 1. Python Installation
- Python 3.10 or higher
- pip (Python package manager)

Check your Python version:
```bash
python --version
# or
python3 --version
```

### 2. Required Accounts & API Keys

You need the following API keys:

1. **OpenRouter API Key** (for AI agent)
   - Sign up at: https://openrouter.ai/
   - Get API key from: https://openrouter.ai/settings/keys
   - Free tier available with credits

2. **Supabase Account** (for database)
   - Sign up at: https://supabase.com/
   - Create a new project
   - Get URL and Service Role Key from project settings

3. **Hugging Face Token** (for embeddings)
   - Sign up at: https://huggingface.co/
   - Get token from: https://huggingface.co/settings/tokens
   - Free tier available

## Step-by-Step Setup

### Step 1: Navigate to Chatbot Directory

```bash
cd Chatbot
```

### Step 2: Create Virtual Environment (Recommended)

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**macOS/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### Step 3: Install Dependencies

```bash
pip install -r requirements.txt
```

This will install:
- FastAPI (web framework)
- Uvicorn (ASGI server)
- Supabase (database client)
- LangChain & LangGraph (AI framework)
- Sentence Transformers (embeddings)
- And other dependencies

**Note:** First installation may take 5-10 minutes as it downloads ML models.

### Step 4: Configure Environment Variables

1. Copy the example environment file:
```bash
copy .env.example .env
```

2. Edit `.env` file with your API keys:

```env
# OpenRouter API (Required for AI agent)
OPENROUTER_API_KEY=sk-or-v1-your-key-here

# Supabase (Required for database)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Hugging Face (Required for embeddings)
HF_TOKEN=hf_your-token-here

# Optional: Nutrition API (if using nutrition features)
NUTRITIONIX_APP_ID=your-app-id
NUTRITIONIX_APP_KEY=your-app-key
```

**Important:** Never commit the `.env` file to version control!

### Step 5: Setup Database

#### Option A: Use Existing Supabase Database

If you already have the database schema set up, skip to Step 6.

#### Option B: Create Database Schema

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Run the following SQL to create tables:

```sql
-- Create meals table
CREATE TABLE meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  discounted_price NUMERIC NOT NULL,
  original_price NUMERIC,
  quantity_available INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  expiry_date TIMESTAMP WITH TIME ZONE,
  allergens TEXT[],
  ingredients TEXT[],
  restaurant_id UUID,
  embedding VECTOR(1024),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create restaurants table
CREATE TABLE restaurants (
  profile_id UUID PRIMARY KEY,
  restaurant_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create cart_items table
CREATE TABLE cart_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL,
  user_id UUID NOT NULL,
  meal_id UUID REFERENCES meals(id),
  quantity INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create favorites table
CREATE TABLE favorites (
  user_id UUID NOT NULL,
  meal_id UUID REFERENCES meals(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, meal_id)
);

-- Create vector search function
CREATE OR REPLACE FUNCTION match_meals(
  query_embedding VECTOR(1024),
  match_threshold FLOAT,
  match_count INT
)
RETURNS TABLE (
  id UUID,
  similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    meals.id,
    1 - (meals.embedding <=> query_embedding) AS similarity
  FROM meals
  WHERE 1 - (meals.embedding <=> query_embedding) > match_threshold
  ORDER BY meals.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
```

4. Enable pgvector extension:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### Step 6: Generate Embeddings (First Time Only)

If you have meals in your database but no embeddings:

```bash
python -m embeddings
```

This will:
- Load the BAAI/bge-m3 model (first time: ~2GB download)
- Generate embeddings for all meals
- Store embeddings in the database

**Note:** This process takes 30-60 seconds for the first run.

### Step 7: Start the Backend Server

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Flags explained:**
- `--reload`: Auto-restart on code changes (development only)
- `--host 0.0.0.0`: Accept connections from any IP (allows Flutter app to connect)
- `--port 8000`: Run on port 8000

**Expected output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [xxxxx] using StatReload
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Step 8: Verify Server is Running

Open a new terminal and test:

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-02-20T..."
}
```

Or open in browser: http://localhost:8000/docs

You should see the FastAPI interactive documentation.

## Testing the Backend

### Test 1: Health Check

```bash
curl http://localhost:8000/health
```

### Test 2: Agent Chat

```bash
curl -X POST http://localhost:8000/agent/chat \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"show me chicken dishes\"}"
```

### Test 3: Meal Search

```bash
curl "http://localhost:8000/meals/search?query=chicken&limit=5"
```

### Test 4: Get Cart

```bash
curl http://localhost:8000/cart/
```

## Connecting Flutter App

### Update Flutter App Configuration

1. Open `lib/features/boss_chat/services/boss_chat_api_service.dart`

2. Update the base URL:

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8000';
```

**For Physical Device (same network):**
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000';
```

To find your computer's IP:
- Windows: `ipconfig` (look for IPv4 Address)
- macOS/Linux: `ifconfig` or `ip addr`

### Test Connection from Flutter

1. Start backend server
2. Run Flutter app: `flutter run`
3. Navigate to Boss AI Chat
4. Check connection status (should show "Connected")
5. Send a test message

## Troubleshooting

### Issue: "Module not found" errors

**Solution:**
```bash
pip install -r requirements.txt --upgrade
```

### Issue: "Port 8000 already in use"

**Solution:**
```bash
# Find process using port 8000
netstat -ano | findstr :8000

# Kill the process (Windows)
taskkill /PID <process_id> /F

# Or use a different port
uvicorn main:app --reload --port 8001
```

### Issue: "OpenRouter API key not found"

**Solution:**
- Check `.env` file exists in Chatbot directory
- Verify `OPENROUTER_API_KEY` is set correctly
- Restart the server after updating `.env`

### Issue: "Supabase connection failed"

**Solution:**
- Verify `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are correct
- Check your Supabase project is active
- Verify network connection

### Issue: "Embedding model download fails"

**Solution:**
- Check internet connection
- Verify `HF_TOKEN` is set in `.env`
- Try manual download:
```bash
python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('BAAI/bge-m3')"
```

### Issue: Flutter app can't connect

**Solution:**
1. Verify backend is running: `curl http://localhost:8000/health`
2. Check firewall isn't blocking port 8000
3. For physical device, ensure same WiFi network
4. Update `baseUrl` in Flutter app to correct IP
5. For Android, use `10.0.2.2` instead of `localhost`

### Issue: "First search is very slow"

**Solution:**
- This is normal! First search loads the embedding model (~30-60 seconds)
- Subsequent searches are fast (1-2 seconds)
- Model stays loaded in memory

## Production Deployment

### Environment Variables

Set these in your production environment:

```env
OPENROUTER_API_KEY=your-production-key
SUPABASE_URL=your-production-url
SUPABASE_SERVICE_ROLE_KEY=your-production-key
HF_TOKEN=your-token
```

### Run Production Server

```bash
# Install gunicorn
pip install gunicorn

# Run with gunicorn (production)
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

**Flags:**
- `-w 4`: 4 worker processes
- `-k uvicorn.workers.UvicornWorker`: Use Uvicorn worker class
- `--bind 0.0.0.0:8000`: Bind to all interfaces

### Docker Deployment (Optional)

Create `Dockerfile`:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Build and run:
```bash
docker build -t boss-chat-backend .
docker run -p 8000:8000 --env-file .env boss-chat-backend
```

## Monitoring

### View Logs

```bash
# Development (with --reload)
# Logs appear in terminal

# Production (with gunicorn)
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 \
  --access-logfile access.log \
  --error-logfile error.log
```

### Health Monitoring

Set up a cron job or monitoring service to check:
```bash
curl http://your-server:8000/health
```

## API Documentation

Once server is running, visit:
- **Interactive docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## Support

For issues:
1. Check this guide
2. Review `CHATBOT_COMPREHENSIVE_REPORT.md`
3. Check backend logs
4. Verify all environment variables are set

## Quick Reference

### Start Server
```bash
cd Chatbot
venv\Scripts\activate  # Windows
source venv/bin/activate  # macOS/Linux
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Stop Server
Press `CTRL+C` in the terminal

### Restart Server
Stop and start again, or use `--reload` flag for auto-restart

### Check Status
```bash
curl http://localhost:8000/health
```

### View API Docs
http://localhost:8000/docs

---

**Last Updated**: February 20, 2026
**Python Version**: 3.10+
**FastAPI Version**: 0.111.0+
