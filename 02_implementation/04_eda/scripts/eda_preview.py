#!/usr/bin/env python3
import argparse
from pathlib import Path
import sys

import pandas as pd

from utils_io import ensure_dir, load_csv


def parse_args():
    p = argparse.ArgumentParser(description="EDA preview: esquema, faltantes y descripciones básicas")
    p.add_argument("--csv", default="archive/games_march2025_cleaned.csv", help="Ruta al CSV cleaned")
    p.add_argument("--nrows", type=int, default=None, help="Límite de filas a leer")
    p.add_argument("--sample-frac", type=float, default=None, help="Fracción de muestreo (0-1)")
    p.add_argument("--out-tables", default="tables", help="Directorio de salida de tablas")
    return p.parse_args()


def main():
    args = parse_args()
    out_tables = Path(args.out_tables)
    ensure_dir(out_tables.as_posix())

    print(f"[EDA] Cargando CSV: {args.csv}")
    df = load_csv(args.csv, nrows=args.nrows, sample_frac=args.sample_frac)
    print(f"[EDA] Shape: {df.shape}")

    # Dtypes y esquema
    dtypes = df.dtypes.astype(str).reset_index()
    dtypes.columns = ["column", "dtype"]
    dtypes.to_csv(out_tables / "schema_dtypes.csv", index=False)
    print("[EDA] Columnas y tipos guardados en tables/schema_dtypes.csv")

    # Faltantes
    missing = (
        df.isna().sum().to_frame("missing")
        .assign(total=df.shape[0])
        .assign(pct=lambda x: (x["missing"] / x["total"]) * 100.0)
        .sort_values("pct", ascending=False)
        .reset_index()
        .rename(columns={"index": "column"})
    )
    missing.to_csv(out_tables / "missing_summary.csv", index=False)
    print("[EDA] Resumen de faltantes guardado en tables/missing_summary.csv")

    # Describe numéricos (solo columnas numéricas disponibles)
    numeric_cols = df.select_dtypes(include=["number"]).columns.tolist()
    if numeric_cols:
        desc = df[numeric_cols].describe(percentiles=[0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99]).T
        desc.to_csv(out_tables / "numeric_describe.csv")
        print("[EDA] Descripción numérica guardada en tables/numeric_describe.csv")
    else:
        print("[EDA] No se encontraron columnas numéricas para describir.")

    # Un vistazo a las primeras filas
    head_path = out_tables / "head_sample.csv"
    df.head(20).to_csv(head_path, index=False)
    print("[EDA] Muestra de encabezado guardada en tables/head_sample.csv")

    print("[EDA] Hecho.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"[EDA] Error: {e}", file=sys.stderr)
        sys.exit(1)

