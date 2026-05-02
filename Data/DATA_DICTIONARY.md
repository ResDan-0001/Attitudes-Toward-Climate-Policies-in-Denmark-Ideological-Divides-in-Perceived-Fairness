# Data Dictionary - Climate Policy Fairness Analysis

## Overview
This document provides detailed information about all variables in the climate policy fairness dataset.

**Data Source:** Norstat panel survey of Danish adults  
**Survey Year:** 2025  
**Sample Size:** N = 312 (after consent filtering)

---

## Raw Data File
**Filename:** `data/raw/Thesis_Data_Cleaned.xlsx`  
**Sheet:** `Clean_Data`

---

## Variable Reference

### Participant Identifiers

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `respondent_id` | Integer | Unique participant identifier | 1-312 |

---

### Primary Variables

#### Political Ideology

| Variable | Type | Description | Values | Notes |
|----------|------|-------------|--------|-------|
| `s_14` | Integer | Political self-placement | 1-11 | 1 = Very Liberal, 11 = Very Conservative |
| `ideology` | Integer | (Renamed from s_14 in processed data) | 1-11 | Same as s_14 |

#### Fairness Perceptions (13 Climate Policies)

**Scale:** 1-5 Likert scale + 6 for "Don't know"
- 1 = Very Unfair
- 2 = Somewhat Unfair
- 3 = Neither Fair nor Unfair
- 4 = Somewhat Fair
- 5 = Highly Fair
- 6 = I don't know (**treated as missing data in analysis**)

| Variable | Policy Description | Policy Type |
|----------|-------------------|-------------|
| `s_15` | Road Pricing (pay-per-kilometer traveled) | Usage fee |
| `s_16` | Carbon Tax | Tax |
| `s_17` | Vehicle Costs (fuel economy standards) | Regulation |
| `s_18` | Emissions Trading System (between companies) | Market mechanism |
| `s_19` | Electric Vehicle Incentives | Subsidy |
| `s_20` | Emissions Trading System (between countries) | Market mechanism |
| `s_21` | Public Transportation Funding | Subsidy |
| `s_22` | Developing Countries Climate Support | International aid |
| `s_23` | Green Bonds and Investment | Market mechanism |
| `s_24` | Plant-Based Food Initiatives | Behavioral nudge |
| `s_25` | Air Travel Tax | Tax |
| `s_26` | Red Meat Tax | Tax |
| `s_27` | Diesel Car Restrictions (city centers) | Regulation |

---

### Demographic Variables

| Variable | Type | Description | Values | Renamed To |
|----------|------|-------------|--------|------------|
| `s_33` | Integer | Gender | 1=Male, 2=Female, 3=Other/Prefer not to say | `gender` |
| `s_32` | Integer | Education level | 1-6 scale (details TBD) | `education` |
| `s_35` | Integer | Age group | 1=18-24, 2=25-34, 3=35-44, 4=45-54, 5=55-64, 6=65+ | `age_group` |
| `s_34` | Integer | Region of residence | Danish regions (details TBD) | `region` |

---

### Consent Variable

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `s_48` | Float | Consent to participate | 1.0 = Yes, Other = No |

**Note:** Only participants with `s_48 == 1.0` are included in the analysis (N=312).

---

## Processed Data Files

### 1. `fairness_policies_long.csv`

**Format:** Long format (3,727 observations)  
**Purpose:** Mixed-effects modeling

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `respondent_id` | Integer | Participant ID | 1-312 |
| `policy_code` | String | Original variable name | s_15 to s_27 |
| `policy_label` | String | Human-readable policy name | See policy descriptions above |
| `policy` | Factor | Policy name (categorical) | Used in R models |
| `fairness` | Float | Fairness rating | 1.0-5.0 (6="Don't know" converted to NaN) |
| `ideology` | Integer | Political ideology | 1-11 |
| `gender` | Integer | Gender | 1-3 |
| `education` | Integer | Education level | 1-6 |
| `age_group` | Integer | Age category | 1-6 |
| `region` | Integer | Region | Varies |

**Observations:** Each participant contributes up to 13 observations (one per policy), excluding "Don't know" responses.

---

### 2. `analysis_ready_wide.csv`

