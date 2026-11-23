library(palmerpenguins)
library(dplyr)
library(tidyr)
library(ggplot2)
library(DHARMa)

set.seed(1)

penguins_clean <- penguins |>
  select(species, bill_length_mm, bill_depth_mm, flipper_length_mm, body_mass_g, sex) |>
  drop_na() |>
  mutate(sex_male = if_else(sex == "male", 1, 0))
n <- nrow(penguins_clean)


# ==============================================================================
# ==============================================================================
# PART 1: LOGISTIC REGRESSION (Binary Response: sex_male in {0, 1})
# ==============================================================================
# ==============================================================================

# ------------------------------------------------------------------------------
# Model Fitting
# ------------------------------------------------------------------------------
# Biological premise: Male penguins have heavier body mass than females within each species
form_logit <- sex_male ~ body_mass_g + species

fit_logit  <- glm(form_logit, data = penguins_clean, family = binomial(link = "logit"))
null_logit <- glm(sex_male ~ 1, data = penguins_clean, family = binomial(link = "logit"))

summary(fit_logit)

# ------------------------------------------------------------------------------
# Model Evaluation: LOOCV Log Predictive Density (Log Score)
# ------------------------------------------------------------------------------
cat("Computing LOOCV Log Predictive Density (Candidate vs. Null)...\n")

loocv_log_score_logit <- function(model_formula, df) {
  n_rows <- nrow(df)
  log_scores <- numeric(n_rows)
  
  for (i in 1:n_rows) {
    # Train on n - 1 observations
    fit_i <- glm(model_formula, data = df[-i, ], family = binomial(link = "logit"))
    
    # Predict probability for held-out unit i
    p_hat <- predict(fit_i, newdata = df[i, ], type = "response")
    # Clamp slightly away from 0 and 1 to prevent log(0) numerical underflow
    p_hat <- min(max(p_hat, 1e-15), 1 - 1e-15)
    
    # Bernoulli log predictive density: y * ln(p) + (1 - y) * ln(1 - p)
    y_i <- df$sex_male[i]
    log_scores[i] <- y_i * log(p_hat) + (1 - y_i) * log(1 - p_hat)
  }
  
  # Return sum, standard error of the sum, and individual scores
  list(
    total  = sum(log_scores),
    se     = sqrt(n_rows) * sd(log_scores),
    scores = log_scores
  )
}

elpd_cand_logit <- loocv_log_score_logit(form_logit, penguins_clean)
elpd_null_logit <- loocv_log_score_logit(sex_male ~ 1, penguins_clean)

# Paired difference and its standard error
diff_scores <- elpd_cand_logit$scores - elpd_null_logit$scores
diff_total  <- sum(diff_scores)
diff_se     <- sqrt(nrow(penguins_clean)) * sd(diff_scores)

# Display results
cat(sprintf("Null Model LOOCV Log Score:      %.2f +/- %.2f  (AIC = %.2f)\n", 
            elpd_null_logit$total, elpd_null_logit$se, AIC(null_logit)))
cat(sprintf("Candidate Model LOOCV Log Score: %.2f +/- %.2f  (AIC = %.2f)\n", 
            elpd_cand_logit$total, elpd_cand_logit$se, AIC(fit_logit)))
cat(sprintf("Out-of-Sample Improvement:       %+.2f +/- %.2f log-density units\n\n", 
            diff_total, diff_se))


# ------------------------------------------------------------------------------
# Model Criticism & Diagnostics (plot() vs. DHARMa)
# ------------------------------------------------------------------------------
# A. Base R diagnostic plots (illustrating the "broken" visual artifact)
par(mfrow = c(2, 2))
plot(fit_logit)
par(mfrow = c(1, 1))
cat("NOTICE in base plot():\n",
    "• Plot 1 displays two parallel curved stripes (an artifact of y in {0, 1}).\n",
    "• Plot 2 (Normal Q-Q) displays an S-curve because binary errors are non-Gaussian.\n",
    "• Plot 4 (Cook's distance) remains valid to detect influential outliers.\n\n")

# B. DHARMa simulation-based quantile residuals (resolving the artifact)
sim_logit <- simulateResiduals(fit_logit, n = 250, plot = FALSE)
plot(sim_logit)
cat("NOTICE in DHARMa plot():\n",
    "• The stripes vanish! Residuals are mapped to a uniform scale U(0, 1).\n",
    "• KS test and dispersion test evaluate whether residuals depart from uniformity.\n\n")


