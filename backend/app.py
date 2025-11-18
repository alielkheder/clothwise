import streamlit as st
import torch
import json
import zipfile
from PIL import Image
from transformers import CLIPImageProcessor, CLIPVisionModel
from train_siamese_resnet50 import SiameseWithProjection
import faiss
import numpy as np
import os
from io import BytesIO
import random

# Fixed path settings
MODEL_PATH = "best_model.pt"
FAISS_DIR = "faiss_indices"
METADATA_PATH = "product_metadata.json"
ZIP_PATH = "all_product_images.zip"

# Set page title and configuration
st.set_page_config(page_title="Outfit Recommendation System", layout="wide")
st.title("Outfit Recommendation System")

# Function to load model
@st.cache_resource
def load_model(path_to_model=MODEL_PATH, device="cuda"):
    # Reconstruct architecture
    clip = CLIPVisionModel.from_pretrained("openai/clip-vit-base-patch32")
    processor = CLIPImageProcessor.from_pretrained("openai/clip-vit-base-patch32")

    # Model class must match how it was trained
    model = SiameseWithProjection(clip_model=clip)

    # Load weights
    state_dict = torch.load(path_to_model, map_location="cuda" if torch.cuda.is_available() else "cpu")
    model.load_state_dict(state_dict)
    
    model.to("cuda" if torch.cuda.is_available() else "cpu").eval()
    return model, processor

# Function to get recommendations
def recommend_with_faiss(user_image, model, processor, faiss_dir=FAISS_DIR):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    
    # Process user image
    if isinstance(user_image, str):
        image = Image.open(user_image).convert("RGB")
    else:
        image = Image.open(BytesIO(user_image)).convert("RGB")
        
    inputs = processor(images=image, return_tensors="pt").to(device)

    with torch.no_grad():
        user_emb = model.clip(pixel_values=inputs['pixel_values']).last_hidden_state[:, 0, :]
        user_emb = model.projector(user_emb).squeeze(0).cpu().numpy().astype("float32")

    # Iterate over category indexes
    recommendations = {}
    for file in os.listdir(faiss_dir):
        if file.endswith(".index"):
            category = file.replace(".index", "")
            index = faiss.read_index(f"{faiss_dir}/{file}")
            with open(f"{faiss_dir}/{category}_ids.json") as f:
                id_map = json.load(f)

            # Get more recommendations for shuffle functionality
            k = min(15, len(id_map))  # Get up to 15 recommendations
            D, I = index.search(user_emb[None], k=k)
            top_indices = [int(i) for i in I[0]]
            recommendations[category] = [id_map[idx] for idx in top_indices]

    return recommendations

# Function to get shuffled subset of recommendations without repeats
def get_shuffled_recommendations(all_products, shown_products, num_to_show=3):
    """Get a random subset of products for display, excluding already shown items"""
    # Filter out products that have already been shown
    available_products = [p for p in all_products if p not in shown_products]

    # If we've shown everything, reset and start over
    if len(available_products) < num_to_show:
        available_products = all_products
        shown_products.clear()

    # Select random products from available ones
    selected = random.sample(available_products, min(num_to_show, len(available_products)))

    # Mark these as shown
    shown_products.update(selected)

    return selected

# Function to display product images
def display_product_images(product_names, metadata, zip_path=ZIP_PATH):
    cols = st.columns(len(product_names))

    with zipfile.ZipFile(zip_path, 'r') as archive:
        for i, (col, product_name) in enumerate(zip(cols, product_names)):
            with col:
                image_path = metadata[product_name]['image']
                with archive.open(image_path) as f:
                    image = Image.open(f).convert("RGB")
                    st.image(image, caption=product_name, use_container_width=True)

                # Display only price information
                st.write(f"**Price:** {metadata.get(product_name, {}).get('price', 'N/A')}")

# Sidebar - Project introduction and usage guide
st.sidebar.title("About This Project")
st.sidebar.markdown("""
This is an AI-powered outfit recommendation system that analyzes your photos and recommends clothing items that match your style.
""")

st.sidebar.title("How To Use")
st.sidebar.markdown("""
### Instructions:
1. Upload your photo
2. Click "Get Recommendations" button
3. Use the filter to select clothing categories you're interested in
4. View your personalized recommendations
5. Click "Shuffle" to see different recommendations if you don't like the current ones
""")

# Load metadata
try:
    with open(METADATA_PATH, 'r') as f:
        metadata = json.load(f)
    
    # Extract available categories from metadata
    available_categories = set()
    for product_info in metadata.values():
        if 'category' in product_info:
            available_categories.add(product_info['category'])
    available_categories = sorted(list(available_categories))
    
