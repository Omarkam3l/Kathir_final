# Boss AI Chat - Quick Start

## 🚀 Start Backend (5 Steps)

### 1. Navigate to Chatbot folder
```bash
cd Chatbot
```

### 2. Activate virtual environment
**Windows:**
```bash
venv\Scripts\activate
```

**macOS/Linux:**
```bash
source venv/bin/activate
```

### 3. Install dependencies (first time only)
```bash
pip install -r requirements.txt
```

### 4. Configure .env file (first time only)
```bash
copy .env.example .env
```

Edit `.env` and add your API keys:
```env
OPENROUTER_API_KEY=sk-or-v1-your-key-here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-key-here
HF_TOKEN=hf_your-token-here
```

### 5. Start server
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

✅ Server running at: http://localhost:8000

## 📱 Run Flutter App

### 1. Update backend URL

**For Android Emulator:**
Edit `lib/features/boss_chat/services/boss_chat_api_service.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8000';
```

**For Physical Device:**
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000';
```

### 2. Run Flutter app
```bash
flutter run
```

### 3. Test Boss AI Chat
1. Tap "Boss AI Chat" button on home screen
2. Check connection status (should be "Connected")
3. Send test message: "Show me chicken dishes"

## ✅ Verify Everything Works

### Test Backend
```bash
curl http://localhost:8000/health
```

Expected: `{"status":"ok","timestamp":"..."}`

### Test Agent
```bash
curl -X POST http://localhost:8000/agent/chat \
  -H "Content-Type: application/json" \
  -d "{\"message\":\"show me chicken dishes\"}"
```

### Test from Flutter
1. Open Boss AI Chat
2. Status should show "Connected" (green dot)
3. Send message
4. Should receive response with meal cards

## 🔧 Common Issues

### Backend won't start
```bash
# Reinstall dependencies
pip install -r requirements.txt --upgrade
```

### Flutter can't connect
- ✅ Backend is running: `curl http://localhost:8000/health`
- ✅ Correct IP in `boss_chat_api_service.dart`
- ✅ Android emulator uses `10.0.2.2` not `localhost`
- ✅ Physical device on same WiFi network

### "User ID required" error
- ✅ User must be logged in
- ✅ Check `AuthProvider` has valid user
- ✅ User ID is automatically passed from logged-in user

## 📚 Full Documentation

- **Backend Setup**: `BACKEND_SETUP_GUIDE.md`
- **Flutter Implementation**: `lib/features/boss_chat/FLUTTER_PORT_DOCUMENTATION.md`
- **API Documentation**: http://localhost:8000/docs (when server running)

## 🎯 Quick Commands

### Start Backend
```bash
cd Chatbot && venv\Scripts\activate && uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Stop Backend
Press `CTRL+C`

### Check Backend Status
```bash
curl http://localhost:8000/health
```

### View API Docs
http://localhost:8000/docs

### Run Flutter
```bash
flutter run
```

---

**Need Help?** See `BACKEND_SETUP_GUIDE.md` for detailed instructions.