# ------------------------------------------------------------------------------
# Parameter Uncertainty via Non-Parametric Bootstrap
# ------------------------------------------------------------------------------
cat("Running Pairs Bootstrap (B = 500) for Logistic Regression...\n")

B <- 500
boot_coefs_logit <- numeric(B)

for (b in 1:B) {
  idx_boot <- sample.int(n, size = n, replace = TRUE)
  df_b     <- penguins_clean[idx_boot, ]
  fit_b    <- glm(form_logit, data = df_b, family = binomial(link = "logit"))
  boot_coefs_logit[b] <- coef(fit_b)["body_mass_g"]
}

boot_se_logit <- sd(boot_coefs_logit)
boot_ci_link  <- quantile(boot_coefs_logit, probs = c(0.025, 0.975))
boot_ci_or    <- exp(boot_ci_link)

cat(sprintf("Bootstrap SE (beta_mass):     %.3f (Wald SE from summary: %.3f)\n", 
            boot_se_logit, summary(fit_logit)$coefficients["body_mass_g", "Std. Error"]))
cat(sprintf("95%% Percentile CI (Log-Odds):  [%.3f, %.3f]\n", boot_ci_link[1], boot_ci_link[2]))
cat(sprintf("95%% Percentile CI (Odds Ratio):[%.3f, %.3f]\n\n", boot_ci_or[1], boot_ci_or[2]))



# ------------------------------------------------------------------------------
# Parameter Interpretation:
# ------------------------------------------------------------------------------

# Create a prediction grid across body mass for each species,
# holding bill_depth_mm constant at its sample median
grid_pred <- penguins_clean |>
  group_by(species) |>
  reframe(
    body_mass_g   = seq(min(body_mass_g), max(body_mass_g), length.out = 200),
  )

grid_pred$pred_prob <- predict(fit_logit, newdata = grid_pred, type = "response")

