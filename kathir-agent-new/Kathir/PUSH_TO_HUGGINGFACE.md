# 🚀 Push to Hugging Face Space

## ✅ Code is Ready and Committed!

Your code has been committed to the local git repository. Now you need to push it to Hugging Face.

## 🔑 Authentication Required

Hugging Face requires a User Access Token for git operations.

### Option 1: Using Hugging Face CLI (Recommended)

1. **Install Hugging Face CLI**
   ```bash
   pip install huggingface_hub
   ```

2. **Login**
   ```bash
   huggingface-cli login
   ```
   - Enter your Hugging Face token when prompted
   - Get token from: https://huggingface.co/settings/tokens

3. **Push the code**
   ```bash
   cd boss-restaurant-chat
   git push
   ```

### Option 2: Using Git with Token

1. **Get your Hugging Face token**
   - Go to: https://huggingface.co/settings/tokens
   - Create a new token with "write" access
   - Copy the token (starts with `hf_...`)

2. **Configure git credential**
   ```bash
   cd boss-restaurant-chat
   git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@huggingface.co/spaces/omark3405/boss-restaurant-chat
   ```
   Replace:
   - `YOUR_USERNAME` with your Hugging Face username
   - `YOUR_TOKEN` with your token

3. **Push**
   ```bash
   git push
   ```

### Option 3: Manual Upload via Web Interface

If git push doesn't work, you can upload files manually:

1. Go to: https://huggingface.co/spaces/omark3405/boss-restaurant-chat
2. Click "Files" tab
3. Click "Add file" → "Upload files"
4. Upload all files from `boss-restaurant-chat/` folder:
   - `.dockerignore`
   - `.gitignore`
   - `Dockerfile`
   - `app.py`
   - `main.py`
   - `requirements.txt`
   - `README.md`
   - `src/` folder (entire folder)

## 📋 After Pushing

### 1. Set Environment Variables

Go to your Space settings and add these secrets:

```
OPENROUTER_API_KEY=your_openrouter_key
HF_TOKEN=your_huggingface_token
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
```

**Steps:**
1. Go to: https://huggingface.co/spaces/omark3405/boss-restaurant-chat/settings
2. Scroll to "Repository secrets"
3. Click "New secret" for each variable
4. Enter name and value
5. Click "Add"

### 2. Wait for Build

1. Go to: https://huggingface.co/spaces/omark3405/boss-restaurant-chat
2. Click "Logs" tab
3. Watch the build progress
4. Wait for "Running on http://0.0.0.0:7860" message
5. Status will change to "Running" ✅

Build typically takes 5-10 minutes.

### 3. Test Your API

Once running, test these endpoints:

```bash
# Health check
curl https://omark3405-boss-restaurant-chat.hf.space/health

# API root
curl https://omark3405-boss-restaurant-chat.hf.space/

# API docs (open in browser)
https://omark3405-boss-restaurant-chat.hf.space/docs

# Chat with agent
curl -X POST https://omark3405-boss-restaurant-chat.hf.space/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show me chicken dishes under 80 EGP"}'
```

## 🎉 Success!

Your Boss AI API will be live at:
- **API**: https://omark3405-boss-restaurant-chat.hf.space
- **Docs**: https://omark3405-boss-restaurant-chat.hf.space/docs
- **Health**: https://omark3405-boss-restaurant-chat.hf.space/health

## 🆘 Troubleshooting

### Authentication Failed
- Make sure you're using a valid Hugging Face token
- Token must have "write" access
- Try `huggingface-cli login` first

### Build Failed
- Check the Logs tab for errors
- Verify all environment variables are set
- Check Dockerfile syntax

### Container Crashes
- Verify all 4 secrets are set correctly
- Check Supabase credentials
- View logs for error messages

## 📚 Quick Commands

```bash
# If you need to make changes later:
cd boss-restaurant-chat
# Make your changes
git add .
git commit -m "Your commit message"
git push

# The Space will automatically rebuild
```

---

**Current Status**: Code committed locally, ready to push! ✅
