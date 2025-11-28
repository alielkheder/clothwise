# Backend Deployment Guide

## Quick Solution: ngrok (Recommended for APK Building)

**Why ngrok?**
- ✅ Takes 2 minutes to setup
- ✅ Keeps your local backend (with GPU acceleration!)
- ✅ Free tier is sufficient
- ✅ Perfect for building APK
- ❌ Requires your computer to stay on
- ❌ URL changes when you restart

### Steps:

1. **Download ngrok**
   - Go to https://ngrok.com/download
   - Create free account and download ngrok for Windows

2. **Install and authenticate**
   ```bash
   # Extract ngrok and add your auth token (from ngrok dashboard)
   ngrok config add-authtoken YOUR_TOKEN_HERE
   ```

3. **Start your local backend**
   ```bash
   cd backend
   python api_server.py
   ```

4. **In a new terminal, start ngrok**
   ```bash
   ngrok http 5000
   ```

5. **Copy the public URL**
   - You'll see something like: `https://abc123.ngrok.io`
   - Copy this URL (it's your public backend URL!)

6. **Update Flutter app**
   - Replace all instances of `192.168.1.48:5000` with your ngrok URL (without the `http://` or `https://`)
   - Example: `abc123.ngrok.io`

7. **Build APK**
   - Your Flutter app will now connect to the cloud backend!

---

## Permanent Solution: Render with External Storage

**Why Render?**
- ✅ Always online
- ✅ Professional deployment
- ✅ Free tier available
- ❌ Slower (CPU only, no GPU)
- ❌ Requires uploading large files to cloud storage
- ❌ More complex setup

### Steps:

#### Part 1: Upload Model Files to Cloud Storage

You need to upload these files to Google Drive or Dropbox:
- `best_model.pt` (334 MB)
- `all_product_images.zip` (104 MB)

**Google Drive Method:**
1. Upload both files to Google Drive
2. Right-click each file → Share → Anyone with the link
3. Get direct download links:
   - For Google Drive, use: `https://drive.google.com/uc?export=download&id=FILE_ID`
   - Get FILE_ID from the share link

**Alternative: Use GitHub Releases**
1. Create a GitHub repository
2. Create a Release
3. Attach the two files as release assets
4. Copy the download URLs

#### Part 2: Deploy to Render

1. **Create a GitHub repository**
   ```bash
   cd backend
   git init
   git add .
   git commit -m "Initial backend deployment"
   # Push to GitHub
   ```

2. **Create Render Web Service**
   - Go to https://render.com
   - Sign up / Login
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Select the `backend` folder

3. **Configure Render**
   - Name: `clothwise-backend`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `python download_models.py && gunicorn -w 1 -b 0.0.0.0:$PORT --timeout 300 api_server:app`
   - Plan: Free

4. **Add Environment Variables** (in Render dashboard)
   - Click "Environment" tab
   - Add these variables:
     - `MODEL_URL` = Your best_model.pt direct download link
     - `IMAGES_URL` = Your all_product_images.zip direct download link

5. **Deploy**
   - Click "Create Web Service"
   - Wait ~10-15 minutes for first deployment
   - Your backend URL will be: `https://clothwise-backend.onrender.com`

6. **Update Flutter App**
   - Replace all `192.168.1.48:5000` with `clothwise-backend.onrender.com`

#### Part 3: Important Notes

**Render Free Tier Limitations:**
- ⚠️ Spins down after 15 minutes of inactivity
- ⚠️ First request after spin-down takes 30-60 seconds
- ⚠️ CPU only (no GPU) - slower recommendations
- ⚠️ 750 hours/month (shuts down after that)

**What files to include in Git:**
- ✅ `api_server.py`
- ✅ `train_siamese_resnet50.py`
- ✅ `clothing_classifier.py`
- ✅ `requirements.txt`
- ✅ `render.yaml`
- ✅ `download_models.py`
- ✅ `product_metadata.json`
- ✅ `faiss_indices/` folder
- ❌ `best_model.pt` (too large - use cloud storage)
- ❌ `all_product_images.zip` (too large - use cloud storage)

---

## Recommendation

**For building APK:** Use ngrok! It's faster, easier, and keeps your GPU acceleration.

**For production app:** Use Render with external storage for a permanent solution.

Choose based on your needs!