# Plot: Observed individuals (by sex at y = 0 and y = 1) with fitted logistic S-curves
p_logit_sex <- ggplot() +
  # 50% decision boundary threshold
  geom_hline(yintercept = mean(penguins_clean$sex_male), linetype = "dashed", color = "gray60", linewidth = 0.7) +
  
  # Observed data: jittered slightly vertically at 0 (female) and 1 (male)
  geom_jitter(
    data = penguins_clean,
    aes(x = body_mass_g, y = sex_male, color = sex),
    height = 0.04, alpha = 0.6, size = 2
  ) +
  
  # Fitted logistic probability curve P(Male)
  geom_line(
    data = grid_pred,
    aes(x = body_mass_g, y = pred_prob),
    color = "#2c3e50", linewidth = 1.2
  ) +
  
  # Facet by species with free x-axes to respect different body mass ranges
  facet_wrap(~ species, scales = "free_x") +
  
  scale_y_continuous(
    breaks = seq(0, 1, by = 0.25),
    limits = c(-0.08, 1.08),
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_color_manual(
    name = "Observed Sex:",
    values = c("female" = "#e74c3c", "male" = "#2980b9"),
    labels = c("female" = "Female (y = 0)", "male" = "Male (y = 1)")
  ) +
  labs(
    title = "Predicted Probability of Being Male by Body Mass",
    subtitle = "Logistic S-curves per species (fitted via binomial GLM with logit link)",
    x = "Body Mass (g)",
    y = "Predicted P(Male)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    strip.text = element_text(face = "bold", size = 11),
    panel.grid.minor = element_blank()
  )

print(p_logit_sex)

# ==============================================================================
# ==============================================================================
# PART 2: GAMMA GLM (Continuous Positive Response: Server Latency)
# ==============================================================================
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. Generate Toy Dataset with Proportional Error (Constant CV = 30%)
# ------------------------------------------------------------------------------
n_toy <- 400

# Predictor: Payload size between 0.5 MB and 8.0 MB
payload_mb <- runif(n_toy, min = 0.5, max = 8.0)

# True physical law: Exponential latency scaling (log link)
# ln(mu) = 3.5 + 0.35 * payload
mu_true <- exp(3.5 + 0.35 * payload_mb)

# True Gamma noise: Constant CV = 0.30 -> shape = 1 / CV^2 = 11.11
shape_true <- 1 / (0.30^2)
rate_true  <- shape_true / mu_true

latency_ms <- rgamma(n_toy, shape = shape_true, rate = rate_true)
toy_gamma  <- tibble(payload_mb = payload_mb, latency_ms = latency_ms)

form_toy <- latency_ms ~ payload_mb
plot(toy_gamma)

# ------------------------------------------------------------------------------
# MOTIVATION: Fit Gaussian lm() and Observe the Expanding Funnel
# ------------------------------------------------------------------------------
cat("--- Demonstrating Heteroskedasticity Failure in Gaussian lm() ---\n")

fit_lm_toy <- lm(form_toy, data = toy_gamma)

par(mfrow = c(1, 2))
# Plot 1: Standard Residuals vs Fitted (shows widening vertical spread)
plot(fit_lm_toy, which = 1, main = "lm(): Residuals vs. Fitted")
# Plot 3: Scale-Location (the red line tilts upward sharply -> severe heteroskedasticity)
plot(fit_lm_toy, which = 3, main = "lm(): Scale-Location (The Funnel)")
par(mfrow = c(1, 1))

cat("NOTICE IN lm():\n",
    "• The Scale-Location line tilts sharply upward!\n",
    "• Residual spread widens from +/-30 ms on small payloads to +/-300 ms on large payloads.\n",
    "• In an ordinary linear model, this is an explicit violation (Heteroskedasticity).\n\n")

# ------------------------------------------------------------------------------
# WARNING: Nonlinear fit does not solve the problem of heteroskedasticity!
# ------------------------------------------------------------------------------

fit_lm_toy <- lm(latency_ms ~ poly(payload_mb, 3), data = toy_gamma)

par(mfrow = c(1, 2))
# Plot 1: Standard Residuals vs Fitted (shows widening vertical spread)
plot(fit_lm_toy, which = 1, main = "lm(): Residuals vs. Fitted")
# Plot 3: Scale-Location (the red line tilts upward sharply -> severe heteroskedasticity)
plot(fit_lm_toy, which = 3, main = "lm(): Scale-Location (The Funnel)")
par(mfrow = c(1, 1))


# ------------------------------------------------------------------------------
# Model Fitting (Gamma GLM with Log Link)
# ------------------------------------------------------------------------------
cat("--- Fitting Gamma GLM to Absorb Proportional Variance ---\n")

fit_gamma  <- glm(form_toy, data = toy_gamma, family = Gamma(link = "log"))
null_gamma <- glm(latency_ms ~ 1, data = toy_gamma, family = Gamma(link = "log"))

summary(fit_gamma)


# ------------------------------------------------------------------------------
# Model Evaluation: LOOCV Log Predictive Density (Log Score)
# ------------------------------------------------------------------------------
cat("Computing LOOCV Log Predictive Density (Candidate vs. Null)...\n")

loocv_log_score_gamma <- function(model_formula, df) {
  n_rows <- nrow(df)
  log_scores <- numeric(n_rows)
  
  for (i in 1:n_rows) {
    # Train on n - 1 observations
    fit_i <- glm(model_formula, data = df[-i, ], family = Gamma(link = "log"))
    
    # Predict mean on natural response scale for held-out unit i
    mu_i <- predict(fit_i, newdata = df[i, ], type = "response")
    
    # Extract dispersion parameter phi to parameterize shape and rate
    phi_i     <- summary(fit_i)$dispersion
    shape_val <- 1 / phi_i
    rate_val  <- shape_val / mu_i
    
    # Exact Gamma log predictive density
    y_i <- df$latency_ms[i]
    log_scores[i] <- dgamma(y_i, shape = shape_val, rate = rate_val, log = TRUE)
  }
  
  list(
    total  = sum(log_scores),
    se     = sqrt(n_rows) * sd(log_scores),
    scores = log_scores
  )
}

elpd_cand_gamma <- loocv_log_score_gamma(form_toy, toy_gamma)
elpd_null_gamma <- loocv_log_score_gamma(latency_ms ~ 1, toy_gamma)

# Paired difference and its standard error
diff_scores_gamma <- elpd_cand_gamma$scores - elpd_null_gamma$scores
diff_total_gamma  <- sum(diff_scores_gamma)
diff_se_gamma     <- sqrt(n_toy) * sd(diff_scores_gamma)

cat(sprintf("Null Model LOOCV Log Score:      %.2f +/- %.2f  (AIC = %.2f)\n", 
            elpd_null_gamma$total, elpd_null_gamma$se, AIC(null_gamma)))
cat(sprintf("Candidate Model LOOCV Log Score: %.2f +/- %.2f  (AIC = %.2f)\n", 
            elpd_cand_gamma$total, elpd_cand_gamma$se, AIC(fit_gamma)))
cat(sprintf("Out-of-Sample Improvement:       %+.2f +/- %.2f log-density units\n\n", 
            diff_total_gamma, diff_se_gamma))


# ------------------------------------------------------------------------------
# Model Criticism & Diagnostics (plot() vs. DHARMa)
# ------------------------------------------------------------------------------
# A. Base R diagnostic plots for Gamma
par(mfrow = c(2, 2))
plot(fit_gamma)
par(mfrow = c(1, 1))
cat("NOTICE in base plot() for Gamma:\n",
    "• Deviance residuals are continuous and divide out the proportional variance.\n",
    "• The funnel visible in lm() is gone; the scale-location line is now flat!\n\n")

# B. DHARMa simulation-based quantile residuals
sim_gamma <- simulateResiduals(fit_gamma, n = 250, plot = FALSE)
plot(sim_gamma)
cat("NOTICE in DHARMa plot():\n",
    "• All three quantile regression lines (0.25, 0.50, 0.75) are flat and horizontal.\n",
    "• Confirms the Gamma mean-variance assumption (Var(Y) proportional to mu^2) holds.\n\n")


# ------------------------------------------------------------------------------
# Parameter Uncertainty via Non-Parametric Bootstrap
# ------------------------------------------------------------------------------
cat("Running Pairs Bootstrap (B = 500) for Gamma GLM...\n")

B <- 500
boot_coefs_gamma <- numeric(B)

for (b in 1:B) {
  idx_boot <- sample.int(n_toy, size = n_toy, replace = TRUE)
  df_b     <- toy_gamma[idx_boot, ]
  fit_b    <- glm(form_toy, data = df_b, family = Gamma(link = "log"))
  boot_coefs_gamma[b] <- coef(fit_b)["payload_mb"]
}

boot_se_gamma <- sd(boot_coefs_gamma)
boot_ci_link  <- quantile(boot_coefs_gamma, probs = c(0.025, 0.975))
boot_ci_mult  <- exp(boot_ci_link)

cat(sprintf("Bootstrap SE (beta_payload):         %.5f (Wald SE from summary: %.5f)\n", 
            boot_se_gamma, summary(fit_gamma)$coefficients["payload_mb", "Std. Error"]))
cat(sprintf("95%% Percentile CI (Log-Mean):        [%.4f, %.4f]\n", boot_ci_link[1], boot_ci_link[2]))
cat(sprintf("95%% Percentile CI (Multiplicative):  [%.4f, %.4f]\n\n", boot_ci_mult[1], boot_ci_mult[2]))


# ------------------------------------------------------------------------------
# Parameter Interpretation:
# ------------------------------------------------------------------------------
b_payload    <- coef(fit_gamma)["payload_mb"]
mult_payload <- exp(b_payload)

cat(sprintf("1. Link Scale (Log-Mean):            beta = %+.4f  (additive shift in ln(mu))\n", b_payload))
cat(sprintf("2. Natural Scale (Multiplicative):   exp(beta) = %.4f\n", mult_payload))
cat(sprintf("   -> Substantive interpretation:\n"))
cat(sprintf("      Each 1 MB increase in payload scales expected latency\n"))
cat(sprintf("      multiplicatively by a factor of %.3f (a %+.1f%% increase).\n\n", 
            mult_payload, (mult_payload - 1) * 100))

# Create smooth prediction grid across payload range
grid_pred_toy <- tibble(
  payload_mb = seq(min(toy_gamma$payload_mb), max(toy_gamma$payload_mb), length.out = 200)
)
grid_pred_toy$pred_latency <- predict(fit_gamma, newdata = grid_pred_toy, type = "response")

# Plot: Observed points showing expanding scatter with fitted Gamma curve
p_gamma_toy <- ggplot() +
  # Raw observations (notice how scatter widens vertically as payload increases)
  geom_point(
    data = toy_gamma,
    aes(x = payload_mb, y = latency_ms),
    alpha = 0.5, color = "#2c3e50", size = 2
  ) +
  # Fitted exponential curve from Gamma GLM with log link
  geom_line(
    data = grid_pred_toy,
    aes(x = payload_mb, y = pred_latency),
    color = "#e74c3c", linewidth = 1.2
  ) +
  labs(
    title = "Server Latency vs. Payload Size (Gamma GLM with Log Link)",
    subtitle = "Notice the expanding vertical scatter (heteroskedasticity) and the fitted exponential curve",
    x = "Payload Size (MB)",
    y = "Latency (ms)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    panel.grid.minor = element_blank()
  )

print(p_gamma_toy)

