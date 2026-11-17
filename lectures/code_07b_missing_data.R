library(dplyr)
library(ggplot2)
library(mice)
library(patchwork)

set.seed(0)

# ==============================================================================
# 0. Generate Clean Data (N = 600)
# ==============================================================================
n <- 1000
x <- runif(n, min = -1, max = 1)
y <- x + rnorm(n, mean = 0, sd = 1)

toy_clean <- tibble(x = x, y = y)

# Baseline fit on complete data
fit_clean <- lm(y ~ x, data = toy_clean)
cat("Ground Truth Fit: Intercept =", round(coef(fit_clean)[1], 2), 
    "| Slope =", round(coef(fit_clean)[2], 2), "\n\n")

# ==============================================================================
# 1. Define the 4 Missingness Regimes
# ==============================================================================

# Scenario 0: MCAR (40% random drop on Y)
m_mcary <- rbinom(n, size = 1, prob = 0.40) == 1

# Scenario 1: MCAR (40% random drop on X)
m_mcar <- rbinom(n, size = 1, prob = 0.40) == 1

# Scenario 2: MAR (Missingness in X depends on observed Y)
prob_mar <- plogis(-0.8 + 1.2 * y)
m_mar    <- rbinom(n, size = 1, prob = prob_mar) == 1

# Scenario 3: Cut X-axis (MNAR on X: all X > 0.25 missing)
m_cut_x  <- x > 0.25

# Scenario 4: Cut Y-axis (MNAR on Y: all Y > 0.50 missing)
m_cut_y  <- y > 0.50


# ==============================================================================
# 2. Helper Engine: Impute, Fit Models, and Return Slopes + Plot
# ==============================================================================
analyze_scenario <- function(df_raw, missing_mask, missing_var = "x", 
                             title_text, subtitle_text) {
  
  # Inject missingness
  df_incomp <- df_raw
  df_incomp[[missing_var]][missing_mask] <- NA_real_
  
  # A. Complete Cases (Listwise Deletion)
  fit_cc  <- lm(y ~ x, data = df_incomp)
  b1_cc   <- coef(fit_cc)["x"]
  b0_cc   <- coef(fit_cc)["(Intercept)"]
  se_cc   <- summary(fit_cc)$coefficients["x", "Std. Error"]
  
  # B. Mean Imputation
  df_mean <- df_incomp
  df_mean[[missing_var]][is.na(df_mean[[missing_var]])] <- mean(df_mean[[missing_var]], na.rm = TRUE)
  fit_mean <- lm(y ~ x, data = df_mean)
  b1_mean  <- coef(fit_mean)["x"]
  b0_mean  <- coef(fit_mean)["(Intercept)"]
  se_mean  <- summary(fit_mean)$coefficients["x", "Std. Error"]
  
  # C. MICE (m = 10, PMM)
  imp_mice <- mice(df_incomp, m = 10, method = "pmm", printFlag = FALSE, seed = 123)
  fit_mice <- with(imp_mice, lm(y ~ x))
  pooled   <- summary(pool(fit_mice))
  b1_mice  <- pooled$estimate[pooled$term == "x"]
  b0_mice  <- pooled$estimate[pooled$term == "(Intercept)"]
  se_mice  <- pooled$std.error[pooled$term == "x"]
  
  # Prepare plotting data
  df_plot <- df_raw |>
    mutate(Status = if_else(missing_mask, "Removed (Missing)", "Observed"))
  
  # Summary text showing both Slope and SE for each method
  slope_summary <- sprintf("CC: %.2f (SE: %.2f) | Mean: %.2f (SE: %.2f) | MICE: %.2f (SE: %.2f)", 
                           b1_cc, se_cc, b1_mean, se_mean, b1_mice, se_mice)
  
  # Scatter plot with highlighted missing points and fitted lines
  p <- ggplot(df_plot, aes(x = x, y = y)) +
    # Points: Observed in slate-blue, Removed in red circles
    geom_point(aes(color = Status, shape = Status, alpha = Status), size = 2) +
    scale_color_manual(values = c("Observed" = "#2c3e50", "Removed (Missing)" = "#e74c3c")) +
    scale_shape_manual(values = c("Observed" = 16, "Removed (Missing)" = 1)) +
    scale_alpha_manual(values = c("Observed" = 0.5, "Removed (Missing)" = 0.8)) +
    
    # 1. True DGP Line (Black Dashed)
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black", linewidth = 2) +
    
    # 2. Complete Cases Line (Blue)
    geom_abline(intercept = b0_cc, slope = b1_cc, color = "#3498db", linewidth = 2) +
    
    # 3. Mean Imputation Line (Orange)
    geom_abline(intercept = b0_mean, slope = b1_mean, color = "#e67e22", linewidth = 2) +
    
    # 4. MICE Line (Purple)
    geom_abline(intercept = b0_mice, slope = b1_mice, color = "#9b59b6", linewidth = 2) +
    
    coord_cartesian(xlim = c(-1.1, 1.1), ylim = c(-3.5, 3.5)) +
    labs(
      title = title_text,
      subtitle = paste(subtitle_text, "\n", slope_summary),
      x = "X", y = "Y"
    ) +
    theme_minimal(base_size = 10) +
    theme(
      legend.position = "none",
      plot.title = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 8.5, color = "gray25")
    )
  
  list(
    plot = p,
    slopes = tibble(
      Scenario = title_text,
      CC = b1_cc, CC_SE = se_cc,
      Mean = b1_mean, Mean_SE = se_mean,
      MICE = b1_mice, MICE_SE = se_mice
    )
  )
}

# ==============================================================================
# 3. Execute the 4 Scenarios
# ==============================================================================


# Scenario 1: MCAR
res0 <- analyze_scenario(
  toy_clean, m_mcary, missing_var = "y",
  title_text = "0. MCAR (Random 40% on Y)",
  subtitle_text = "All methods recover slope. SI overestimates SE.  "
)
plot(res0$plot)

# Scenario 1: MCAR
res1 <- analyze_scenario(
  toy_clean, m_mcar, missing_var = "x",
  title_text = "1. MCAR (Random 40% on X)",
  subtitle_text = "All methods recover slope. SI overestimates SE.  "
)
plot(res1$plot)

# Scenario 2: MAR (Outcome-dependent)
res2 <- analyze_scenario(
  toy_clean, m_mar, missing_var = "x",
  title_text = "2. MAR (X Missing Driven by Y)",
  subtitle_text = "MICE recovers slope. CC and SI don't."
)
plot(res2$plot)

# Scenario 3: Cut X-axis (MNAR on X)
res3 <- analyze_scenario(
  toy_clean, m_cut_x, missing_var = "x",
  title_text = "3. Cut X-axis (MNAR on X: X > 0.25 Missing)",
  subtitle_text = "CC recovers line. MICE (no donors above 0.25) and SI fail."
)
plot(res3$plot)

# Scenario 4: Cut Y-axis (MNAR on Y)
res4 <- analyze_scenario(
  toy_clean, m_cut_y, missing_var = "y",
  title_text = "4. Cut Y-axis (MNAR on Y: Y > 0.50 Missing)",
  subtitle_text = "Horizontal slice: Truncates outcome. ALL METHODS FAIL."
)
plot(res4$plot)