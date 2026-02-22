# Boss AI API - Docker Deployment Guide

## 🐳 Docker Deployment

### Prerequisites
- Docker installed
- Docker Compose installed (optional)
- Environment variables configured

### Quick Start

#### 1. Build the Docker Image
```bash
docker build -t boss-ai-api .
```

#### 2. Run the Container
```bash
docker run -p 7860:7860 \
  -e OPENROUTER_API_KEY=your_key \
  -e HF_TOKEN=your_token \
  -e SUPABASE_URL=your_url \
  -e SUPABASE_KEY=your_key \
  boss-ai-api
```

#### 3. Using Docker Compose
```bash
# Create .env file with your credentials
cp .env.example .env

# Start the service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```

### Access the API
- **API**: http://localhost:7860
- **Docs**: http://localhost:7860/docs
- **Health**: http://localhost:7860/health

## 🤗 Hugging Face Spaces Deployment

### Method 1: Using Hugging Face CLI

#### 1. Install Hugging Face CLI
```bash
pip install huggingface_hub
```

#### 2. Login to Hugging Face
```bash
huggingface-cli login
```

#### 3. Create a New Space
```bash
# Create a new Docker space
huggingface-cli repo create boss-ai-api --type space --space_sdk docker
```

#### 4. Clone the Space Repository
```bash
git clone https://huggingface.co/spaces/YOUR_USERNAME/boss-ai-api
cd boss-ai-api
```

#### 5. Copy Your Code
```bash
# Copy all necessary files
cp -r /path/to/your/project/* .
```

#### 6. Configure Secrets
Go to your Space settings on Hugging Face and add:
- `OPENROUTER_API_KEY`
- `HF_TOKEN`
- `SUPABASE_URL`
- `SUPABASE_KEY`

#### 7. Push to Hugging Face
```bash
git add .
git commit -m "Initial deployment"
git push
```

### Method 2: Using Web Interface

#### 1. Create New Space
- Go to https://huggingface.co/new-space
- Choose "Docker" as SDK
- Name your space (e.g., "boss-ai-api")

#### 2. Upload Files
Upload these files to your space:
- `Dockerfile`
- `requirements.txt`
- `main.py`
- `app.py`
- `src/` folder
- `static/` folder
- `.dockerignore`

#### 3. Configure Secrets
In Space settings → Repository secrets, add:
- `OPENROUTER_API_KEY`
- `HF_TOKEN`
- `SUPABASE_URL`
- `SUPABASE_KEY`

#### 4. Wait for Build
Hugging Face will automatically build and deploy your Docker container.

### Method 3: Using Git

#### 1. Initialize Git (if not already)
```bash
git init
git remote add space https://huggingface.co/spaces/YOUR_USERNAME/boss-ai-api
```

#### 2. Commit and Push
```bash
git add Dockerfile requirements.txt main.py app.py src/ static/
git commit -m "Deploy to Hugging Face Spaces"
git push space main
```

## 📋 Required Files for Deployment

### Essential Files
- ✅ `Dockerfile` - Container configuration
- ✅ `requirements.txt` - Python dependencies
- ✅ `main.py` - FastAPI application
- ✅ `app.py` - Hugging Face entry point
- ✅ `src/` - Source code directory
- ✅ `static/` - Static files (UI)
- ✅ `.dockerignore` - Files to exclude

### Optional Files
- `docker-compose.yml` - Local development
- `.env.example` - Environment template
- `README.md` - Documentation

## 🔐 Environment Variables

### Required
```env
OPENROUTER_API_KEY=sk-or-v1-...
HF_TOKEN=hf_...
SUPABASE_URL=https://....supabase.co
SUPABASE_KEY=eyJhbGci...
```

### Optional
```env
PORT=7860  # Default port for Hugging Face
```

## 🧪 Testing the Deployment

### Local Docker Test
```bash
# Build
docker build -t boss-ai-api .

# Run
docker run -p 7860:7860 --env-file .env boss-ai-api

# Test
curl http://localhost:7860/health
```

### Hugging Face Test
```bash
# After deployment, test your space
curl https://YOUR_USERNAME-boss-ai-api.hf.space/health
```

## 📊 Monitoring

### Docker Logs
```bash
# View logs
docker logs -f <container_id>

# With docker-compose
docker-compose logs -f
```

### Hugging Face Logs
- View logs in the Space's "Logs" tab
- Monitor build status in "Settings" → "Repository"

## 🔧 Troubleshooting

### Build Fails
1. Check Dockerfile syntax
2. Verify all files are present
3. Check requirements.txt for conflicts

### Container Crashes
1. Check environment variables
2. View logs: `docker logs <container_id>`
3. Verify database connectivity

### Port Issues
```bash
# Check if port is in use
lsof -i :7860

# Use different port
docker run -p 8000:7860 boss-ai-api
```

### Memory Issues
```bash
# Increase Docker memory limit
docker run -m 2g boss-ai-api
```

## 🚀 Production Optimization

### 1. Multi-stage Build
```dockerfile
# Build stage
FROM python:3.10-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Runtime stage
FROM python:3.10-slim
COPY --from=builder /root/.local /root/.local
COPY . .
CMD uvicorn main:app --host 0.0.0.0 --port 7860
```

### 2. Reduce Image Size
- Use slim Python images
- Remove unnecessary files
- Use .dockerignore effectively

### 3. Security
- Don't include .env in image
- Use secrets management
- Run as non-root user

### 4. Performance
- Enable caching
- Use gunicorn with workers
- Configure connection pooling

## 📦 Deployment Checklist

### Pre-deployment
- [ ] Test locally with Docker
- [ ] Verify all environment variables
- [ ] Check database connectivity
- [ ] Test all API endpoints
- [ ] Review security settings

### Deployment
- [ ] Build Docker image successfully
- [ ] Push to Hugging Face
- [ ] Configure secrets
- [ ] Wait for build completion
- [ ] Test deployed API

### Post-deployment
- [ ] Monitor logs
- [ ] Test all endpoints
- [ ] Check performance
- [ ] Set up monitoring
- [ ] Document API URL

## 🌐 Access URLs

### Local Development
- API: http://localhost:7860
- Docs: http://localhost:7860/docs
- Health: http://localhost:7860/health

### Hugging Face Spaces
- API: https://YOUR_USERNAME-boss-ai-api.hf.space
- Docs: https://YOUR_USERNAME-boss-ai-api.hf.space/docs
- Health: https://YOUR_USERNAME-boss-ai-api.hf.space/health

## 📞 Support

### Issues
- Check logs first
- Review environment variables
- Test database connectivity
- Verify API keys

### Resources
- Docker Documentation: https://docs.docker.com
- Hugging Face Spaces: https://huggingface.co/docs/hub/spaces
- FastAPI Documentation: https://fastapi.tiangolo.com

## 🎉 Success!

Your Boss AI API is now deployed and ready to use!

Test it:
```bash
curl https://YOUR_USERNAME-boss-ai-api.hf.space/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-02-22T..."
}
```
