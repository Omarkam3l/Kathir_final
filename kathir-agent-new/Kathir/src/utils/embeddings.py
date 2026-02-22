"""
rag/embeddings.py
─────────────────
Handles:
  1. Loading the BAAI/bge-m3 SentenceTransformer model (singleton).
  2. Building text documents from meal rows for embedding.
  3. Generating embeddings in batches.
  4. Upserting embeddings back into the Supabase `meals` table.

Run this module directly to (re)embed all meals:
    python -m rag.embeddings
"""

import torch
from sentence_transformers import SentenceTransformer

from src.utils.db_client import sb

# ── Model singleton ───────────────────────────────────────────────────────────
_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
_MODEL_NAME = "BAAI/bge-m3"

_model: SentenceTransformer | None = None


def get_model() -> SentenceTransformer:
    """Lazy-load the embedding model (loaded once, reused globally)."""
    global _model
    if _model is None:
        print(f"Loading embedding model '{_MODEL_NAME}' on {_DEVICE} …")
        _model = SentenceTransformer(_MODEL_NAME, device=_DEVICE, trust_remote_code=True)
        print("Model loaded.")
    return _model


# ── Text preparation ──────────────────────────────────────────────────────────

def build_meal_text(meal: dict) -> str:
    """
    Combine all searchable meal fields into a single embedding document.
    Falls back to 'no description available' if the row is empty.
    """
    parts = [
        str(meal.get("title") or "").strip(),
        str(meal.get("description") or "").strip(),
        str(meal.get("category") or "").strip(),
        ", ".join(meal.get("ingredients") or []),
        ", ".join(meal.get("allergens") or []),
    ]
    text = " ".join(p for p in parts if p).strip()
    return text or "no description available"


# ── Embedding pipeline ────────────────────────────────────────────────────────

def fetch_meals_for_embedding() -> list[dict]:
    """Fetch all meal rows that need to be embedded."""
    response = sb.table("meals").select(
        "id, title, description, category, ingredients, allergens"
    ).execute()
    return response.data or []


def generate_embeddings(texts: list[str], batch_size: int = 16) -> list[list[float]]:
    """
    Encode a list of strings into normalized embedding vectors.
    Returns a list of plain Python lists (ready for Supabase JSON).
    """
    model = get_model()
    print(f"Generating embeddings for {len(texts)} texts …")
    embeddings = model.encode(
        texts,
        batch_size=batch_size,
        show_progress_bar=True,
        normalize_embeddings=True,  # cosine similarity works best with normalized vectors
        convert_to_numpy=True,
    )
    print(f"Done — shape: {embeddings.shape}")
    return [emb.tolist() for emb in embeddings]


def upsert_embeddings(ids: list[str], embeddings: list[list[float]]) -> int:
    """
    Write each embedding vector back to the matching meal row.
    Returns the count of successfully updated rows.
    """
    updated = 0
    for i, (meal_id, emb) in enumerate(zip(ids, embeddings)):
        result = sb.table("meals").update({"embedding": emb}).eq("id", meal_id).execute()
        if result.data:
            updated += 1
            print(f"✓ {i + 1}/{len(ids)} → {meal_id}")
        else:
            print(f"✗ Failed: {meal_id}")
    return updated


def encode_query(query: str) -> list[float]:
    """Encode a single query string into a normalized embedding vector."""
    model = get_model()
    return model.encode(query, normalize_embeddings=True).tolist()


# ── Entry point ───────────────────────────────────────────────────────────────

def run_embedding_pipeline() -> None:
    """Fetch all meals, embed them, and persist back to Supabase."""
    meals = fetch_meals_for_embedding()
    if not meals:
        print("No meals found — check your Supabase credentials or table.")
        return

    print(f"Found {len(meals)} meals.")
    texts = [build_meal_text(m) for m in meals]
    ids = [m["id"] for m in meals]

    embeddings = generate_embeddings(texts)
    count = upsert_embeddings(ids, embeddings)
    print(f"\nEmbedding pipeline complete — {count}/{len(meals)} meals updated.")


if __name__ == "__main__":
    run_embedding_pipeline()
