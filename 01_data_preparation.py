"""
Climate Policy Fairness Analysis - Data Preparation Script
===========================================================

This script transforms raw survey data into analysis-ready formats for studying
the relationship between political ideology and perceived fairness of climate policies.

Input:  data/raw/Thesis_Data_Cleaned.xlsx
Outputs: 
  - data/processed/fairness_policies_long.csv (long format for mixed-effects)
  - data/processed/analysis_ready_wide.csv (wide format for OLS)

Author: Nadav
Date: November 2025
"""

import pandas as pd
import numpy as np
from pathlib import Path

# ============================================================================
# CONFIGURATION
# ============================================================================

# Paths
PROJECT_ROOT = Path(__file__).parent.parent
RAW_DATA_PATH = PROJECT_ROOT / 'data' / 'raw' / 'Thesis_Data_Cleaned.xlsx'
OUTPUT_LONG = PROJECT_ROOT / 'data' / 'processed' / 'fairness_policies_long.csv'
OUTPUT_WIDE = PROJECT_ROOT / 'data' / 'processed' / 'analysis_ready_wide.csv'

# Survey variable mappings
FAIRNESS_COLS = [f's_{i}' for i in range(15, 28)]  # 13 climate policy fairness questions
IDEOLOGY_COL = 's_14'  # 1-11 scale: 1=Very Liberal, 11=Very Conservative
CONSENT_COL = 's_48'   # 1=Consented to participate
DEMOGRAPHIC_COLS = {
    's_33': 'gender',
    's_32': 'education', 
    's_35': 'age_group',
    's_34': 'region'
}

# Data cleaning parameters
DONT_KNOW_VALUE = 6  # "Don't know" responses coded as 6
CONSENT_VALUE = 1.0  # Only include participants who consented

# Policy labels matching the paper
POLICY_LABELS = {
    's_15': "Road Pricing",
    's_16': "Carbon Tax",
    's_17': "Vehicle Costs (Fuel Economy Standards)",
    's_18': "Emissions Trading (Companies)",
    's_19': "Electric Vehicle Incentives",
    's_20': "Emissions Trading (Countries)",
    's_21': "Public Transportation Funding",
    's_22': "Developing Countries Support",
    's_23': "Green Bonds and Investment",
    's_24': "Plant-Based Food Initiatives",
    's_25': "Air Travel Tax",
    's_26': "Red Meat Tax",
    's_27': "Diesel Car Restrictions"
}

# Load raw data
print(f"Loading raw data from: {RAW_DATA_PATH}")
df_raw = pd.read_excel(RAW_DATA_PATH, sheet_name='Clean_Data')
print(f"Loaded {len(df_raw)} survey responses")

# Filter for consented participants
df = df_raw[df_raw[CONSENT_COL] == CONSENT_VALUE].copy()
print(f"Retained {len(df)} participants (excluded {len(df_raw) - len(df)} non-consenting)")

# Create respondent IDs
df['respondent_id'] = range(1, len(df) + 1)

# Clean fairness responses: replace "Don't know" (6) with NaN
dont_know_total = sum((df[col] == DONT_KNOW_VALUE).sum() for col in FAIRNESS_COLS)
for col in FAIRNESS_COLS:
    df[col] = df[col].replace(DONT_KNOW_VALUE, np.nan)
print(f"Replaced {dont_know_total} 'Don't know' responses with NaN")

# Calculate average fairness per participant
df['avg_fairness'] = df[FAIRNESS_COLS].mean(axis=1)
print(f"Average fairness: M={df['avg_fairness'].mean():.2f}, SD={df['avg_fairness'].std():.2f}")

# Rename demographic variables
df_wide = df.copy()
df_wide = df_wide.rename(columns=DEMOGRAPHIC_COLS)
df_wide = df_wide.rename(columns={IDEOLOGY_COL: 'ideology'})

# Transform to long format for mixed-effects models

# Melt fairness columns to long format
df_long = df.melt(
    id_vars=['respondent_id', IDEOLOGY_COL] + list(DEMOGRAPHIC_COLS.keys()),
    value_vars=FAIRNESS_COLS,
    var_name='policy_code',
    value_name='fairness'
)

# Add policy labels
df_long['policy_label'] = df_long['policy_code'].map(POLICY_LABELS)

# Rename columns for clarity
df_long = df_long.rename(columns=DEMOGRAPHIC_COLS)
df_long = df_long.rename(columns={IDEOLOGY_COL: 'ideology'})

# Remove missing fairness responses (from "Don't know")
n_before_drop = len(df_long)
df_long = df_long.dropna(subset=['fairness'])
print(f"Long format: {len(df_long)} observations ({df_long['respondent_id'].nunique()} participants)")

# Data quality checks
assert df_long['ideology'].notna().all(), "Missing ideology values"
assert df_long['ideology'].between(1, 11).all(), "Ideology out of range"
assert df_long['fairness'].between(1, 5).all(), "Fairness out of range"
assert not df_long.duplicated(subset=['respondent_id', 'policy_code']).any(), "Duplicate observations"

# Save processed data
df_long.to_csv(OUTPUT_LONG, index=False)
print(f"Saved: {OUTPUT_LONG}")

wide_cols = ['respondent_id', 'ideology', 'avg_fairness', 
             'gender', 'education', 'age_group', 'region'] + FAIRNESS_COLS
df_wide_export = df_wide[wide_cols]
df_wide_export.to_csv(OUTPUT_WIDE, index=False)
print(f"Saved: {OUTPUT_WIDE}")

print(f"\nDone. {len(df_long)} observations, {len(df_wide_export)} participants.")