**Format:** Wide format (312 participants)  
**Purpose:** OLS regression, descriptive statistics

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `respondent_id` | Integer | Participant ID | 1-312 |
| `ideology` | Integer | Political ideology | 1-11 |
| `avg_fairness` | Float | Average fairness across all 13 policies | 1.0-5.0 |
| `gender` | Integer | Gender | 1-3 |
| `education` | Integer | Education level | 1-6 |
| `age_group` | Integer | Age category | 1-6 |
| `region` | Integer | Region | Varies |
| `s_15` to `s_27` | Float | Individual policy fairness ratings | 1-5 (NaN for "Don't know") |

**Note:** `avg_fairness` is calculated as the mean of s_15 to s_27, **excluding NaN values** (i.e., "Don't know" responses do not contribute to the average).

---

## Important Data Handling Notes

### "Don't Know" Responses (Value = 6)

**Count:** 329 responses across 13 policies (out of 4,056 possible responses)

**Treatment:**
- **In Python:** Replaced with `np.nan` before averaging
- **In R:** Excluded via `na.rm = TRUE` in calculations
- **Rationale:** Including 6 as a numeric value inflates fairness scores by ~0.22 points (7% bias)

### Missing Data

| Source | Count | Handling |
|--------|-------|----------|
| "Don't know" responses | 329 | Converted to NaN |
| Missing ideology | 0 | None (complete data) |
| Missing demographics | 0 | None (complete data) |
| Non-consent | 0 | Pre-filtered in raw data |

---

## Descriptive Statistics

### Ideology Distribution

```
Mean:    4.78
Std Dev: 2.40
Median:  5.00
Range:   1-11
```

**Interpretation:** Sample leans slightly liberal (mean < 6), with good spread across political spectrum.

### Fairness Ratings (After Cleaning)

```
Mean:    3.26
Std Dev: 1.16
Median:  3.33
Range:   1.00-5.00
```

**Interpretation:** Average fairness perception is slightly above midpoint (neutral = 3).

---

## Policy Categorization

For analysis purposes, policies can be grouped:

### By Mechanism

| Category | Policies |
|----------|----------|
| **Taxes** | Carbon Tax (s_16), Air Travel Tax (s_25), Red Meat Tax (s_26) |
| **Market Mechanisms** | Emissions Trading Companies (s_18), Emissions Trading Countries (s_20), Green Bonds (s_23) |
| **Subsidies** | EV Incentives (s_19), Public Transport Funding (s_21) |
| **Regulations** | Vehicle Standards (s_17), Diesel Restrictions (s_27) |
| **Usage Fees** | Road Pricing (s_15) |
| **Behavioral** | Plant-Based Initiatives (s_24) |
| **International** | Developing Countries Support (s_22) |

### By Target

| Category | Policies |
|----------|----------|
| **Transportation** | Road Pricing, Vehicle Standards, EV Incentives, Public Transport, Air Travel Tax, Diesel Restrictions |
| **Food/Lifestyle** | Red Meat Tax, Plant-Based Initiatives |
| **Systemic** | Carbon Tax, Emissions Trading (both), Green Bonds, International Support |

---

## Survey Context

### Survey Administration

- **Platform:** Norstat panel (online survey)
- **Language:** English (with Danish consent screening)
- **Duration:** ~8-10 minutes
- **Randomization:** Order of fairness questions randomized per participant

### Sampling

- **Target Population:** Danish adults (18+)
- **Sampling Method:** Panel-based (Norstat)
- **Response Rate:** Not reported
- **Final N:** 312

---

## Validation Checks

Before using the data, verify:

1. **Ideology range:** All values between 1-11 ✓
2. **Fairness range (cleaned):** All values between 1-5 (no 6s) ✓
3. **No duplicates:** Each respondent_id appears once in wide format ✓
4. **Long format integrity:** Each respondent × policy pair appears at most once ✓
5. **Missing ideology:** Zero participants missing ideology ✓

**Run validation:**
```python
# In Python
assert df['ideology'].min() == 1 and df['ideology'].max() == 11
assert df['fairness'].min() >= 1 and df['fairness'].max() <= 5
assert df['fairness'].isna().sum() == 0  # After dropping "Don't know"
```

---

## Change Log

### November 2025 - Version 1.0
- Initial data dictionary
- Documented all variables from raw to processed formats
- Added policy categorizations
- Clarified "Don't know" handling

---

## References

- Campbell, T. H., & Kay, A. C. (2014). Solution aversion. *Journal of Personality and Social Psychology*, 107(5), 809-824.
- Bergquist, M., et al. (2022). Meta-analyses of climate change taxes and laws. *Nature Climate Change*, 12(3), 235-240.
