#!/usr/bin/env python3
import argparse
from pathlib import Path
import sys

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from utils_io import ensure_dir, load_csv, explode_and_count


def parse_args():
    p = argparse.ArgumentParser(description="EDA plots: distribuciones, top categorías y correlaciones")
    p.add_argument("--csv", default="archive/games_march2025_cleaned.csv", help="Ruta al CSV cleaned")
    p.add_argument("--nrows", type=int, default=None, help="Límite de filas a leer")
    p.add_argument("--sample-frac", type=float, default=None, help="Fracción de muestreo (0-1)")
    p.add_argument("--out-figures", default="figures", help="Directorio de salida de figuras")
    p.add_argument("--topn", type=int, default=20, help="Top N para géneros/categorías")
    return p.parse_args()


def save_hist(df: pd.DataFrame, col: str, out: Path, bins: int = 50, logx: bool = False):
    if col not in df.columns:
        return
    series = pd.to_numeric(df[col], errors="coerce").dropna()
    if series.empty:
        return
    plt.figure(figsize=(8, 5))
    sns.histplot(series, bins=bins, kde=False)
    if logx:
        plt.xscale("log")
    plt.title(f"Distribución de {col}")
    plt.xlabel(col)
    plt.ylabel("Frecuencia")
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()


def save_bars(counts: pd.Series, title: str, out: Path):
    if counts is None or counts.empty:
        return
    plt.figure(figsize=(10, 6))
    sns.barplot(x=counts.values, y=counts.index, orient="h")
    plt.title(title)
    plt.xlabel("Conteo")
    plt.ylabel("")
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()


def save_corr_heatmap(df: pd.DataFrame, cols: list, out: Path):
    available = [c for c in cols if c in df.columns]
    if not available:
        return
    sdf = df[available].apply(pd.to_numeric, errors="coerce")
    if sdf.dropna(how="all").empty:
        return
    corr = sdf.corr(numeric_only=True)
    plt.figure(figsize=(10, 8))
    sns.heatmap(corr, cmap="coolwarm", annot=False, linewidths=0.5)
    plt.title("Matriz de correlación")
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()


def main():
    args = parse_args()
    out_dir = Path(args.out_figures)
    ensure_dir(out_dir.as_posix())

    print(f"[EDA] Cargando CSV: {args.csv}")
    df = load_csv(args.csv, nrows=args.nrows, sample_frac=args.sample_frac)
    print(f"[EDA] Shape: {df.shape}")

    # Histogramas básicos
    save_hist(df, "price", out_dir / "fig_prices_hist.png", bins=60)
    save_hist(df, "discount", out_dir / "fig_discount_hist.png", bins=50)
    save_hist(df, "user_score", out_dir / "fig_user_score_hist.png", bins=50)
    save_hist(df, "peak_ccu", out_dir / "fig_peak_ccu_hist.png", bins=60, logx=True)

    # Top géneros y categorías
    top_genres = explode_and_count(df, "genres", top_n=args.topn)
    save_bars(top_genres, f"Top {args.topn} géneros", out_dir / "fig_top_genres.png")

    top_categories = explode_and_count(df, "categories", top_n=args.topn)
    save_bars(top_categories, f"Top {args.topn} categorías", out_dir / "fig_top_categories.png")

    # Correlaciones (selección razonable de columnas numéricas)
    corr_cols = [
        "price",
        "user_score",
        "positive",
        "negative",
        "pct_pos_total",
        "num_reviews_total",
        "pct_pos_recent",
        "num_reviews_recent",
        "peak_ccu",
        "estimated_owners",
        "discount",
        "average_playtime_forever",
        "median_playtime_forever",
    ]
    save_corr_heatmap(df, corr_cols, out_dir / "fig_corr_heatmap.png")

    print(f"[EDA] Figuras guardadas en: {out_dir}")
    print("[EDA] Hecho.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"[EDA] Error: {e}", file=sys.stderr)
        sys.exit(1)

