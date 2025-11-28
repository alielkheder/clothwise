"""
Training script for fine-tuning CLIP on clothing style classification
Trains on GPU for casual, formal, and semi-formal classification
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler
import clip
from PIL import Image
import json
import os
import numpy as np
from tqdm import tqdm
import random
from collections import Counter
import torchvision.transforms as transforms


class ClothingStyleDataset(Dataset):
    """Dataset for clothing style classification"""

    def __init__(self, image_paths, labels, preprocess, augment=False):
        """
        Args:
            image_paths: List of image file paths
            labels: List of labels (0=casual, 1=uniform/formal, 2=semi_uniform)
            preprocess: CLIP preprocessing function
            augment: Whether to apply data augmentation
        """
        self.image_paths = image_paths
        self.labels = labels
        self.preprocess = preprocess
        self.augment = augment

        # Data augmentation transforms
        if augment:
            self.augment_transform = transforms.Compose([
                transforms.RandomHorizontalFlip(p=0.5),
                transforms.RandomRotation(degrees=15),
                transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
                transforms.RandomResizedCrop(224, scale=(0.8, 1.0)),
            ])

    def __len__(self):
        return len(self.image_paths)

    def __getitem__(self, idx):
        image_path = self.image_paths[idx]
        label = self.labels[idx]

        try:
            # Load image
            image = Image.open(image_path).convert('RGB')

            # Apply augmentation if enabled
            if self.augment:
                image = self.augment_transform(image)

            # Apply CLIP preprocessing
            image = self.preprocess(image)

            return image, label
        except Exception as e:
            print(f"Error loading {image_path}: {e}")
            # Return a blank image with label
            blank_image = Image.new('RGB', (224, 224), color='white')
            return self.preprocess(blank_image), label


def prepare_dataset(metadata_path='product_metadata.json'):
    """
    Prepare training, validation, and test datasets

    Returns:
        Tuple of (train_data, val_data, test_data, class_counts)
    """
    print("Loading product metadata...")
    with open(metadata_path, 'r') as f:
        products = json.load(f)

    # Map style types to numeric labels
    label_mapping = {
        'casual': 0,
        'uniform': 1,
        'semi_uniform': 2
    }

    # Collect all valid image-label pairs
    image_paths = []
    labels = []

    for product_name, product_data in products.items():
        image_id = product_data.get('image', '')
        style_type = product_data.get('style_type', 'casual')

        if image_id and style_type in label_mapping:
            image_path = image_id  # Already includes data/ prefix
            if os.path.exists(image_path):
                image_paths.append(image_path)
                labels.append(label_mapping[style_type])

    print(f"Found {len(image_paths)} valid images")

    # Count class distribution
    class_counts = Counter(labels)
    print(f"Class distribution:")
    print(f"  Casual: {class_counts[0]} ({class_counts[0]/len(labels)*100:.1f}%)")
    print(f"  Formal: {class_counts[1]} ({class_counts[1]/len(labels)*100:.1f}%)")
    print(f"  Semi-formal: {class_counts[2]} ({class_counts[2]/len(labels)*100:.1f}%)")

    # Shuffle data
    combined = list(zip(image_paths, labels))
    random.shuffle(combined)
    image_paths, labels = zip(*combined)
    image_paths = list(image_paths)
    labels = list(labels)

    # Split into train (80%), val (10%), test (10%)
    n = len(image_paths)
    train_size = int(0.8 * n)
    val_size = int(0.1 * n)

    train_images = image_paths[:train_size]
    train_labels = labels[:train_size]

    val_images = image_paths[train_size:train_size + val_size]
    val_labels = labels[train_size:train_size + val_size]

    test_images = image_paths[train_size + val_size:]
    test_labels = labels[train_size + val_size:]

    print(f"\nDataset splits:")
    print(f"  Train: {len(train_images)} images")
    print(f"  Val:   {len(val_images)} images")
    print(f"  Test:  {len(test_images)} images")

    return (train_images, train_labels), (val_images, val_labels), (test_images, test_labels), class_counts


def get_weighted_sampler(labels, class_counts):
    """
    Create weighted sampler to balance classes during training

    Args:
        labels: List of labels
        class_counts: Counter object with class distribution

    Returns:
        WeightedRandomSampler
    """
    # Calculate weights for each class (inverse of frequency)
    total = sum(class_counts.values())
    class_weights = {cls: total / count for cls, count in class_counts.items()}

    # Assign weight to each sample
    sample_weights = [class_weights[label] for label in labels]

    sampler = WeightedRandomSampler(
        weights=sample_weights,
        num_samples=len(sample_weights),
        replacement=True
    )

    return sampler


def train_model(num_epochs=10, batch_size=32, learning_rate=1e-5, save_path='clip_style_classifier.pth'):
    """
    Train CLIP model for clothing style classification

    Args:
        num_epochs: Number of training epochs
        batch_size: Batch size for training
        learning_rate: Learning rate
        save_path: Path to save best model
    """
    # Set device
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"\nUsing device: {device}")

    if device == "cuda":
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")

    # Load CLIP model
    print("\nLoading CLIP model...")
    model, preprocess = clip.load("ViT-B/32", device=device)

    # Prepare datasets
    (train_images, train_labels), (val_images, val_labels), (test_images, test_labels), class_counts = prepare_dataset()

    # Create datasets
    train_dataset = ClothingStyleDataset(train_images, train_labels, preprocess, augment=True)
    val_dataset = ClothingStyleDataset(val_images, val_labels, preprocess, augment=False)
    test_dataset = ClothingStyleDataset(test_images, test_labels, preprocess, augment=False)

    # Create weighted sampler for balanced training
    train_sampler = get_weighted_sampler(train_labels, class_counts)

    # Create data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, sampler=train_sampler, num_workers=0)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False, num_workers=0)

    # Create classification head
    # We'll train a linear layer on top of CLIP image features
    feature_dim = 512  # CLIP ViT-B/32 output dimension
    num_classes = 3

    classifier_head = nn.Linear(feature_dim, num_classes).to(device)

    # COMPLETELY FREEZE CLIP - only train classifier head
    # This is more stable and prevents model collapse
    for param in model.parameters():
        param.requires_grad = False

    # Simple optimizer and loss WITHOUT class weights
    # Let the model learn naturally without forcing it
    optimizer = optim.Adam(classifier_head.parameters(), lr=learning_rate)
    criterion = nn.CrossEntropyLoss()  # No class weights

    # Learning rate scheduler - reduce LR when validation plateaus
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(
        optimizer, mode='max', factor=0.5, patience=2, verbose=True
    )

    # Training loop
    best_val_acc = 0.0
    train_losses = []
    val_accuracies = []

    print(f"\n{'='*60}")
    print(f"Starting training for {num_epochs} epochs")
    print(f"{'='*60}\n")

    for epoch in range(num_epochs):
        # Training phase
        model.eval()  # Keep CLIP in eval mode
        classifier_head.train()

        train_loss = 0.0
        train_correct = 0
        train_total = 0

        progress_bar = tqdm(train_loader, desc=f"Epoch {epoch+1}/{num_epochs} [Train]")

        for images, labels in progress_bar:
            images = images.to(device)
            labels = labels.to(device)

            # Get CLIP features
            with torch.no_grad():
                image_features = model.encode_image(images)
                image_features = image_features.float()

            # Forward pass through classifier
            outputs = classifier_head(image_features)
            loss = criterion(outputs, labels)

            # Backward pass
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            # Statistics
            train_loss += loss.item()
            _, predicted = outputs.max(1)
            train_total += labels.size(0)
            train_correct += predicted.eq(labels).sum().item()

            # Update progress bar
            progress_bar.set_postfix({
                'loss': f'{loss.item():.4f}',
                'acc': f'{100.*train_correct/train_total:.2f}%'
            })

        avg_train_loss = train_loss / len(train_loader)
        train_acc = 100. * train_correct / train_total
        train_losses.append(avg_train_loss)

        # Validation phase
        classifier_head.eval()
        val_correct = 0
        val_total = 0
        class_correct = [0, 0, 0]
        class_total = [0, 0, 0]

        with torch.no_grad():
            for images, labels in tqdm(val_loader, desc=f"Epoch {epoch+1}/{num_epochs} [Val]  "):
                images = images.to(device)
                labels = labels.to(device)

                # Get CLIP features and classify
                image_features = model.encode_image(images)
                image_features = image_features.float()
                outputs = classifier_head(image_features)

                _, predicted = outputs.max(1)
                val_total += labels.size(0)
                val_correct += predicted.eq(labels).sum().item()

                # Per-class accuracy
                for i in range(len(labels)):
                    label = labels[i].item()
                    class_total[label] += 1
                    if predicted[i] == labels[i]:
                        class_correct[label] += 1

        val_acc = 100. * val_correct / val_total
        val_accuracies.append(val_acc)

        # Per-class accuracies
        casual_acc = 100. * class_correct[0] / class_total[0] if class_total[0] > 0 else 0
        formal_acc = 100. * class_correct[1] / class_total[1] if class_total[1] > 0 else 0
        semi_acc = 100. * class_correct[2] / class_total[2] if class_total[2] > 0 else 0

        print(f"\nEpoch {epoch+1}/{num_epochs}")
        print(f"  Train Loss: {avg_train_loss:.4f} | Train Acc: {train_acc:.2f}%")
        print(f"  Val Acc: {val_acc:.2f}%")
        print(f"  Per-class: Casual {casual_acc:.1f}% | Formal {formal_acc:.1f}% | Semi-formal {semi_acc:.1f}%")

        # Update learning rate based on validation accuracy
        scheduler.step(val_acc)

        # Save best model
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            print(f"  [NEW BEST] Saving model to {save_path}")

            # Save both CLIP and classifier
            torch.save({
                'epoch': epoch,
                'model_state_dict': model.state_dict(),
                'classifier_state_dict': classifier_head.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_acc': val_acc,
                'class_accuracies': {
                    'casual': casual_acc,
                    'formal': formal_acc,
                    'semi_formal': semi_acc
                }
            }, save_path)

        print()

    # Final test evaluation
    print(f"\n{'='*60}")
    print("Final Test Evaluation")
    print(f"{'='*60}\n")

    classifier_head.eval()
    test_correct = 0
    test_total = 0
    class_correct = [0, 0, 0]
    class_total = [0, 0, 0]

    with torch.no_grad():
        for images, labels in tqdm(test_loader, desc="Testing"):
            images = images.to(device)
            labels = labels.to(device)

            image_features = model.encode_image(images)
            image_features = image_features.float()
            outputs = classifier_head(image_features)

            _, predicted = outputs.max(1)
            test_total += labels.size(0)
            test_correct += predicted.eq(labels).sum().item()

            for i in range(len(labels)):
                label = labels[i].item()
                class_total[label] += 1
                if predicted[i] == labels[i]:
                    class_correct[label] += 1

    test_acc = 100. * test_correct / test_total
    casual_acc = 100. * class_correct[0] / class_total[0] if class_total[0] > 0 else 0
    formal_acc = 100. * class_correct[1] / class_total[1] if class_total[1] > 0 else 0
    semi_acc = 100. * class_correct[2] / class_total[2] if class_total[2] > 0 else 0

    print(f"\nTest Accuracy: {test_acc:.2f}%")
    print(f"Per-class accuracy:")
    print(f"  Casual:      {casual_acc:.2f}%")
    print(f"  Formal:      {formal_acc:.2f}%")
    print(f"  Semi-formal: {semi_acc:.2f}%")
    print(f"\nBest validation accuracy: {best_val_acc:.2f}%")
    print(f"Model saved to: {save_path}")


if __name__ == "__main__":
    # Set random seeds for reproducibility
    random.seed(42)
    np.random.seed(42)
    torch.manual_seed(42)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(42)

    # Train the model with simple approach - frozen CLIP, no class weights
    train_model(
        num_epochs=10,  # Shorter training since we're only training classifier head
        batch_size=64,
        learning_rate=5e-4,  # Higher LR for faster convergence with frozen features
        save_path='clip_style_classifier_simple.pth'
    )
