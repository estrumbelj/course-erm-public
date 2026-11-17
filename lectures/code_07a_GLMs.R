# ==============================================================================
# Simple Binary Logistic Regression Workflow
# ==============================================================================

library(boot)
library(DHARMa)

set.seed(1)

# ------------------------------------------------------------------------------
# 0. Generate Toy Dataset (N = 300)
# ------------------------------------------------------------------------------
n <- 300
x <- rnorm(n, mean = 0, sd = 1)

# True DGP: logit(p) = -0.5 + 1.2 * x
# True parameters: beta_0 = -0.5, beta_1 = 1.2
p_true <- plogis(-0.5 + 1.2 * x)
y      <- rbinom(n, size = 1, prob = p_true)

df <- data.frame(x = x, y = y)


# ------------------------------------------------------------------------------
# 1. Fit Binomial GLM (Logistic Regression)
# ------------------------------------------------------------------------------
fit      <- glm(y ~ x, data = df, family = binomial(link = "logit"))
fit_null <- glm(y ~ 1, data = df, family = binomial(link = "logit"))

summary(fit)


# ------------------------------------------------------------------------------
# 2. Model Diagnostics
# ------------------------------------------------------------------------------

# A. Base R diagnostic plots
# Notice: Plot 1 exhibits parallel curved stripes, and Plot 2 (Q-Q) forms an S-curve.
# These are mathematical artifacts of discrete y in {0, 1}, not proof of model failure.
par(mfrow = c(2, 2))
plot(fit)
par(mfrow = c(1, 1))

# B. DHARMa simulation-based quantile residuals
# Simulates from the model to map discrete residuals to continuous Uniform(0, 1).
# The stripes vanish: look for a straight Q-Q line and flat horizontal quantile splines.
sim_res <- simulateResiduals(fit, n = 250)
plot(sim_res)


# Fitting Gaussian GLM (an example of a misspecified model):
my_lr <- lm(y ~ x, data = df)
sim_res <- simulateResiduals(my_lr , n = 250)
plot(sim_res)

# ------------------------------------------------------------------------------
# 3. Parameter Uncertainty via Nonparametric Bootstrap (`boot` package)
# ------------------------------------------------------------------------------
# Statistic function for boot: returns the slope coefficient
boot_fn <- function(data, indices) {
  d <- data[indices, ]
  coef(glm(y ~ x, data = d, family = binomial))[2]
}

boot_out <- boot(data = df, statistic = boot_fn, R = 1000)
boot_ci  <- boot.ci(boot_out, type = "perc")

beta_est <- boot_out$t0
beta_se  <- sd(boot_out$t)
ci_lower <- boot_ci$percent[4]
ci_upper <- boot_ci$percent[5]

cat("\n--- Parameter Uncertainty (Slope beta_1) ---\n")
cat(sprintf("Point Estimate:             %.3f (Wald SE: %.3f)\n", 
            beta_est, summary(fit)$coefficients["x", "Std. Error"]))
cat(sprintf("Bootstrap SE:               %.3f\n", beta_se))
cat(sprintf("95%% Percentile CI (Logit):  [%.3f, %.3f]\n", ci_lower, ci_upper))
cat(sprintf("95%% Percentile CI (Odds):   [%.3f, %.3f]\n\n", exp(ci_lower), exp(ci_upper)))


# ------------------------------------------------------------------------------
# 4. Model Evaluation: AIC & LOOCV Log Predictive Density
# ------------------------------------------------------------------------------
# Function to compute exact Leave-One-Out Cross-Validated log scores
loocv_elpd <- function(formula, data) {
  n_obs <- nrow(data)
  log_scores <- numeric(n_obs)
  
  for (i in 1:n_obs) {
    fit_i <- glm(formula, data = data[-i, ], family = binomial)
    p_hat <- predict(fit_i, newdata = data[i, , drop = FALSE], type = "response")
    # Clamp slightly to prevent log(0) underflow
    p_hat <- min(max(p_hat, 1e-15), 1 - 1e-15)
    
    y_i <- data$y[i]
    log_scores[i] <- y_i * log(p_hat) + (1 - y_i) * log(1 - p_hat)
  }
  list(total = sum(log_scores), se = sqrt(n_obs) * sd(log_scores), scores = log_scores)
}

