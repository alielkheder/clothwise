# ClothWise - Complete Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Flutter Frontend](#flutter-frontend)
4. [AI/ML Backend](#aiml-backend)
5. [Features Deep Dive](#features-deep-dive)
6. [Data Flow](#data-flow)
7. [Technologies Used](#technologies-used)
8. [Setup & Deployment](#setup--deployment)

---

## Project Overview

### What is ClothWise?
ClothWise is an AI-powered fashion recommendation mobile application that helps users:
- Get personalized outfit recommendations using AI
- Browse and discover clothing items
- Build a virtual wardrobe
- Shop for fashion items based on their style preferences

### Core Features
1. **AI Outfit Recommendations** - Upload a clothing item photo and get matching recommendations
2. **Personal Wardrobe** - View and manage clothing items from backend
3. **Smart Shopping** - Browse products with filters and categories
4. **User Authentication** - Secure Firebase-based login system
5. **Style Profiling** - Personalized questionnaire for user preferences
6. **Dark Mode** - Full theme support for better UX

### Technical Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Python Flask + PyTorch
- **Authentication**: Firebase Auth
- **Database**: Product metadata (JSON) + FAISS indices
- **AI Models**: CLIP (Contrastive Language-Image Pre-training)
- **State Management**: Riverpod
- **Routing**: GoRouter

---

## Architecture Overview

### System Architecture Diagram
```
┌─────────────────────────────────────────────────────────┐
│                   Flutter Mobile App                     │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Presentation Layer (UI Screens)                  │  │
│  │  - Splash, Onboarding, Login, Home, etc.         │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Domain Layer (Business Logic)                    │  │
│  │  - Entities, Use Cases                           │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Data Layer (Services & Repositories)            │  │
│  │  - API Services, Local Storage                   │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          │ HTTP/REST API
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Python Flask Backend Server                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │  REST API Endpoints                               │  │
│  │  /recommend, /products, /health, etc.            │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  AI/ML Models                                     │  │
│  │  - CLIP Model (Image + Text Embeddings)          │  │
│  │  - Clothing Classifier                           │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  FAISS Indices (Vector Search)                    │  │
│  │  - 15 category-based indices                     │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Product Metadata Database                        │  │
│  │  - 1,982 products with images                    │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Flutter Frontend

### Project Structure
```
lib/
├── src/
│   ├── app/                    # App-level configuration
│   │   ├── router.dart         # Navigation routing
│   │   └── theme/              # App theming
│   ├── core/                   # Core utilities
│   │   └── services/           # Shared services
│   ├── features/               # Feature modules
│   │   ├── auth/               # Authentication
│   │   ├── home/               # Home screen
│   │   ├── wardrobe/           # Wardrobe management
│   │   ├── shop/               # Shopping features
│   │   ├── recommendations/    # AI recommendations
│   │   ├── profile/            # User profile
│   │   ├── onboarding/         # First-time user flow
│   │   └── splash/             # Splash screen
│   └── widgets/                # Reusable widgets
└── main.dart                   # App entry point
```

### Clean Architecture Layers

#### 1. Presentation Layer
**What it does**: Displays UI and handles user interactions

**Files**: `*_screen.dart`, `*_widget.dart`

**Example**:
```dart
// home_screen.dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches state from providers
    final outfits = ref.watch(savedOutfitsProvider);

    return Scaffold(
      body: ListView.builder(
        itemCount: outfits.length,
        itemBuilder: (context, index) {
          return OutfitCard(outfit: outfits[index]);
        },
      ),
    );
  }
}
```

**Key Concepts**:
- **ConsumerWidget**: Listens to state changes from Riverpod providers
- **ref.watch()**: Watches a provider and rebuilds when data changes
- **StatefulWidget vs StatelessWidget**:
  - StatefulWidget: Can change state internally (e.g., form inputs)
  - StatelessWidget: Immutable, rebuilds from parent

#### 2. Domain Layer
**What it does**: Defines business rules and entities

**Files**: `entities/*.dart`, `repositories/*.dart`

**Example**:
```dart
// clothing_item.dart (Entity)
class ClothingItem {
  final String id;
  final String name;
  final ClothingCategory category;
  final String color;
  final ClothingUsage usage;
  final String? imageUrl;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.usage,
    this.imageUrl,
  });
}

// Enums define allowed values
enum ClothingCategory {
  topwear,
  bottomwear,
  footwear,
  onePiece,
}

enum ClothingUsage {
  casual,
  formal,
  party,
}
```

**Key Concepts**:
- **Entities**: Pure data models representing business objects
- **Immutable**: Uses `final` keywords - data cannot be changed after creation
- **Enums**: Define a fixed set of values (prevents typos)

#### 3. Data Layer
**What it does**: Handles data fetching and storage

**Files**: `services/*.dart`, `repositories/*.dart`

**Example**:
```dart
// recommendation_service.dart
class RecommendationService {
  final Dio _dio; // HTTP client

  Future<Map<String, List<ProductRecommendation>>> getRecommendations({
    required String imagePath,
  }) async {
    // 1. Read image file
    final xFile = XFile(imagePath);
    final bytes = await xFile.readAsBytes();

    // 2. Convert to base64 (text format for HTTP)
    final base64Image = base64Encode(bytes);

    // 3. Send HTTP POST request to backend
    final response = await _dio.post('/recommend', data: {
      'image': base64Image,
      'num_items': 15,
    });

    // 4. Parse JSON response
    final data = response.data;
    final recommendationsData = data['recommendations'];

    // 5. Convert JSON to Dart objects
    final recommendations = <String, List<ProductRecommendation>>{};
    for (final entry in recommendationsData.entries) {
      final category = entry.key;
      final products = (entry.value as List)
          .map((p) => ProductRecommendation.fromJson(p))
          .toList();
      recommendations[category] = products;
    }

    return recommendations;
  }
}
```

**Key Concepts**:
- **Dio**: HTTP client for making API requests
- **async/await**: Handle asynchronous operations (network calls)
- **Future<T>**: Represents a value that will be available in the future
- **JSON Parsing**: Convert JSON to Dart objects using `.fromJson()`

### State Management with Riverpod

**What is Riverpod?**
A reactive state management library that:
- Provides dependency injection
- Automatically rebuilds UI when data changes
- Prevents bugs with compile-time safety

**Example**:
```dart
// 1. Define a provider (data source)
final backendProductsProvider = FutureProvider<List<ClothingItem>>((ref) async {
  final service = ref.watch(backendProductsServiceProvider);
  return await service.getAllProducts();
});

// 2. Use in UI
class WardrobeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(backendProductsProvider);

    // Handle loading/error/data states
    return productsState.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (products) => GridView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}
```

**Provider Types**:
- **Provider**: Simple, immutable value
- **FutureProvider**: Async data (API calls)
- **StateProvider**: Simple mutable state
- **StateNotifierProvider**: Complex state with logic

### Navigation with GoRouter

**What is GoRouter?**
Declarative routing library for Flutter

**Example**:
```dart
// router.dart - Define routes
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/recommendations',
      name: 'recommendations',
      builder: (context, state) {
        final imagePath = state.extra as String;
        return RecommendationsScreen(imagePath: imagePath);
      },
    ),
  ],
);

// Usage in UI
// Navigate to a route
context.go('/home');

// Navigate with parameters
context.go('/recommendations', extra: '/path/to/image.jpg');

// Go back
context.pop();
```

**Key Concepts**:
- **Declarative Routing**: Define all routes upfront
- **Type Safety**: Routes defined as constants
- **Deep Linking**: Can handle URLs like `myapp://recommendations/123`

### Firebase Authentication

**What is Firebase Auth?**
Backend service for user authentication

**Flow**:
```
User enters email/password
    ↓
Flutter calls Firebase SDK
    ↓
Firebase verifies credentials
    ↓
Returns User object with UID
    ↓
App stores auth state
    ↓
User stays logged in (persistent)
```

**Implementation**:
```dart
// firebase_auth_service.dart
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register new user
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    // Create Firebase account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name
    await credential.user!.updateDisplayName(username);

    // Send verification email
    await credential.user!.sendEmailVerification();

    // Return app user
    return AppUser(
      uid: credential.user!.uid,
      email: email,
      username: username,
      isEmailVerified: false,
    );
  }

  // Sign in existing user
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return AppUser(
      uid: credential.user!.uid,
      email: credential.user!.email!,
      username: credential.user!.displayName ?? '',
      isEmailVerified: credential.user!.emailVerified,
    );
  }

  // Check current user
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return AppUser(
      uid: user.uid,
      email: user.email!,
      username: user.displayName ?? '',
      isEmailVerified: user.emailVerified,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

**Key Features**:
- Email/Password authentication
- Email verification
- Password reset
- Persistent login (automatic)
- User metadata (UID, email, display name)

---

## AI/ML Backend

### Backend Architecture

```
backend/
├── api_server.py           # Main Flask server
├── best_model.pt           # Trained CLIP model weights
├── product_metadata.json   # 1,982 products database
├── data/                   # Product images
│   ├── 1_1.jpg
│   ├── 1_2.jpg
│   └── ...
└── indices/                # FAISS vector indices
    ├── Shirts_index.faiss
    ├── Jeans_index.faiss
    └── ...
```

### CLIP Model (AI Brain)

**What is CLIP?**
CLIP (Contrastive Language-Image Pre-training) is an AI model by OpenAI that:
- Understands both images and text
- Creates "embeddings" (numerical representations) of images
- Can compare similarity between images

**How it works**:
```
Input: Photo of a blue shirt
    ↓
CLIP processes image through neural network
    ↓
Output: Vector of 512 numbers (embedding)
    Example: [0.23, -0.45, 0.89, ..., 0.12]
    ↓
This vector represents the "essence" of the image
```

**Code**:
```python
# Load CLIP model
import clip
import torch

device = "cuda" if torch.cuda.is_available() else "cpu"
model, preprocess = clip.load("ViT-B/32", device=device)

# Convert image to embedding
def encode_image(image_path):
    # Load and preprocess image
    image = Image.open(image_path)
    image = preprocess(image).unsqueeze(0).to(device)

    # Get embedding from CLIP
    with torch.no_grad():
        embedding = model.encode_image(image)

    # Normalize to unit vector
    embedding = embedding / embedding.norm(dim=-1, keepdim=True)

    return embedding.cpu().numpy()
```

**Why CLIP?**
- Pre-trained on 400 million image-text pairs
- Understands fashion and clothing concepts
- Very accurate for visual similarity

### FAISS (Fast Similarity Search)

**What is FAISS?**
FAISS (Facebook AI Similarity Search) is a library for:
- Storing millions of vectors efficiently
- Finding similar vectors quickly (milliseconds)
- Approximate nearest neighbor search

**How it works**:
```
1. Build Index (One-time setup):
   - Take all product images
   - Get CLIP embeddings for each
   - Store in FAISS index

2. Search (Real-time):
   - User uploads photo
   - Get CLIP embedding
   - FAISS finds most similar embeddings
   - Return corresponding products
```

**Code**:
```python
import faiss
import numpy as np

# Build index for a category (e.g., "Shirts")
def build_faiss_index(category_products):
    # Get embeddings for all products
    embeddings = []
    for product in category_products:
        embedding = encode_image(product['image_path'])
        embeddings.append(embedding)

    # Convert to numpy array
    embeddings = np.array(embeddings).astype('float32')

    # Create FAISS index
    dimension = 512  # CLIP embedding size
    index = faiss.IndexFlatL2(dimension)  # L2 = Euclidean distance
    index.add(embeddings)

    # Save to disk
    faiss.write_index(index, f"{category}_index.faiss")
    return index

# Search for similar items
def search_similar(query_embedding, index, k=10):
    # Find k nearest neighbors
    distances, indices = index.search(query_embedding, k)

    # distances: how far each match is (lower = more similar)
    # indices: position in original product list

    return indices[0]  # Return product IDs
```

**Index Types**:
- **IndexFlatL2**: Exact search (slower but accurate)
- **IndexIVFFlat**: Approximate search (faster, slightly less accurate)
- We use separate indices per category for faster search

### Flask API Server

**What is Flask?**
Lightweight Python web framework for building REST APIs

**API Endpoints**:

#### 1. Health Check
```python
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'model_loaded': clip_model is not None,
        'metadata_loaded': len(product_metadata) > 0,
        'categories': len(category_indices)
    })
```

**What it does**: Checks if server is running and models are loaded

---

#### 2. Get Recommendations
```python
@app.route('/recommend', methods=['POST'])
def recommend():
    # 1. Get image from request
    data = request.json
    image_base64 = data['image']

    # 2. Decode base64 to image
    image_bytes = base64.b64decode(image_base64)
    image = Image.open(io.BytesIO(image_bytes))

    # 3. Get CLIP embedding
    query_embedding = encode_image(image)

    # 4. Search in each category
    recommendations = {}
    for category, index in category_indices.items():
        # Find 3 most similar items
        similar_indices = search_similar(query_embedding, index, k=3)

        # Get product details
        products = [product_metadata[category][i] for i in similar_indices]
        recommendations[category] = products

    return jsonify({
        'success': True,
        'recommendations': recommendations
    })
```

**What it does**: Takes an image and returns similar products from each category

**Flow**:
```
User uploads photo → Base64 encoding → HTTP POST
    ↓
Flask receives request
    ↓
Decode image
    ↓
CLIP creates embedding
    ↓
FAISS searches each category
    ↓
Return top 3 matches per category
    ↓
Flutter displays results
```

---

#### 3. Get Products
```python
@app.route('/products', methods=['GET'])
def get_products():
    # Get query parameters
    category = request.args.get('category')  # Optional
    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))

    # Flatten all products
    all_products = []
    for cat_products in product_metadata.values():
        all_products.extend(cat_products)

    # Filter by category if specified
    if category:
        all_products = [p for p in all_products if p['category'] == category]

    # Pagination
    paginated = all_products[offset:offset+limit]

    return jsonify({
        'success': True,
        'products': paginated,
        'total': len(all_products)
    })
```

**What it does**: Returns list of products with pagination

---

#### 4. Serve Images
```python
@app.route('/image/<path:image_id>', methods=['GET'])
def serve_image(image_id):
    # Construct file path
    image_path = os.path.join('data', image_id)

    # Check if file exists
    if not os.path.exists(image_path):
        return jsonify({'error': 'Image not found'}), 404

    # Send image file
    return send_file(image_path, mimetype='image/jpeg')
```

**What it does**: Serves product images to the app

---

### Product Metadata Structure

**File**: `product_metadata.json`

**Format**:
```json
{
  "Shirts": [
    {
      "name": "Blue Cotton Shirt",
      "category": "Shirts",
      "price": "$29.99",
      "description": "Comfortable blue cotton shirt for casual wear",
      "image_id": "data/1_1.jpg",
      "url": "https://amazon.com/...",
      "gender": "male",
      "style_type": "casual"
    },
    ...
  ],
  "Jeans": [ ... ],
  "Shoes": [ ... ]
}
```

**Fields**:
- **name**: Product title
- **category**: Clothing category (Shirts, Jeans, etc.)
- **price**: Price string (for display)
- **description**: Product description
- **image_id**: Path to product image
- **url**: External shopping link
- **gender**: Target gender (male/female/unisex)
- **style_type**: Style category (casual/formal/party)

---

### Clothing Classifier

**What it does**: Automatically classifies uploaded clothing into categories

**How it works**:
```python
# Text prompts for each category
text_prompts = [
    "a photo of a shirt",
    "a photo of jeans",
    "a photo of shoes",
    "a photo of a dress",
    ...
]

# Encode text prompts using CLIP
text_embeddings = model.encode_text(clip.tokenize(text_prompts))

# For uploaded image
def classify_clothing(image):
    # Get image embedding
    image_embedding = model.encode_image(preprocess(image))

    # Calculate similarity with each text prompt
    similarities = image_embedding @ text_embeddings.T

    # Get highest scoring category
    category_idx = similarities.argmax()
    category = categories[category_idx]
    confidence = similarities[category_idx].item()

    return category, confidence
```

**Why useful?**
- Auto-tags uploaded clothing
- Ensures correct category matching
- Improves recommendation accuracy

---

## Features Deep Dive

### 1. Splash Screen & Onboarding

**Purpose**: First-time user experience

**Logic**:
```dart
Future<void> _navigateBasedOnState() async {
  // Check if user completed onboarding
  final hasCompletedOnboarding = await PreferencesService.hasCompletedOnboarding();

  // Check if user is logged in
  final user = FirebaseAuth.instance.currentUser;

  // Route decision
  if (!hasCompletedOnboarding) {
    context.go('/onboarding');  // First time
  } else if (user == null) {
    context.go('/login');        // Returning, not logged in
  } else {
    context.go('/home');         // Returning, logged in
  }
}
```

**Onboarding Flow**:
1. Splash (2 seconds)
2. 3 Onboarding screens (swipe)
3. 5 Style questions
4. Mark as complete in SharedPreferences
5. Navigate to Login

**Persistence**:
```dart
// Save onboarding completion
class PreferencesService {
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
```

---

### 2. Style Questionnaire

**Purpose**: Collect user preferences

**Questions**:
1. Daily style (Casual/Formal/etc.)
2. Favorite colors
3. Usual environment
4. Comfort importance
5. Budget preference

**Storage**:
```dart
Future<void> _saveAnswers() async {
  final prefs = await SharedPreferences.getInstance();

  // Save each answer
  await prefs.setString('style_answer_1', 'Casual');
  await prefs.setString('style_answer_2', 'Neutrals');
  await prefs.setString('style_answer_3', 'University');
  await prefs.setString('style_answer_4', 'Very important');
  await prefs.setString('style_answer_5', 'Mid');

  // Mark questionnaire complete
  await prefs.setBool('style_questionnaire_completed', true);
}
```

**Usage** (Can be implemented):
```dart
// Filter products by budget
final budget = prefs.getString('style_answer_5');
if (budget == 'Low') {
  products = products.where((p) => p.priceValue < 30).toList();
} else if (budget == 'Mid') {
  products = products.where((p) => p.priceValue >= 30 && p.priceValue < 60).toList();
}
```

---

### 3. AI Recommendations

**User Flow**:
```
1. User taps Camera FAB
2. Choose source (Camera/Gallery)
3. Pick image
4. Show loading
5. Call backend API
6. Display recommendations grid
7. User can select items
8. Save outfit (optional)
```

**Implementation**:
```dart
// 1. Pick image
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.camera);

// 2. Call recommendation service
final recommendations = await RecommendationService().getRecommendations(
  imagePath: image!.path,
);

// 3. Display results
GridView.builder(
  itemCount: recommendations['Shirts'].length,
  itemBuilder: (context, index) {
    final product = recommendations['Shirts'][index];
    return ProductCard(product: product);
  },
)
```

**Backend Process**:
```python
# 1. Receive image
image_base64 = request.json['image']
image = decode_base64_image(image_base64)

# 2. Get CLIP embedding (512-dimensional vector)
embedding = clip_model.encode_image(image)

# 3. Search each category FAISS index
recommendations = {}
for category in ['Shirts', 'Jeans', 'Shoes', ...]:
    index = faiss_indices[category]
    similar_ids = index.search(embedding, k=3)  # Top 3
    products = [metadata[category][id] for id in similar_ids]
    recommendations[category] = products

# 4. Return JSON
return {'success': True, 'recommendations': recommendations}
```

---

### 4. Wardrobe Management

**Purpose**: Display all available clothing items

**Data Source**: Backend `/products` endpoint

**Flow**:
```
App starts → Call /products API → Load 100 items
    ↓
Display in grid
    ↓
User scrolls → Load next 100 (pagination)
```

**Implementation**:
```dart
final backendProductsProvider = FutureProvider<List<ClothingItem>>((ref) async {
  final service = BackendProductsService();
  return await service.getAllProducts(limit: 100);
});

// In UI
class WardrobeScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(backendProductsProvider);

    return productsState.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
      data: (products) {
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _WardrobeItemCard(item: products[index]);
          },
        );
      },
    );
  }
}
```

**Backend**:
```python
@app.route('/products', methods=['GET'])
def get_products():
    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))

    # Flatten all products
    all_products = []
    for category_products in product_metadata.values():
        all_products.extend(category_products)

    # Paginate
    result = all_products[offset:offset+limit]

    return jsonify({
        'success': True,
        'products': result,
        'total': len(all_products)
    })
```

---

### 5. Profile & Settings

**Features**:
- Display username (from Firebase Auth)
- Item count (from wardrobe)
- Style score (random 85-100%)
- Dark mode toggle
- Gender preference
- Notification settings

**Data Sources**:
```dart
// Username from Firebase
final user = FirebaseAuth.instance.currentUser;
final username = user?.displayName ?? user?.email.split('@')[0];

// Item count from wardrobe
final wardrobeState = ref.watch(backendProductsProvider);
final itemCount = wardrobeState.when(
  data: (items) => items.length,
  loading: () => 0,
  error: (_, __) => 0,
);

// Random style score
final styleScore = 85 + Random().nextInt(16); // 85-100
```

**Dark Mode Implementation**:
```dart
// Theme provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

// In MaterialApp
MaterialApp(
  themeMode: ref.watch(themeModeProvider),
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  ...
)
```

---

## Data Flow

### Complete Request Flow Example

**Scenario**: User wants AI recommendations for a blue shirt

```
┌─────────────────────────────────────────────────────┐
│ 1. USER INTERACTION                                  │
│    User taps Camera FAB → Selects photo             │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 2. FLUTTER APP (Presentation Layer)                 │
│    recommendations_screen.dart                       │
│    - Shows loading indicator                         │
│    - Calls recommendation service                    │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 3. FLUTTER APP (Data Layer)                         │
│    recommendation_service.dart                       │
│    - Reads image file                                │
│    - Converts to base64                              │
│    - Creates HTTP POST request                       │
└─────────────────────────────────────────────────────┘
                    ↓
        HTTP POST to 192.168.1.5:5000/recommend
        Body: { "image": "base64_string...", "num_items": 15 }
                    ↓
┌─────────────────────────────────────────────────────┐
│ 4. BACKEND (Flask API)                              │
│    api_server.py - /recommend endpoint              │
│    - Receives POST request                           │
│    - Decodes base64 to image                         │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 5. AI MODEL (CLIP)                                  │
│    - Preprocesses image (resize, normalize)          │
│    - Passes through neural network                   │
│    - Outputs 512-dimensional embedding               │
│      [0.23, -0.45, 0.89, ..., 0.12]                │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 6. FAISS SEARCH (For each category)                │
│    Shirts Index:                                     │
│    - Compare embedding with 300 shirt embeddings     │
│    - Find top 3 most similar (L2 distance)          │
│    - Return indices [45, 102, 234]                  │
│                                                      │
│    Jeans Index:                                      │
│    - Compare with 250 jeans embeddings              │
│    - Find top 3 → [12, 89, 156]                     │
│                                                      │
│    ... (repeat for all 15 categories)               │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 7. PRODUCT LOOKUP                                   │
│    product_metadata.json                             │
│    - Get product details for each index              │
│    - Shirts[45] = {name: "Blue Polo", price: "$25"} │
│    - Jeans[12] = {name: "Dark Jeans", price: "$40"} │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 8. BACKEND RESPONSE                                 │
│    JSON Response:                                    │
│    {                                                 │
│      "success": true,                                │
│      "recommendations": {                            │
│        "Shirts": [                                   │
│          {"name": "Blue Polo", "price": "$25", ...}, │
│          {"name": "Navy Shirt", "price": "$30", ...},│
│          {"name": "Sky Blue Tee", "price": "$15", ...}│
│        ],                                            │
│        "Jeans": [...],                               │
│        ...                                           │
│      }                                               │
│    }                                                 │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 9. FLUTTER APP (Data Layer)                         │
│    recommendation_service.dart                       │
│    - Receives JSON response                          │
│    - Parses into ProductRecommendation objects       │
│    - Returns Map<String, List<ProductRecommendation>>│
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 10. FLUTTER APP (Presentation Layer)                │
│     recommendations_screen.dart                      │
│     - Hides loading indicator                        │
│     - Displays products in grid                      │
│     - User sees 3 shirts, 3 jeans, etc.             │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ 11. USER SEES RESULTS                               │
│     - Grid of recommended products                   │
│     - Can select items                               │
│     - Can save outfit                                │
└─────────────────────────────────────────────────────┘
```

**Time Breakdown**:
- Image encoding: ~100ms
- HTTP request: ~50ms
- CLIP processing: ~200ms
- FAISS search (15 categories): ~50ms
- Response parsing: ~50ms
- **Total**: ~450ms (under 0.5 seconds!)

---

## Technologies Used

### Frontend Technologies

#### 1. **Flutter Framework**
- **Version**: Latest stable
- **Language**: Dart
- **Platform**: Android (can do iOS/Web too)
- **Why**: Single codebase for multiple platforms, fast development, beautiful UI

#### 2. **Riverpod** (State Management)
- **Version**: flutter_riverpod ^2.0.0
- **Purpose**: Manage app state and data flow
- **Advantages**:
  - Compile-time safety
  - Easy testing
  - No BuildContext needed
  - Better than Provider/BLoC for this use case

#### 3. **GoRouter** (Navigation)
- **Version**: go_router ^13.0.0
- **Purpose**: Handle app navigation and routing
- **Features**:
  - Deep linking support
  - Type-safe routes
  - Declarative routing

#### 4. **Firebase** (Backend Services)
- **firebase_core**: Core Firebase SDK
- **firebase_auth**: User authentication
- **Why**: Free tier, easy setup, reliable, automatic persistence

#### 5. **Dio** (HTTP Client)
- **Version**: dio ^5.0.0
- **Purpose**: Make HTTP requests to backend
- **Features**:
  - Interceptors
  - Timeout handling
  - Progress tracking
  - Better than http package

#### 6. **SharedPreferences** (Local Storage)
- **Version**: shared_preferences ^2.0.0
- **Purpose**: Store user preferences and onboarding state
- **Uses**:
  - Onboarding completion flag
  - Style questionnaire answers
  - App settings

#### 7. **Image Picker** (Camera/Gallery)
- **Version**: image_picker ^1.0.0
- **Purpose**: Pick images from camera or gallery
- **Platform**: Works on Android/iOS

### Backend Technologies

#### 1. **Python**
- **Version**: 3.12
- **Why**: Best for AI/ML, large ecosystem, easy to learn

#### 2. **Flask** (Web Framework)
- **Version**: 2.3.0
- **Purpose**: Build REST API
- **Why**: Lightweight, simple, perfect for ML APIs
- **Alternative**: FastAPI (more modern but more complex)

#### 3. **PyTorch** (Deep Learning)
- **Version**: 2.0.0+
- **Purpose**: Run CLIP neural network
- **Why**: Industry standard, CUDA support for GPU
- **Components**:
  - torch: Core tensor library
  - torchvision: Image processing

#### 4. **CLIP** (AI Model)
- **Model**: ViT-B/32 (Vision Transformer)
- **Source**: OpenAI
- **Size**: ~350MB
- **Parameters**: ~151 million
- **Embedding Size**: 512 dimensions

#### 5. **FAISS** (Vector Search)
- **Version**: faiss-gpu or faiss-cpu
- **Purpose**: Fast similarity search
- **Why**: Handles millions of vectors efficiently
- **Developed by**: Facebook AI Research

#### 6. **Pillow** (Image Processing)
- **Version**: 10.0.0+
- **Purpose**: Load, resize, process images
- **Format Support**: JPG, PNG, etc.

#### 7. **NumPy** (Numerical Computing)
- **Version**: 1.24.0+
- **Purpose**: Array operations, vector math
- **Use**: Convert between PyTorch tensors and FAISS arrays

---

## Setup & Deployment

### Prerequisites

**For Flutter Development**:
- Flutter SDK (3.16.0+)
- Dart SDK (included with Flutter)
- Android Studio or VS Code
- Android SDK
- Java JDK 17

**For Backend Development**:
- Python 3.12
- CUDA 11.8+ (for GPU support)
- NVIDIA GPU (optional but recommended)

### Flutter Setup

```bash
# 1. Check Flutter installation
flutter doctor

# 2. Install dependencies
cd clothwise
flutter pub get

# 3. Run on emulator/device
flutter run

# 4. Build APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

### Backend Setup

```bash
# 1. Navigate to backend
cd backend

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Download CLIP model (automatic on first run)
python -c "import clip; clip.load('ViT-B/32')"

# 4. Start server
python api_server.py

# Server runs on http://192.168.1.5:5000
```

### Network Configuration

**For Android Emulator**:
```dart
// Use 10.0.2.2 instead of localhost
baseUrl: 'http://10.0.2.2:5000'
```

**For Real Phone (Same WiFi)**:
```dart
// Use computer's local IP
baseUrl: 'http://192.168.1.5:5000'

// Find your IP:
// Windows: ipconfig
// Mac: ifconfig
// Linux: ip addr
```

**For Cloud Deployment** (Optional):
- Deploy backend to Render/Railway/AWS
- Update all baseUrl to cloud URL
- More complex but works anywhere

---

## Key Concepts Explained

### 1. Embeddings
**What**: Numerical representation of data
**Example**: Image → [0.23, -0.45, ..., 0.12] (512 numbers)
**Why**: Computers can't compare images directly, but can compare numbers
**Math**: Cosine similarity or L2 distance between vectors

### 2. Neural Networks
**What**: AI model that learns patterns from data
**Structure**: Layers of neurons (mathematical functions)
**CLIP**: 151 million parameters (learned numbers)
**Training**: Showed 400 million image-text pairs

### 3. REST API
**What**: Communication protocol between app and server
**Format**: HTTP requests with JSON data
**Methods**: GET (read), POST (create), PUT (update), DELETE (delete)
**Example**: POST /recommend → Get recommendations

### 4. Async/Await
**What**: Handle operations that take time (network, file I/O)
**Why**: Prevent app from freezing
**Example**:
```dart
// Without async: App freezes for 2 seconds
final data = getDataFromInternet(); // Blocks!

// With async: App continues running
final data = await getDataFromInternet(); // Non-blocking!
```

### 5. State Management
**What**: How app tracks and updates data
**Problem**: Multiple screens need same data
**Solution**: Central store (provider) that all screens can access
**Update**: Change provider → All listeners rebuild automatically

### 6. Clean Architecture
**Why**: Separation of concerns
**Layers**:
- Presentation: UI only
- Domain: Business logic
- Data: External communication
**Benefit**: Easy to test, maintain, scale

---

## Performance Optimization

### Flutter App
1. **Image Caching**: Cached product images to avoid reloading
2. **Lazy Loading**: Load products as user scrolls (pagination)
3. **State Optimization**: Only rebuild widgets that changed
4. **Asset Optimization**: Compressed images

### Backend
1. **GPU Acceleration**: CUDA for CLIP model (10x faster)
2. **FAISS Indexing**: Pre-computed embeddings (instant search)
3. **Category Splitting**: Separate indices per category (faster search)
4. **Batch Processing**: Process multiple images together (future improvement)

---

## Common Issues & Solutions

### Issue 1: "Cannot connect to backend"
**Cause**: Network configuration
**Solutions**:
- Check backend is running (python api_server.py)
- Verify IP address (ipconfig/ifconfig)
- For emulator: Use 10.0.2.2
- For phone: Use local IP (e.g., 192.168.1.5)
- Same WiFi network required

### Issue 2: "Out of memory" in backend
**Cause**: GPU memory insufficient
**Solutions**:
- Use CPU version: `device = "cpu"`
- Reduce batch size
- Close other GPU applications
- Use smaller CLIP model (ViT-B/16 instead of ViT-B/32)

### Issue 3: "Firebase auth error"
**Cause**: Configuration issue
**Solutions**:
- Check google-services.json exists
- Verify Firebase project setup
- Check internet connection
- Email verification might be needed

### Issue 4: "App crashes on launch"
**Cause**: Various
**Solutions**:
- Run `flutter clean`
- Delete build folder
- Reinstall APK
- Check logs: `flutter logs`

---

## Testing Guide

### Flutter Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/features/home/home_screen_test.dart
```

### Backend Testing
```bash
# Test health endpoint
curl http://192.168.1.5:5000/health

# Test products endpoint
curl http://192.168.1.5:5000/products?limit=5

# Test recommendation (requires base64 image)
curl -X POST http://192.168.1.5:5000/recommend \
  -H "Content-Type: application/json" \
  -d '{"image": "base64_string_here"}'
```

---

## Future Improvements

### High Priority
1. **Implement Saved Outfits**: Actually save and display user's created outfits
2. **Use Style Preferences**: Filter/personalize based on questionnaire
3. **Weather Integration**: Add weather API for context-aware recommendations
4. **Make Settings Functional**: Save and apply gender/city preferences

### Medium Priority
1. **Shopping Cart**: Add cart functionality
2. **Favorites/Wishlist**: Let users save favorite items
3. **Improved UI**: More animations and transitions
4. **Offline Mode**: Cache products for offline viewing

### Low Priority
1. **Social Features**: Share outfits with friends
2. **AI Stylist Chat**: Conversational recommendations
3. **Virtual Try-On**: AR feature to see clothes on user
4. **Price Tracking**: Alert when price drops

---

## Glossary

**API**: Application Programming Interface - way for apps to communicate
**APK**: Android Package - installable Android app file
**Async**: Asynchronous - code that runs in background
**Base64**: Text encoding of binary data (images)
**CLIP**: AI model that understands images and text
**Dio**: HTTP client library for Dart
**Embedding**: Numerical representation (vector) of data
**FAISS**: Fast similarity search library
**Firebase**: Google's backend platform
**Flutter**: UI framework by Google
**GoRouter**: Navigation library
**JSON**: JavaScript Object Notation - data format
**Provider**: State management tool
**REST**: Representational State Transfer - API style
**Riverpod**: Advanced state management
**Vector**: Array of numbers
**Widget**: UI component in Flutter

---

## Conclusion

This documentation covers the complete ClothWise project from architecture to implementation details. Key takeaways:

1. **Flutter provides the UI**: Clean, fast, cross-platform mobile app
2. **CLIP provides the AI**: Understands clothing similarity
3. **FAISS provides the speed**: Instant search among thousands of items
4. **Firebase provides auth**: Secure user management
5. **Clean architecture**: Maintainable, testable, scalable code

The app demonstrates:
- Mobile development (Flutter)
- AI/ML integration (PyTorch, CLIP)
- Backend development (Flask)
- Database management (JSON, FAISS)
- Authentication (Firebase)
- State management (Riverpod)

Perfect for a graduation project showing full-stack + AI skills! 🎓

---

**Version**: 1.0
**Last Updated**: November 2025
**Author**: ClothWise Development Team
