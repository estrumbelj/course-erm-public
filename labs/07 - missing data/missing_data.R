# ==============================================================================
# LECTURE DEMO: Missing Data in Action (MAR Regime)
# ==============================================================================
library(palmerpenguins)
library(dplyr)
library(tidyr)
library(ggplot2)
library(mice)

set.seed(1)

# ==============================================================================
# STAGE 0: Ground Truth Benchmark (Clean, Complete Data)
# ==============================================================================

penguins_clean <- penguins |>
  select(body_mass_g, flipper_length_mm, bill_depth_mm, species, sex) |>
  drop_na()

n <- nrow(penguins_clean)
mod_formula <- body_mass_g ~ flipper_length_mm + bill_depth_mm + species * sex

fit_true   <- lm(mod_formula, data = penguins_clean)
true_slope <- coef(fit_true)["flipper_length_mm"]
true_ci    <- confint(fit_true)["flipper_length_mm", ]

cat("Full Data Slope (flipper_length_mm):", round(true_slope, 2), "\n")
cat("95% Benchmark CI: [", round(true_ci[1], 2), ",", round(true_ci[2], 2), "]\n\n")


# ==============================================================================
# STAGE 1: Generate Incomplete Dataset under Strong MAR
# Mechanism: Heavy penguins are far less likely to have flipper measured.
# P(M = 1 | body_mass_g) depends strongly on observed body mass.
# ==============================================================================
logit_mar <- -8.0 + 0.0020 * penguins_clean$body_mass_g
prob_mar  <- plogis(logit_mar)
m_mask    <- rbinom(n, size = 1, prob = prob_mar)

penguins_mar <- penguins_clean |>
  mutate(flipper_length_mm = if_else(m_mask == 1, NA_real_, flipper_length_mm))

cat("Total observations:", n, "\n")
cat("Missing flipper records:", sum(is.na(penguins_mar$flipper_length_mm)), 
    sprintf("(%.1f%% missing)\n\n", 100 * mean(is.na(penguins_mar$flipper_length_mm))))


# ==============================================================================
# STAGE 2: Complete-Case Analysis (Listwise Deletion)
# ==============================================================================
# Using only complete cases biases the slope downward

fit_cc <- lm(mod_formula, data = penguins_mar)
cc_slope <- coef(fit_cc)["flipper_length_mm"]
cc_ci    <- confint(fit_cc)["flipper_length_mm", ]

cat("Complete Cases Slope:", round(cc_slope, 2), "\n")
cat("95% CI: [", round(cc_ci[1], 2), ",", round(cc_ci[2], 2), "]\n")
cat("Bias vs. Full Dataset:", round(cc_slope - true_slope, 2), "\n")

# ==============================================================================
# STAGE 3: Unconditional Single Mean Imputation
# ==============================================================================
# Imputing with the mean decreases the slobe substantially, while falsely deflating
# standard error.

mean_flipper <- mean(penguins_mar$flipper_length_mm, na.rm = TRUE)
df_mean <- penguins_mar |>
  mutate(flipper_length_mm = if_else(is.na(flipper_length_mm), mean_flipper, flipper_length_mm))

fit_mean  <- lm(mod_formula, data = df_mean)
mean_slope <- coef(fit_mean)["flipper_length_mm"]
mean_ci    <- confint(fit_mean)["flipper_length_mm", ]

cat("Mean Imputation Slope:", round(mean_slope, 2), "\n")
cat("95% CI: [", round(mean_ci[1], 2), ",", round(mean_ci[2], 2), "]\n")
cat("Bias vs. Full Dataset:", round(mean_slope - true_slope, 2), "\n")
plot(df_mean$flipper_length_mm, df_mean$body_mass_g)
abline(900 + 17.164 * 103.678, mean_slope, col = "purple", lwd = 2) 
abline(900 + 17.164 * 103.678 + 511, mean_slope, col = "darkgreen", lwd = 2) # sl# slope for Adelie female
# ==============================================================================
# STAGE 4: Diagnostic — Is it MCAR? (Logistic Regression on Missingness)
# Before running MICE, show empirically that missingness is NOT MCAR.
# ==============================================================================
# In practice, we would not have a complete dataset to compare to. Instead, we 
# should diagnose if it is indeed MCAR. Under MCAR, M should be independent of 
# the data. We demonstrate that it's not, thus ruling out MCAR.