elpd_cand <- loocv_elpd(y ~ x, df)
elpd_null <- loocv_elpd(y ~ 1, df)

# Paired difference and its standard error
diff_scores <- elpd_cand$scores - elpd_null$scores
diff_total  <- sum(diff_scores)
diff_se     <- sqrt(n) * sd(diff_scores)

cat("--- Model Comparison: Candidate (y ~ x) vs. Null (y ~ 1) ---\n")
cat(sprintf("AIC (Null):              %.2f\n", AIC(fit_null)))
cat(sprintf("AIC (Candidate):         %.2f (Delta AIC = %+.2f)\n\n", 
            AIC(fit), AIC(fit) - AIC(fit_null)))

cat(sprintf("LOOCV Log Score (Null):       %.2f +/- %.2f\n", elpd_null$total, elpd_null$se))
cat(sprintf("LOOCV Log Score (Candidate):  %.2f +/- %.2f\n", elpd_cand$total, elpd_cand$se))
cat(sprintf("Out-of-Sample Improvement:    %+.2f +/- %.2f log-density units\n\n", 
            diff_total, diff_se))

# ------------------------------------------------------------------------------
# 5. Visualizing Parameter Interpretation Across Scales (Log-Odds vs. Probability)
# ------------------------------------------------------------------------------

library(ggplot2)
library(patchwork)

# 1. Create a dense grid of x values to generate smooth curves
grid_x <- data.frame(x = seq(min(df$x), max(df$x), length.out = 300))

# Predict on both scales
grid_x$log_odds <- predict(fit, newdata = grid_x, type = "link")      # eta = x'beta
grid_x$prob     <- predict(fit, newdata = grid_x, type = "response")  # p = plogis(eta)

b1_hat <- coef(fit)["x"]
or_hat <- exp(b1_hat)

# 2. Left Panel: Link Scale (Log-Odds) -> Strictly Linear & Additive
p_link <- ggplot(grid_x, aes(x = x, y = log_odds)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_line(color = "#2c3e50", linewidth = 1.2) +
  annotate(
    "text", x = min(df$x) + 0.2, y = max(grid_x$log_odds) - 0.5,
    label = sprintf("Linear Slope (beta_1) = %+.2f\nConstant additive change in log-odds", b1_hat),
    color = "#2c3e50", fontface = "bold", hjust = 0, size = 3.6
  ) +
  labs(
    title = "1. Link Scale: Log-Odds",
    subtitle = "eta = beta_0 + beta_1 * x (Unbounded, Linear)",
    x = "Predictor (x)",
    y = "Log-Odds: ln(p / (1 - p))"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

# 3. Right Panel: Natural Scale (Probability) -> Non-Linear S-Curve (Sigmoid)
p_response <- ggplot() +
  # Raw observations jittered slightly at y = 0 and y = 1
  geom_jitter(data = df, aes(x = x, y = y), height = 0.04, alpha = 0.4, color = "gray40", size = 1.6) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray60") +
  geom_line(data = grid_x, aes(x = x, y = prob), color = "#e74c3c", linewidth = 1.2) +
  scale_y_continuous(breaks = seq(0, 1, 0.25), limits = c(-0.08, 1.08)) +
  labs(
    title = "2. Natural Scale: Probability",
    subtitle = "p = 1 / (1 + e^-eta) (Bounded [0, 1], Non-Linear)",
    x = "Predictor (x)",
    y = "P(Y = 1)"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

# 4. Display both side-by-side
(p_link + p_response)