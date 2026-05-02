# Climate Policy Fairness Analysis

## Overview

This repository contains a complete, reproducible analysis pipeline for studying the relationship between political ideology and perceived fairness of climate policies in Denmark. The analysis supports the paper **"Attitudes Toward Climate Policies in Denmark: Ideological Divides and the Role of Perceived Fairness"**.

### Research Question
How does political ideology shape fairness perceptions of climate mitigation policies in a high-trust context where climate change denial is rare?

### Key Findings
- **94.87%** of Danish respondents believe climate change is happening
- **61.53%** see it as a serious threat in their lifetime
- Belief in climate change doesn't vary by ideology, BUT **perceived fairness of policies does**
- Liberals consistently rate climate policies as fairer than conservatives
- Market-based solutions (emissions trading, EV incentives) show less ideological disagreement

---

## Repository Structure

```
climate-fairness-analysis/
├── README.md
├── data/
│   ├── raw/
│   │   └── Thesis_Data_Cleaned.xlsx   # Original survey data (N=312)
│   ├── processed/
│   │   ├── fairness_policies_long.csv # Long format for mixed-effects
│   │   └── analysis_ready_wide.csv    # Wide format for descriptives
│   └── DATA_DICTIONARY.md             # Variable reference
├── scripts/
│   ├── 01_data_preparation.py         # Transform raw data to analysis format
│   └── 02_mixed_effects_analysis.R    # Mixed-effects model
└── outputs/
    ├── models/
    │   ├── ols_summary.txt
    │   └── mixed_model_summary.txt
    ├── tables/
    │   └── policy_slopes_from_mixed_model.csv
    └── figures/
        ├── slope_lines_most_divisive.png
        └── slope_lines_least_divisive.png
```

---

## Quick Start

### Prerequisites

**Python 3.8+**
```bash
pip install pandas numpy openpyxl
```

**R 4.0+**
```r
install.packages(c("tidyverse", "lme4", "broom.mixed", "viridis", "here"))
```

### Running the Analysis

**Step 1: Data Preparation (Python)**
```bash
cd climate-fairness-analysis
python scripts/01_data_preparation.py
```

**Step 2: Statistical Analysis (R)**
```r
source("scripts/02_mixed_effects_analysis.R")
```

Outputs are saved to `outputs/`.

---

## Key Results

### Mixed-Effects Model

The main analysis uses a linear mixed-effects model:

```
fairness ~ ideology * policy + (1 | participant_id)
```

**Model fit:** AIC = 10,235, BIC = 10,409, N = 3,727 observations from 312 participants

**Random effects:** Participant intercept SD = 0.63 (substantial individual differences in baseline fairness ratings)

**Baseline ideology effect:** β = −0.14 (p < .001)

### Policy-Specific Slopes

Each policy has a slope representing the change in fairness rating per 1-point increase in conservatism:

| Policy | Slope | Interpretation |
|--------|-------|----------------|
| Red Meat Tax | −0.18 | Most polarizing |
| Road Pricing | −0.17 | Highly polarizing |
| Diesel Car Restrictions | −0.17 | Highly polarizing |
| Emissions Trading (Companies) | +0.00 | No ideological divide |
| Emissions Trading (Countries) | −0.01 | No ideological divide |

Full results: [`outputs/tables/policy_slopes_from_mixed_model.csv`](outputs/tables/policy_slopes_from_mixed_model.csv)

Model output: [`outputs/models/mixed_model_summary.txt`](outputs/models/mixed_model_summary.txt)

---

## Data Description

### Raw Data (`Thesis_Data_Cleaned.xlsx`)

**Sample:** N = 312 Danish adults (Norstat panel, 2025)

**Key Variables:**
- `s_14`: Political ideology (1 = Very Liberal, 11 = Very Conservative)
- `s_15` to `s_27`: Fairness ratings for 13 climate policies (1-5 scale, 6 = "Don't know")
- `s_33`: Gender
- `s_32`: Education level
- `s_35`: Age group
- `s_34`: Region
- `s_48`: Consent (1 = Yes)

### Climate Policies (s_15 to s_27)

| Variable | Policy Description |
|----------|-------------------|
| s_15 | Road Pricing (Pay-per-km) |
| s_16 | Carbon Tax |
| s_17 | Vehicle Costs (Fuel Economy Standards) |
| s_18 | Emissions Trading System (Companies) |
| s_19 | Electric Vehicle Incentives |
| s_20 | Emissions Trading System (Countries) |
| s_21 | Public Transportation Funding |
| s_22 | Developing Countries Support |
| s_23 | Green Bonds and Investment |
| s_24 | Plant-Based Food Initiatives |
| s_25 | Air Travel Tax |
| s_26 | Red Meat Tax |
| s_27 | Diesel Car Restrictions |

