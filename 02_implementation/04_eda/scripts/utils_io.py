import os
import ast
from typing import List, Optional

import pandas as pd


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def parse_list_str(x):
    """Parse a Python-like list stored as string, else return as-is/None.
    Examples:
      "['Action', 'Indie']" -> ['Action','Indie']
      "[]" -> []
      None/NaN -> []
    """
    if pd.isna(x):
        return []
    if isinstance(x, (list, tuple)):
        return list(x)
    if isinstance(x, str):
        s = x.strip()
        # Accept JSON-like or Python-like; try literal_eval first
        try:
            val = ast.literal_eval(s)
            if isinstance(val, (list, tuple)):
                return list(val)
        except Exception:
            pass
        # Fallback: split by comma if it looks like a simple list
        if s.startswith('[') and s.endswith(']'):
            inner = s[1:-1].strip()
            if inner:
                return [t.strip().strip("'\"") for t in inner.split(',')]
            return []
        # Otherwise return original string wrapped
        return [s]
    return [x]


def load_csv(
    csv_path: str,
    nrows: Optional[int] = None,
    sample_frac: Optional[float] = None,
    random_state: int = 42,
) -> pd.DataFrame:
    """Load CSV with reasonable defaults and optional sampling.

    - If sample_frac provided, sample after initial read (preserving dtypes).
    - Caller can limit nrows to speed up initial EDA on large files.
    """
    df = pd.read_csv(csv_path, nrows=nrows, low_memory=False)
    if sample_frac is not None and 0 < sample_frac < 1.0:
        df = df.sample(frac=sample_frac, random_state=random_state)
    return df


def explode_and_count(df: pd.DataFrame, col: str, top_n: int = 20) -> pd.Series:
    """Parse list-like column, explode and count top values.
    Returns a Series indexed by value with counts.
    """
    if col not in df.columns:
        return pd.Series(dtype=int)
    parsed = df[col].apply(parse_list_str)
    exploded = parsed.explode()
    exploded = exploded.dropna()
    counts = exploded.value_counts().head(top_n)
    return counts