except Exception as e:
    st.error(f"Error loading metadata: {e}")
    st.stop()
    
# Load model
try:
    model, processor = load_model()
except Exception as e:
    st.error(f"Error loading model: {e}")
    st.stop()

# Main app interface
st.markdown("### Upload your photo to get personalized outfit recommendations")

# Image upload (only upload option, no camera)
uploaded_file = st.file_uploader("Choose an image...", type=["jpg", "jpeg", "png"])
user_image = None
if uploaded_file is not None:
    # Check if this is a new upload by comparing with previous image
    if 'previous_image_name' not in st.session_state or st.session_state.previous_image_name != uploaded_file.name:
        # Reset filters and recommendations when a new image is uploaded
        st.session_state.selected_filters = []
        if 'has_recommendations' in st.session_state:
            st.session_state.has_recommendations = False
        if 'recommendations' in st.session_state:
            del st.session_state.recommendations
        if 'shuffled_recommendations' in st.session_state:
            del st.session_state.shuffled_recommendations
        if 'shown_products' in st.session_state:
            del st.session_state.shown_products

        # Store the new image name for future comparison
        st.session_state.previous_image_name = uploaded_file.name
        
    user_image = uploaded_file.getvalue()
    st.image(user_image, caption="Uploaded Image", width=300)

# Process image and show recommendations
if user_image and st.button("Get Recommendations"):
    with st.spinner("Analyzing your style..."):
        try:
            # Get all category recommendations and save to session state
            recommendations = recommend_with_faiss(user_image, model, processor)
            st.session_state.recommendations = recommendations
            st.session_state.has_recommendations = True
            
            st.success("Analysis complete! Use the filter below to choose which categories to view")
            
        except Exception as e:
            st.error(f"Error generating recommendations: {e}")

# Display filter and recommendation results (only after recommendations are generated)
if 'has_recommendations' in st.session_state and st.session_state.has_recommendations:
    st.markdown("### Filter Recommendations")
    
    # Default to no categories selected
    if 'selected_filters' not in st.session_state:
        st.session_state.selected_filters = []
        
    selected_filters = st.multiselect(
        label="Select categories to view",
        options=available_categories,
        default=[],
        format_func=lambda x: x.title() if x.isalpha() else x
    )
    
    # Update session state with selected filters
    st.session_state.selected_filters = selected_filters
    
    # Display filtered recommendations
    st.markdown("## Your Personalized Recommendations")

    if not selected_filters:
        st.info("Please select at least one category to view recommendations")
    else:
        # Initialize shuffled recommendations and shown products tracker in session state
        if 'shuffled_recommendations' not in st.session_state:
            st.session_state.shuffled_recommendations = {}
        if 'shown_products' not in st.session_state:
            st.session_state.shown_products = {}

        # Add shuffle button
        col1, col2 = st.columns([1, 5])
        with col1:
            if st.button("🔀 Shuffle", help="Get different recommendations from the same categories"):
                # Shuffle recommendations for selected categories
                for category in selected_filters:
                    if category in st.session_state.recommendations:
                        all_products = st.session_state.recommendations[category]

                        # Initialize shown products set for this category if not exists
                        if category not in st.session_state.shown_products:
                            st.session_state.shown_products[category] = set()

                        # Get new recommendations excluding already shown ones
                        st.session_state.shuffled_recommendations[category] = get_shuffled_recommendations(
                            all_products,
                            st.session_state.shown_products[category]
                        )
                st.rerun()

        filtered_recommendations = {cat: products for cat, products in st.session_state.recommendations.items()
                                  if cat in selected_filters}

        if filtered_recommendations:
            for category, products in filtered_recommendations.items():
                st.markdown(f"### {category.title() if category.isalpha() else category} Recommendations")

                # Use shuffled recommendations if they exist, otherwise initialize with first 3
                if category in st.session_state.shuffled_recommendations:
                    display_products = st.session_state.shuffled_recommendations[category]
                else:
                    # Initialize with first 3 products and track them as shown
                    display_products = products[:3]
                    st.session_state.shuffled_recommendations[category] = display_products

                    # Initialize shown products tracker for this category
                    if category not in st.session_state.shown_products:
                        st.session_state.shown_products[category] = set()
                    st.session_state.shown_products[category].update(display_products)

                display_product_images(display_products, metadata)
                st.markdown("---")
        else:
            st.info("No recommendations available for selected categories")