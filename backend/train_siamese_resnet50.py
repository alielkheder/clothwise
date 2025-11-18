from transformers import CLIPImageProcessor, CLIPVisionModel, get_cosine_schedule_with_warmup
import zipfile
from tqdm import tqdm
from torch.utils.data import random_split
from sklearn.metrics import roc_auc_score, average_precision_score, accuracy_score
import numpy as np
import json
import pandas as pd
import torch
import torch.nn as nn
import torch.nn.functional as F
from PIL import Image
from torch.utils.data import Dataset, DataLoader
import torch
from torch.utils.data import Dataset
from PIL import Image
import pandas as pd


# --------- Model ---------
class SiameseWithProjection(nn.Module):
    def __init__(self, clip_model, projection_dim=128):
        super().__init__()
        self.clip = clip_model
        self.projector = nn.Sequential(
            nn.Linear(clip_model.config.hidden_size, projection_dim),
            nn.ReLU(),
            nn.Linear(projection_dim, projection_dim)
        )

    def forward(self, anchor, candidate):
        anchor_feat = self.clip(pixel_values=anchor).last_hidden_state[:, 0, :]
        candidate_feat = self.clip(pixel_values=candidate).last_hidden_state[:, 0, :]

        anchor_proj = self.projector(anchor_feat)
        candidate_proj = self.projector(candidate_feat)

        return anchor_proj, candidate_proj
