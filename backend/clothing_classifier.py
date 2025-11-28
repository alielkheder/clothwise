"""
CLIP-based Clothing Style Classifier
Classifies clothing images into: casual, uniform (formal), semi_uniform (semi-formal)
"""

import torch
import clip
from PIL import Image
import numpy as np
from typing import Tuple, Union
import io


class ClothingStyleClassifier:
    """
    Clothing style classifier using CLIP model
    Supports both zero-shot and fine-tuned classification
    """

    def __init__(self, model_path=None, device=None):
        """
        Initialize the classifier

        Args:
            model_path: Path to fine-tuned model checkpoint (optional)
            device: Device to run on ('cuda' or 'cpu'). Auto-detects if None
        """
        if device is None:
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
        else:
            self.device = device

        print(f"Loading CLIP model on {self.device}...")

        # Load CLIP model
        self.model, self.preprocess = clip.load("ViT-B/32", device=self.device)

        # Load fine-tuned weights if provided
        if model_path:
            print(f"Loading fine-tuned weights from {model_path}")
            checkpoint = torch.load(model_path, map_location=self.device)
            self.model.load_state_dict(checkpoint['model_state_dict'])

        self.model.eval()

        # Enhanced text prompts for zero-shot classification
        self.text_prompts = [
            "a photo of casual everyday clothing including t-shirts, jeans, hoodies, sneakers, and relaxed comfortable wear",
            "a photo of formal business professional attire including suits, blazers, dress shirts, ties, dress pants, and formal shoes",
            "a photo of smart casual semi-formal clothing including polo shirts, button-downs, chinos, cardigans, and loafers"
        ]

        # Class names mapping
        self.class_names = ['casual', 'uniform', 'semi_uniform']
        self.display_names = {
            'casual': 'Casual',
            'uniform': 'Formal',
            'semi_uniform': 'Semi-formal'
        }

        # Encode text prompts once for efficiency
        print("Encoding text prompts...")
        text_tokens = clip.tokenize(self.text_prompts).to(self.device)
        with torch.no_grad():
            self.text_features = self.model.encode_text(text_tokens)
            self.text_features /= self.text_features.norm(dim=-1, keepdim=True)

        print("Classifier ready!")

    def classify_image(self, image_path: str) -> Tuple[str, float]:
        """
        Classify clothing image from file path

        Args:
            image_path: Path to image file

        Returns:
            Tuple of (class_name, confidence_score)
            class_name: 'casual', 'uniform', or 'semi_uniform'
            confidence_score: 0.0 to 1.0
        """
        try:
            # Load and preprocess image
            image = Image.open(image_path).convert('RGB')
            return self._classify_pil_image(image)
        except Exception as e:
            print(f"Error classifying image {image_path}: {e}")
            return 'casual', 0.0

    def classify_from_bytes(self, image_bytes: bytes) -> Tuple[str, float]:
        """
        Classify clothing image from bytes (for user uploads)

        Args:
            image_bytes: Image data as bytes

        Returns:
            Tuple of (class_name, confidence_score)
        """
        try:
            image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
            return self._classify_pil_image(image)
        except Exception as e:
            print(f"Error classifying image from bytes: {e}")
            return 'casual', 0.0

    def _classify_pil_image(self, image: Image.Image) -> Tuple[str, float]:
        """
        Internal method to classify PIL Image

        Args:
            image: PIL Image object

        Returns:
            Tuple of (class_name, confidence_score)
        """
        # Preprocess image
        image_input = self.preprocess(image).unsqueeze(0).to(self.device)

        # Get image features
        with torch.no_grad():
            image_features = self.model.encode_image(image_input)
            image_features /= image_features.norm(dim=-1, keepdim=True)

            # Calculate similarity with text prompts
            similarity = (100.0 * image_features @ self.text_features.T).softmax(dim=-1)

            # Get top prediction
            confidence, predicted_idx = similarity[0].topk(1)

            predicted_class = self.class_names[predicted_idx.item()]
            confidence_score = confidence.item()

        return predicted_class, confidence_score

    def classify_batch(self, image_paths: list) -> list:
        """
        Classify multiple images in batch (more efficient)

        Args:
            image_paths: List of image file paths

        Returns:
            List of tuples (class_name, confidence_score)
        """
        results = []

        # Process in batches of 32
        batch_size = 32
        for i in range(0, len(image_paths), batch_size):
            batch_paths = image_paths[i:i + batch_size]

            # Load and preprocess images
            images = []
            valid_indices = []
            for idx, path in enumerate(batch_paths):
                try:
                    image = Image.open(path).convert('RGB')
                    images.append(self.preprocess(image))
                    valid_indices.append(idx)
                except Exception as e:
                    print(f"Error loading {path}: {e}")
                    results.append(('casual', 0.0))

            if not images:
                continue

            # Stack images into batch
            image_batch = torch.stack(images).to(self.device)

            # Get predictions
            with torch.no_grad():
                image_features = self.model.encode_image(image_batch)
                image_features /= image_features.norm(dim=-1, keepdim=True)

                # Calculate similarity
                similarity = (100.0 * image_features @ self.text_features.T).softmax(dim=-1)

                # Get predictions for each image
                for j, sim in enumerate(similarity):
                    confidence, predicted_idx = sim.topk(1)
                    predicted_class = self.class_names[predicted_idx.item()]
                    confidence_score = confidence.item()
                    results.append((predicted_class, confidence_score))

        return results

    def get_display_name(self, class_name: str) -> str:
        """
        Get human-readable display name for class

        Args:
            class_name: Internal class name ('casual', 'uniform', 'semi_uniform')

        Returns:
            Display name ('Casual', 'Formal', 'Semi-formal')
        """
        return self.display_names.get(class_name, class_name)


def test_classifier():
    """Test the classifier on sample images"""
    print("=" * 50)
    print("Testing Clothing Style Classifier")
    print("=" * 50)

    classifier = ClothingStyleClassifier()

    # Test on a few sample images
    import os
    import json

    # Load product metadata
    with open('product_metadata.json', 'r') as f:
        products = json.load(f)

    # Test on 10 random products from each category
    test_samples = []
    for product_name, product_data in list(products.items())[:30]:
        image_id = product_data.get('image', '')
        if image_id:
            image_path = image_id  # Already includes data/ prefix
            if os.path.exists(image_path):
                actual_class = product_data.get('style_type', 'unknown')
                test_samples.append((image_path, product_name, actual_class))

    print(f"\nTesting on {len(test_samples)} sample images...\n")

    correct = 0
    for image_path, product_name, actual_class in test_samples:
        predicted_class, confidence = classifier.classify_image(image_path)
        is_correct = predicted_class == actual_class
        if is_correct:
            correct += 1

        status = "[CORRECT]" if is_correct else "[WRONG]  "
        print(f"{status} {product_name[:50]:50s} | Actual: {actual_class:12s} | Predicted: {predicted_class:12s} | Confidence: {confidence:.2%}")

    accuracy = correct / len(test_samples) if test_samples else 0
    print(f"\n{'=' * 50}")
    print(f"Accuracy: {accuracy:.2%} ({correct}/{len(test_samples)})")
    print(f"{'=' * 50}")


if __name__ == "__main__":
    test_classifier()
