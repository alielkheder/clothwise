# ClothWise AI Backend

AI-powered outfit recommendation backend using CLIP Vision Model and FAISS similarity search.

## 🚀 Features

- **Flask REST API** - Serves AI recommendations to Flutter mobile app
- **CLIP Vision Model** - OpenAI's clip-vit-base-patch32 for image embeddings
- **Siamese Network** - Custom projection layer for similarity matching
- **FAISS Search** - Fast similarity search across 1,982 products
- **Smart Shuffle** - Never repeats items until all recommendations shown
- **15 Categories** - Jeans, Pants, Shirts, Dresses, Skirts, and more
- **Product Images** - Served directly from ZIP archive

## 📋 Prerequisites

- Python 3.8+
- pip
- Virtual environment (recommended)

## 🔧 Installation

### Step 1: Clone Repository

```bash
git clone git@github.com:alielkheder/clothwise.git
cd clothwise/backend
```

### Step 2: Create Virtual Environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### Step 3: Install Dependencies

```bash
pip install flask==3.1.2
pip install flask-cors==6.0.1
pip install torch==2.9.0
pip install transformers==4.57.1
pip install faiss-cpu==1.12.0
pip install pillow==11.3.0
pip install streamlit==1.42.0
```

### Step 4: Download Required Files

**IMPORTANT**: These large files are NOT included in the repository. Download them separately:

1. **Model weights** (`best_model.pt`): Download from HuggingFace Space
   - Original: https://huggingface.co/spaces/yiqing111/Outfit_recommendation
   - Place in `backend/` directory

2. **Product images** (`all_product_images.zip`): Download from HuggingFace Space
   - Original: https://huggingface.co/spaces/yiqing111/Outfit_recommendation
   - Place in `backend/` directory

3. These files are already included:
   - ✅ `product_metadata.json` - Product database
   - ✅ `faiss_indices/` - Pre-built FAISS indices

## 🎯 Quick Start

### Run Flask API Server

```bash
cd backend
python api_server.py
```

The API will start on `http://localhost:5000`

### Run Streamlit Web App (Optional)

```bash
cd backend
streamlit run app.py
```

## 📡 API Endpoints

### Health Check
```http
GET /health
```

### Get Recommendations
```http
POST /recommend
Content-Type: application/json

{
  "image": "base64_encoded_image",
  "categories": ["Pants", "Shirts"],
  "num_items": 15
}
```

### Get Categories
```http
GET /categories
```

### Get Product Image
```http
GET /image/<image_id>
```

## 🔗 Flutter Integration

**File**: `lib/src/features/recommendations/data/recommendation_service.dart`

### For Android Emulator:
```dart
baseUrl: 'http://10.0.2.2:5000'
```

### For iOS Simulator:
```dart
baseUrl: 'http://localhost:5000'
```

## 🐛 Troubleshooting

### API Server Not Starting
**Error**: `FileNotFoundError: best_model.pt`
**Solution**: Download `best_model.pt` from HuggingFace (see Step 4 above)

### Images Not Loading
**Error**: `FileNotFoundError: all_product_images.zip`
**Solution**: Download `all_product_images.zip` from HuggingFace (see Step 4 above)

### Flutter Can't Connect
**Solutions**:
1. Ensure API server is running
2. For Android emulator, use `10.0.2.2` instead of `localhost`
3. Ensure both devices on same WiFi network

## 🎉 Running the Full Stack

### Terminal 1: Backend API
```bash
cd clothwise/backend
python api_server.py
```

### Terminal 2: Flutter App
```bash
cd clothwise
flutter pub get
flutter run
```

Now the Flutter app will connect to the AI backend!

## 📦 File Structure

```
backend/
├── api_server.py                 # Flask REST API server
├── app.py                        # Streamlit web app
├── product_metadata.json         # Product database
├── faiss_indices/               # FAISS similarity indices
├── best_model.pt                # Model weights (download required)
├── all_product_images.zip       # Product images (download required)
└── README.md                    # This file
```

---

**Version**: 2.0.0
**Developed by**: ClothWise Team