### Data Cleaning Steps

1. **Filter for consent:** Retain only participants with `s_48 == 1` (N = 312)
2. **Handle "Don't know" responses:** Replace value `6` with `NaN` (329 responses)
   - **Critical:** Including 6 as numeric inflates fairness scores by ~0.22 points!
3. **Calculate average fairness:** Mean across 13 policies (excluding NaN)
4. **Create long format:** Melt policies into observations for mixed-effects modeling

---

## Statistical Methods

### 1. OLS Regression (Participant-Level)

**Model:**
```
avg_fairness ~ ideology
```

**Purpose:** Estimate overall effect of ideology on average fairness perceptions

**Key Result:**
- Each 1-point increase in conservatism → **~0.09 point decrease** in average fairness
- R² ≈ 0.13

### 2. Mixed-Effects Model (Observation-Level)

**Model:**
```
fairness ~ ideology * policy + (1 | participant_id)
```

**Components:**
- **Fixed effects:** Ideology, policy type, and their interaction
- **Random effects:** Random intercepts for participants (accounts for within-person correlation)
- **Baseline:** Air Travel Tax (neutral policy)

**Purpose:**
- Estimate policy-specific ideology slopes
- Test whether ideological divides vary by policy type

**Key Result:**
- Strong ideology × policy interactions
- Taxes on lifestyle (meat, travel) most divisive
- Market mechanisms (ETS) least divisive

---

## Interpretation Guide

### Policy-Specific Slopes

Each policy has a slope representing the **change in fairness rating per 1-point increase in conservatism**:

- **Negative slope:** Conservatives rate policy as less fair
- **Zero slope:** No ideological difference
- **Large absolute slope:** Strong ideological divide

**Example:**
- Red Meat Tax: slope = **-0.15** → Very divisive
- Emissions Trading (Companies): slope = **-0.02** → Low disagreement

---

## Output Files

### `ols_summary.txt`
- Full OLS regression results
- Coefficients, standard errors, p-values, R²

### `mixed_model_summary.txt`
- Full mixed-effects model output
- Fixed effects, random effects, model fit statistics

### `policy_slopes_from_mixed_model.csv`

| Column | Description |
|--------|-------------|
| policy | Policy name |
| intercept | Predicted fairness for liberals (ideology=1) |
| slope | Change in fairness per 1-point increase in conservatism |
| abs_slope | Absolute value of slope (for ranking divisiveness) |

### `predicted_fairness_by_ideology.csv`

| Column | Description |
|--------|-------------|
| policy | Policy name |
| ideology | Ideology level (1-11) |
| pred_fairness | Predicted fairness rating |

---

## Visualizations

### `slope_lines_most_divisive.png`
Shows the 6 policies with the **steepest negative slopes** (largest ideological gaps)

### `slope_lines_least_divisive.png`
Shows the 6 policies with the **flattest slopes** (smallest ideological gaps)

**Interpretation:**
- Steeper downward lines → Greater liberal-conservative divide
- Flatter lines → Cross-ideological consensus

---

## Reproducing the Paper Results

### Table 1: Fairness by Policy and Ideology
```r
# After running 02_mixed_effects_analysis.R
library(tidyverse)
results <- read_csv("outputs/tables/policy_slopes_from_mixed_model.csv")
results %>% arrange(desc(abs_slope))
```

### Figure X: Ideological Divides
The generated PNG files in `outputs/figures/` are publication-ready.

### Regression Coefficients
See `outputs/models/ols_summary.txt` and `outputs/models/mixed_model_summary.txt`

---

## Important Notes

### "Don't Know" Handling

The value `6` represents "I don't know" and must be treated as missing data, not as a numeric fairness rating. Including 6 inflates average fairness by ~0.22 points. Our approach: replace `6` with `NaN` before analysis.

---

## Theoretical Framework

### Solution Aversion (Campbell & Kay, 2014)
People may deny or downplay problems not because they dispute evidence, but because they oppose the proposed solutions.

**Finding:** In Denmark, resistance stems less from climate denial and more from perceived threats in policy solutions.

### Identity-Protective Cognition (Kahan et al., 2007)
Individuals process information to align with their ideological group's beliefs, even when it conflicts with scientific evidence.

**Finding:** Conservatives acknowledge climate change but perceive lifestyle-restricting policies as unfair (identity threat).

---

## License

This project is licensed for academic use.
