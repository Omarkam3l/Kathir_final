# 🚀 Quick Deploy to Hugging Face Spaces (API Only)

## ✅ Status: READY FOR DEPLOYMENT

All files verified and ready! Follow these 5 simple steps:

---

## Step 1: Create Space (2 minutes)

1. Go to: **https://huggingface.co/new-space**
2. Fill in:
   - **Name**: `boss-ai-api` (or your choice)
   - **SDK**: Select **Docker** ⚠️ IMPORTANT
   - **Visibility**: Public or Private
3. Click **Create Space**

---

## Step 2: Upload Files (5 minutes)

Click "Files" → "Add file" → "Upload files"

Upload these files/folders:

### Root Files (5 files)
```
✓ Dockerfile
✓ requirements.txt
✓ main.py
✓ app.py
✓ .dockerignore
```

### Folders (1 folder with all contents)
```
✓ src/          (upload entire folder)
```

**Tip**: You can drag and drop folders directly!

---

## Step 3: Set Secrets (2 minutes)

1. Click **Settings** tab
2. Scroll to **Repository secrets**
3. Click **New secret** for each:

```
Name: OPENROUTER_API_KEY
Value: [your OpenRouter API key]

Name: HF_TOKEN
Value: [your HuggingFace token]

Name: SUPABASE_URL
Value: [your Supabase URL]

Name: SUPABASE_KEY
Value: [your Supabase key]
```

---

## Step 4: Wait for Build (5-10 minutes)

1. Go to **Logs** tab
2. Watch the build progress
3. Wait for "Running on http://0.0.0.0:7860"
4. Status will change to "Running" ✅

---

## Step 5: Test Deployment (1 minute)

### Open Your Space
```
https://YOUR_USERNAME-boss-ai-api.hf.space
```

### Test Health Check
```bash
curl https://YOUR_USERNAME-boss-ai-api.hf.space/health
```

Expected response:
```json
{"status":"ok","timestamp":"..."}
```

### Test API Root
```bash
curl https://YOUR_USERNAME-boss-ai-api.hf.space/
```

Expected response:
```json
{
  "message": "Boss Food Ordering API",
  "version": "1.0.0",
  "docs": "/docs",
  "endpoints": {...}
}
```

### Test API Docs
```
https://YOUR_USERNAME-boss-ai-api.hf.space/docs
```

---

## 🎉 Done!

Your Boss AI API is now live on Hugging Face Spaces!

### Share Your API
- **API Root**: `https://YOUR_USERNAME-boss-ai-api.hf.space/`
- **API Docs**: `https://YOUR_USERNAME-boss-ai-api.hf.space/docs`
- **Health**: `https://YOUR_USERNAME-boss-ai-api.hf.space/health`

### Example API Calls

#### Chat with Agent
```bash
curl -X POST https://YOUR_USERNAME-boss-ai-api.hf.space/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show me chicken dishes under 80 EGP"}'
```

#### Search Meals
```bash
curl "https://YOUR_USERNAME-boss-ai-api.hf.space/meals/search?query=chicken&limit=5"
```

#### Get Cart
```bash
curl https://YOUR_USERNAME-boss-ai-api.hf.space/cart/
```

---

## 🆘 Troubleshooting

### Build Failed?
- Check Dockerfile is uploaded
- Verify requirements.txt is present
- Check logs for specific error

### Container Crashes?
- Verify all 4 secrets are set correctly
- Check Supabase URL and key are valid
- View logs for error messages

### API Not Responding?
- Wait 1-2 minutes after "Running" status
- Check health endpoint first
- Verify port 7860 is configured

---

## 📚 More Help

- **Full Guide**: See `DEPLOYMENT_READY.md`
- **Checklist**: See `DEPLOYMENT_CHECKLIST.md`
- **File List**: See `HUGGINGFACE_UPLOAD_LIST.txt`
- **Verify Files**: Run `python verify_deployment_files.py`

---

**Total Time**: ~15 minutes from start to finish! 🚀
