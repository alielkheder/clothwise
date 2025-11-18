# API Integration Guide - Flutter App with AI Model

This guide explains how to integrate the AI outfit recommendation model with the ClothWise Flutter app.

## 📋 Overview

The integration consists of:
1. **Flask API Server** - Serves the AI model via REST API
2. **Flutter Service** - Connects Flutter app to the API
3. **Updated UI** - Uses real AI recommendations

## 🚀 Quick Start

### Step 1: Start the Flask API Server

```bash
cd d:\Outfit_recommendation\Outfit_recommendation
python api_server.py
```

The server will start on `http://localhost:5000`

### Step 2: Configure Flutter App

For **Android Emulator**, use:
```dart
baseUrl: 'http://10.0.2.2:5000'
```

For **iOS Simulator**, use:
```dart
baseUrl: 'http://localhost:5000'
```

For **Real Device**, use your computer's IP:
```dart
baseUrl: 'http://192.168.1.X:5000'  // Replace X with your IP
```

Update the `baseUrl` in `lib/src/features/recommendations/data/recommendation_service.dart`

### Step 3: Run Flutter App

```bash
cd d:\Outfit_recommendation\clothwise
flutter pub get
flutter run
```

## 📡 API Endpoints

### 1. Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "metadata_loaded": true,
  "categories": 15
}
```

### 2. Get Recommendations
```http
POST /recommend
Content-Type: application/json

{
  "image": "base64_encoded_image",
  "categories": ["Pants", "Shirts"],  // optional
  "num_items": 15  // optional, default 15
}
```

**Response:**
```json
{
  "success": true,
  "recommendations": {
    "Jeans": [
      {
        "name": "RELAXED JEANS",
        "category": "Jeans",
        "price": "$40.50",
        "description": "Relaxed fit denim jeans",
        "image_id": "data/1234.jpg",
        "gender": "women",
        "url": "https://..."
      }
    ]
  },
  "total_categories": 5
}
```

### 3. Get Categories
```http
GET /categories
```

**Response:**
```json
{
  "categories": ["Jeans", "Pants", "Shirts", "..."],
  "count": 15
}
```

### 4. Get Product Image
```http
GET /image/<image_id>
```

Returns the product image file (JPEG)

### 5. Get Product Details
```http
GET /product/<product_name>
```

**Response:**
```json
{
  "success": true,
  "product": {
    "name": "RELAXED JEANS",
    "category": "Jeans",
    "price": "$40.50",
    "description": "...",
    "image_id": "data/1234.jpg",
    "gender": "women",
    "url": "https://..."
  }
}
```

### 6. Shuffle Recommendations
```http
POST /shuffle
Content-Type: application/json

{
  "category": "Pants",
  "all_items": ["ITEM1", "ITEM2", ...],
  "shown_items": ["ITEM1", "ITEM2"],
  "num_to_show": 3
}
```

**Response:**
```json
{
  "success": true,
  "products": [...],
  "shown_items": ["ITEM1", "ITEM2", "ITEM3"]
}
```

## 🔧 Flutter Integration

### Service Usage

```dart
import 'package:clothwise/src/features/recommendations/data/recommendation_service.dart';

// Create service instance
final service = RecommendationService();

// Get recommendations
final recommendations = await service.getRecommendations(
  imageFile: imageFile,
  categories: ['Pants', 'Shirts'],
  numItems: 15,
);

// Shuffle recommendations
final shuffled = await service.shuffleRecommendations(
  category: 'Pants',
  allItems: allProductNames,
  shownItems: shownProductNames,
  numToShow: 3,
);

// Get product image URL
final imageUrl = service.getProductImageUrl('data/1234.jpg');

// Check API health
final isHealthy = await service.checkHealth();
```

## 🐛 Troubleshooting

### API Server Not Starting

**Error:** Model or data files not found

**Solution:**
```bash
cd d:\Outfit_recommendation\Outfit_recommendation
# Ensure these files exist:
# - best_model.pt
# - product_metadata.json
# - all_product_images.zip
# - faiss_indices/ directory
```

### Flutter Can't Connect to API

**Error:** Connection refused or timeout

**Solutions:**
1. Check API server is running
2. Verify baseUrl in recommendation_service.dart
3. For Android emulator, use `10.0.2.2` instead of `localhost`
4. For real device, ensure both devices are on same WiFi network
5. Check firewall settings

### Images Not Loading

**Error:** 404 for product images

**Solution:**
- Ensure `all_product_images.zip` exists and contains the images
- Verify `image_id` path is correct in metadata
- Check ZIP file structure matches metadata paths

## 🔐 Security Notes

### Production Deployment:

1. **Use HTTPS** - Never use HTTP in production
2. **Add Authentication** - Implement API keys or OAuth
3. **Rate Limiting** - Prevent API abuse
4. **Input Validation** - Validate all inputs
5. **CORS Configuration** - Restrict allowed origins

---

**Generated for ClothWise - AI Outfit Recommendation App**