penguins_mar <- penguins_mar |>
  mutate(is_missing = if_else(is.na(flipper_length_mm), 1, 0))

fit_diag <- glm(is_missing ~ body_mass_g + bill_depth_mm, 
                data = penguins_mar, family = binomial)
summary(fit_diag) # diagnose model

# A. Baseline (No-Information / Majority Class Rule)
missing_pct  <- mean(penguins_mar$is_missing)
baseline_acc <- max(missing_pct, 1 - missing_pct)

# B. Logistic regression (but we could use any predictive model)
pred_probs <- predict(fit_diag, type = "response")
pred_class <- if_else(pred_probs > 0.5, 1, 0)
model_acc <- mean(pred_class == penguins_mar$is_missing)
se_acc <- sqrt(model_acc * (1 - model_acc) / nrow(penguins_mar))
margin <- 1.96 * se_acc

cat(sprintf("Baseline Missing Rate:      %.1f%%\n", missing_pct * 100))
cat(sprintf("Naive Baseline Accuracy:    %.1f%%  (predicting majority '%s' for everyone)\n", 
            baseline_acc * 100, if_else(missing_pct > 0.5, "Missing", "Observed")))
cat(sprintf("Model Prediction Accuracy: %.1f%% (95%% CI: ±%.1f%%)\n", 
            100 * model_acc, 100 * margin))

# ==============================================================================
# STAGE 5: MICE with Rubin's Rules (m = 20, PMM)
# ==============================================================================

imp_mice <- mice(penguins_mar, m = 20, method = "pmm", printFlag = FALSE, seed = 1)

# 1. Pre-allocate an empty list for the m models
m <- 20
fit_list <- vector("list", m)

# 2. Fit the model to each completed dataset one by one
for (i in 1:m) {
  df_completed   <- complete(imp_mice, i)
  fit_list[[i]]  <- lm(mod_formula, data = df_completed)
}

# 3. Pool the results
pooled_res <- summary(pool(as.mira(fit_list)), conf.int = TRUE) |>
  filter(term == "flipper_length_mm")

mice_slope <- pooled_res$estimate
mice_ci    <- c(pooled_res$`2.5 %`, pooled_res$`97.5 %`)

cat("MICE Pooled Slope:", round(mice_slope, 2), "\n")
cat("95% CI (Rubin's Rules): [", round(mice_ci[1], 2), ",", round(mice_ci[2], 2), "]\n")
cat("Bias vs. Full Dataset:", round(mice_slope - true_slope, 2), "\n")

# ==============================================================================
# STAGE 6: Bootstrap Before Imputation (B = 200, m = 1 pass per bootstrap sample)
# ==============================================================================
B <- 200

# Pre-allocate vector for the B bootstrap estimates
boot_slopes <- numeric(B)

for (b in 1:B) {
  # Step 1: Resample rows with replacement from incomplete data
  boot_indices <- sample.int(n, size = nrow(penguins_mar), replace = TRUE)
  df_boot      <- penguins_mar[boot_indices, ]
  
  # Step 2: Run a single stochastic imputation pass (m = 1)
  imp_single   <- mice(df_boot, m = 1, maxit = 5, method = "pmm", printFlag = FALSE)
  df_completed <- complete(imp_single, 1)
  
  # Step 3: Fit the substantive analysis model and extract the slope
  fit_b          <- lm(mod_formula, data = df_completed)
  boot_slopes[b] <- coef(fit_b)["flipper_length_mm"]
}

# Step 4: Extract point estimate and 95% Percentile Confidence Interval
boot_slope <- mean(boot_slopes)
boot_ci    <- quantile(boot_slopes, probs = c(0.025, 0.975))

cat("Bootstrap-then-Impute Slope:", round(boot_slope, 2), "\n")
cat("95% Percentile CI: [", round(boot_ci[1], 2), ",", round(boot_ci[2], 2), "]\n")
cat("Bias vs. Full Dataset:", round(boot_slope - true_slope, 2), "\n")
