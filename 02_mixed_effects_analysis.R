# Mixed-effects analysis of climate policy fairness perceptions
# Author: Nadav
# Date: November 2025
#
# Model: fairness ~ ideology * policy + (1|participant)

suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(broom.mixed)
  library(viridis)
  library(here)
})

setwd(here::here("climate-fairness-analysis"))

# Load data
df_long <- read_csv("data/processed/fairness_policies_long.csv", show_col_types = FALSE)
df_wide <- read_csv("data/processed/analysis_ready_wide.csv", show_col_types = FALSE)
cat("Loaded", nrow(df_long), "observations from", nrow(df_wide), "participants\n")

# Set baseline policy (Air Travel Tax as neutral reference)
BASELINE_POLICY <- "Air Travel Tax"
policy_levels <- c(BASELINE_POLICY, sort(setdiff(unique(df_long$policy_label), BASELINE_POLICY)))
df_long$policy <- factor(df_long$policy_label, levels = policy_levels)
df_long$participant_id <- factor(df_long$respondent_id)

# Descriptive statistics
summary_stats <- df_long %>%
  summarise(
    n_participants = n_distinct(participant_id),
    n_policies = n_distinct(policy),
    n_observations = n(),
    mean_fairness = round(mean(fairness, na.rm = TRUE), 2),
    sd_fairness = round(sd(fairness, na.rm = TRUE), 2),
    mean_ideology = round(mean(ideology, na.rm = TRUE), 2),
    sd_ideology = round(sd(ideology, na.rm = TRUE), 2)
  )
print(summary_stats)

# OLS regression (participant-level averages)
ols_model <- lm(avg_fairness ~ ideology, data = df_wide)
ols_summary_output <- capture.output(summary(ols_model))
writeLines(ols_summary_output, "outputs/models/ols_summary.txt")
cat("OLS: ideology beta =", round(coef(ols_model)[2], 4), ", R2 =", round(summary(ols_model)$r.squared, 3), "\n")

# Mixed-effects model
mixed_model <- lmer(
  fairness ~ ideology * policy + (1 | participant_id), 
  data = df_long,
  REML = FALSE
)
mixed_summary_output <- capture.output(summary(mixed_model))
writeLines(mixed_summary_output, "outputs/models/mixed_model_summary.txt")
cat("Mixed model: AIC =", round(AIC(mixed_model), 1), "\n")

# Extract policy-specific coefficients
fixed_effects <- tidy(mixed_model, effects = "fixed")
base_intercept <- fixed_effects$estimate[fixed_effects$term == "(Intercept)"]
base_slope <- fixed_effects$estimate[fixed_effects$term == "ideology"]

# Create coefficient table for each policy
policy_coefs <- tibble(policy = levels(df_long$policy)) %>%
  mutate(
    # Calculate intercept for each policy
    intercept = map_dbl(policy, function(p) {
      if (p == BASELINE_POLICY) {
        return(base_intercept)
      } else {
        policy_term <- paste0("policy", p)
        policy_adj <- fixed_effects$estimate[fixed_effects$term == policy_term]
        if (length(policy_adj) == 0) policy_adj <- 0
        return(base_intercept + policy_adj)
      }
    }),
    
    # Calculate slope for each policy
    slope = map_dbl(policy, function(p) {
      if (p == BASELINE_POLICY) {
        return(base_slope)
      } else {
        interaction_term <- paste0("ideology:policy", p)
        interaction_adj <- fixed_effects$estimate[fixed_effects$term == interaction_term]
        if (length(interaction_adj) == 0) interaction_adj <- 0
        return(base_slope + interaction_adj)
      }
    })
  ) %>%
  # Add absolute slope for ranking
  mutate(abs_slope = abs(slope)) %>%
  # Round for readability
  mutate(across(c(intercept, slope, abs_slope), ~ round(.x, 4))) %>%
  # Sort by ideological divisiveness
  arrange(desc(abs_slope))

# Save policy coefficients
write_csv(policy_coefs, "outputs/tables/policy_slopes_from_mixed_model.csv")
cat("Most divisive:", head(policy_coefs$policy, 3), "\n")

# Generate predictions across ideology spectrum (1-11)
prediction_grid <- expand_grid(
  policy = levels(df_long$policy),
  ideology = 1:11
) %>%
  mutate(participant_id = first(df_long$participant_id))

predictions <- prediction_grid %>%
  mutate(pred_fairness = predict(mixed_model, newdata = ., re.form = NA)) %>%
  select(-participant_id) %>%
  mutate(pred_fairness = round(pred_fairness, 3))

write_csv(predictions, "outputs/tables/predicted_fairness_by_ideology.csv")

# Visualizations
create_slope_plot <- function(policies_to_plot, title_text, filename) {
  
  plot_data <- predictions %>%
    filter(policy %in% policies_to_plot) %>%
    # Reorder by slope magnitude for legend
    mutate(policy = factor(policy, levels = policies_to_plot))
  
  p <- ggplot(plot_data, aes(x = ideology, y = pred_fairness, color = policy)) +
    geom_line(linewidth = 1.2, alpha = 0.85) +
    scale_x_continuous(
      breaks = seq(1, 11, 2),
      labels = c("1\n(Very\nLiberal)", "3", "5", "7", "9", "11\n(Very\nConservative)")
    ) +
    scale_y_continuous(limits = c(1, 5), breaks = 1:5) +
    scale_color_viridis_d(option = "plasma", end = 0.9) +
    labs(
      title = title_text,
      subtitle = paste0("Based on mixed-effects model: fairness ~ ideology × policy + (1|participant)"),
      x = "Political Ideology",
      y = "Predicted Fairness Rating (1-5)",
      color = "Policy"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 9, color = "gray30"),
      legend.position = "right",
      legend.title = element_text(size = 11, face = "bold"),
      legend.text = element_text(size = 9),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(alpha = 0.3),
      axis.title = element_text(size = 11, face = "bold")
    ) +
    guides(color = guide_legend(override.aes = list(linewidth = 1.8)))
  
  ggsave(filename, plot = p, width = 12, height = 7, dpi = 300, bg = "white")
  return(p)
}

# Identify most and least divisive policies (top 6 each)
most_divisive <- policy_coefs %>%
  slice_max(abs_slope, n = 6) %>%
  pull(policy)

least_divisive <- policy_coefs %>%
  slice_min(abs_slope, n = 6) %>%
  pull(policy)

# Create plots
plot_most <- create_slope_plot(
  most_divisive,
  "Policies with Strongest Ideological Divide in Fairness Perceptions",
  "outputs/figures/slope_lines_most_divisive.png"
)

plot_least <- create_slope_plot(
  least_divisive,
  "Policies with Smallest Ideological Divide in Fairness Perceptions", 
  "outputs/figures/slope_lines_least_divisive.png"
)

cat("Figures saved to outputs/figures/\n")

cat("\nDone.\n")
