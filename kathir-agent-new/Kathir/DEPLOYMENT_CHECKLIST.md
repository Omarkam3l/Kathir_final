# 🚀 Deployment Checklist for Hugging Face Spaces

## ✅ Pre-Deployment Verification

### 1. Files Ready
- [x] `Dockerfile` - Container configuration
- [x] `requirements.txt` - Python dependencies
- [x] `main.py` - FastAPI application
- [x] `app.py` - Hugging Face entry point
- [x] `src/` - All source code
- [x] `static/` - UI files (index.html, app.js, style.css)
- [x] `.dockerignore` - Excludes unnecessary files
- [x] `docker-compose.yml` - Local testing (optional)

### 2. Code Features Implemented
- [x] JSON response format from agent
- [x] Full meal data with image_url
- [x] Restaurant ID hidden (only name exposed)
- [x] Dynamic authentication (sb.auth.get_user())
- [x] Proper project structure (src/ organization)
- [x] Health check endpoint (/health)
- [x] Static files served correctly
- [x] CORS enabled for all origins

### 3. Environment Variables Required
```env
OPENROUTER_API_KEY=sk-or-v1-...
HF_TOKEN=hf_...
SUPABASE_URL=https://....supabase.co
SUPABASE_KEY=eyJhbGci...
```

## 📦 Deployment Steps

### Option 1: Hugging Face Web Interface (Easiest)

1. **Create New Space**
   - Go to https://huggingface.co/new-space
   - Choose "Docker" as SDK
   - Name: `boss-ai-api` (or your preferred name)
   - Visibility: Public or Private

2. **Upload Files**
   Upload these files to your space:
   ```
   Dockerfile
   requirements.txt
   main.py
   app.py
   src/
   static/
   .dockerignore
   ```

3. **Configure Secrets**
   - Go to Space Settings → Repository secrets
   - Add each environment variable:
     - `OPENROUTER_API_KEY`
     - `HF_TOKEN`
     - `SUPABASE_URL`
     - `SUPABASE_KEY`

4. **Wait for Build**
   - Hugging Face will automatically build your Docker container
   - Check the "Logs" tab for build progress
   - Build typically takes 5-10 minutes

5. **Test Deployment**
   ```bash
   curl https://YOUR_USERNAME-boss-ai-api.hf.space/health
   ```

### Option 2: Git Push (For Developers)

1. **Install Hugging Face CLI**
   ```bash
   pip install huggingface_hub
   huggingface-cli login
   ```

2. **Create Space**
   ```bash
   huggingface-cli repo create boss-ai-api --type space --space_sdk docker
   ```

3. **Clone and Push**
   ```bash
   git clone https://huggingface.co/spaces/YOUR_USERNAME/boss-ai-api
   cd boss-ai-api
   
   # Copy your files
   cp -r /path/to/project/* .
   
   # Commit and push
   git add .
   git commit -m "Initial deployment"
   git push
   ```

4. **Configure Secrets** (same as Option 1, step 3)

### Option 3: Local Docker Test (Before Deployment)

**Note:** Docker is not currently installed on your system. To test locally:

1. **Install Docker**
   - Download from https://www.docker.com/products/docker-desktop
   - Install and restart your computer

2. **Build Image**
   ```bash
   docker build -t boss-ai-api .
   ```

3. **Run Container**
   ```bash
   docker run -p 7860:7860 --env-file .env boss-ai-api
   ```

4. **Test Locally**
   ```bash
   curl http://localhost:7860/health
   ```

## 🧪 Post-Deployment Testing

### 1. Health Check
```bash
curl https://YOUR_USERNAME-boss-ai-api.hf.space/health
```
Expected: `{"status":"ok","timestamp":"..."}`

### 2. API Documentation
Visit: `https://YOUR_USERNAME-boss-ai-api.hf.space/docs`

### 3. Chat UI
Visit: `https://YOUR_USERNAME-boss-ai-api.hf.space/`

### 4. Test Agent Chat
```bash
curl -X POST https://YOUR_USERNAME-boss-ai-api.hf.space/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show me chicken dishes"}'
```

### 5. Test Meal Search
```bash
curl https://YOUR_USERNAME-boss-ai-api.hf.space/meals/search?query=chicken&limit=5
```

## 🔍 Troubleshooting

### Build Fails
- Check Dockerfile syntax
- Verify all files are uploaded
- Check requirements.txt for version conflicts
- View build logs in Space settings

### Container Crashes
- Check environment variables are set correctly
- View runtime logs in Space logs tab
- Verify Supabase credentials are valid
- Check database connectivity

### API Returns Errors
- Verify all environment variables are set
- Check Supabase URL and key
- Test database connection with /ready endpoint
- Check OpenRouter API key is valid

### UI Not Loading
- Verify static files are uploaded
- Check browser console for errors
- Ensure CORS is enabled
- Check API_BASE_URL in app.js

## 📊 Monitoring

### Check Logs
- Go to your Space page
- Click "Logs" tab
- Monitor for errors or warnings

### Check Status
```bash
# Health check
curl https://YOUR_USERNAME-boss-ai-api.hf.space/health

# Readiness check (includes DB connectivity)
curl https://YOUR_USERNAME-boss-ai-api.hf.space/ready

# Agent info
curl https://YOUR_USERNAME-boss-ai-api.hf.space/agent/info
```

## 🎯 Success Criteria

- [ ] Health endpoint returns 200 OK
- [ ] API documentation loads at /docs
- [ ] Chat UI loads and displays welcome message
- [ ] Can send messages to agent
- [ ] Agent returns structured JSON responses
- [ ] Meal search works with images
- [ ] Cart operations work
- [ ] No errors in logs

## 📝 Important Notes

### Security
- ✅ Restaurant IDs are hidden (only names exposed)
- ✅ Environment variables stored as secrets
- ✅ .env file excluded from Docker image
- ✅ Authentication uses dynamic user IDs

### Performance
- Port 7860 (Hugging Face default)
- Uvicorn ASGI server
- Health checks every 30 seconds
- Auto-restart on failure

### Features
- ✅ Semantic meal search with embeddings
- ✅ Full meal data including images
- ✅ Restaurant filtering by name
- ✅ Price and allergen filters
- ✅ Cart management
- ✅ Budget-based cart building
- ✅ Favorites search
- ✅ Structured JSON responses

## 🚀 Ready to Deploy!

Your API is fully configured and ready for Hugging Face Spaces deployment.

**Recommended:** Use Option 1 (Web Interface) for the easiest deployment experience.

**Next Steps:**
1. Go to https://huggingface.co/new-space
2. Create a Docker space
3. Upload files
4. Configure secrets
5. Wait for build
6. Test your deployment!

Good luck! 🎉
