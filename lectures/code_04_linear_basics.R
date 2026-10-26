library(ggplot2)
library(dplyr)

# 1) INTRO ---------------------------------------------------------------------

# Load the dataset directly
penguins_raw <- read.csv("https://raw.githubusercontent.com/allisonhorst/palmerpenguins/main/inst/extdata/penguins.csv")

# Clean missing values for our primary variables
penguins <- penguins_raw |>
  filter(!is.na(body_mass_g), !is.na(flipper_length_mm), !is.na(sex), !is.na(species))

# Quick inspection of the observational units
glimpse(penguins)

# 2) MARGINAL DISTRIBUTION OF RESPONSE -----------------------------------------

mean_mass <- mean(penguins$body_mass_g)
sd_mass   <- sd(penguins$body_mass_g)
n         <- nrow(penguins)

cat("Marginal Mean Body Mass:", round(mean_mass, 1), "g\n")
cat("SE:", round(sd_mass / sqrt(n), 1), "g\n")
cat("Marginal Std. Deviation:", round(sd_mass, 1), "g\n")

# 3) SCATTERPLOT AND LINEAR FIT ------------------------------------------------

ggplot(penguins, aes(x = flipper_length_mm, y = body_mass_g)) +
  geom_point(alpha = 0.6, color = "#2c3e50", size = 2) +
  # 1. Null / Marginal Mean Baseline (Model 0)
  geom_hline(yintercept = mean_mass, linetype = "dashed", color = "#e74c3c", linewidth = 1) +
  annotate("text", x = 172, y = mean_mass + 150, 
           label = paste0("Null Model M₀: E[Y] = Ȳ = ", round(mean_mass, 0), " g"), 
           color = "#e74c3c", hjust = 0, fontface = "bold", size = 3.8) +
  # 2. Linear Conditional Fit (Model 1)
  geom_smooth(method = "lm", se = FALSE, color = "#2980b9", linewidth = 1.2) +
  annotate("text", x = 185, y = 5800, 
           label = "Conditional Model E[Y | X] = β0 + β1 X", 
           color = "#2980b9", hjust = 0, fontface = "bold", size = 3.8) +
  labs(
    title = "Moving from Marginal Average to Conditional Relationship",
    subtitle = "Palmer Archipelago Penguins (n = 333) | Comparing Model 0 (Null) vs. Model 1 (Linear)",
    x = "Flipper Length (mm)",
    y = "Body Mass (g)"
  ) +
  theme_minimal(base_size = 13)

# 4) FITTING A LINEAR MODEL TO PENGUINS DATA -----------------------------------

# Fit the simple linear regression model
model_penguins <- lm(body_mass_g ~ flipper_length_mm, data = penguins)


# 4.1) visualize residuals -----------------------------------------------------

# Add fitted values and residuals to the dataframe
penguins_plot <- penguins |>
  mutate(
    y_hat = predict(model_penguins),
    residual = body_mass_g - y_hat
  )

# Select a small random subset to highlight individual vertical residuals
set.seed(1)
highlight_sample <- penguins_plot |> slice_sample(n = 25)

ggplot(penguins_plot, aes(x = flipper_length_mm, y = body_mass_g)) +
  geom_point(alpha = 0.35, color = "gray50", size = 1.8) +
  # Fitted regression line
  geom_line(aes(y = y_hat), color = "#2980b9", linewidth = 1.2) +
  # Highlighted sample points
  geom_point(data = highlight_sample, color = "#2c3e50", size = 2.2) +
  # Vertical residual error lines for the sample
  geom_segment(
    data = highlight_sample,
    aes(xend = flipper_length_mm, yend = y_hat),
    color = "#e74c3c", linewidth = 0.6, linetype = "solid"
  ) +
  annotate("text", x = 175, y = 6000, 
           label = "ŷ = -5780.8 + 49.7 × Flipper", 
           color = "#2980b9", fontface = "bold", size = 4.5, hjust = 0) +
  annotate("text", x = 175, y = 5600, 
           label = "Red bars = Vertical Residuals (eᵢ)", 
           color = "#e74c3c", size = 3.8, hjust = 0) +
  labs(
    title = "The Fitted Linear Model and Residual Decompositions",
    subtitle = "Minimizing the sum of squared vertical distances ∑ eᵢ²",
    x = "Flipper Length (mm)",
    y = "Body Mass (g)"
  ) +
  theme_minimal(base_size = 13)

# 4.2) Inspect coefficients ----------------------------------------------------
# Basic summary
summary(model_penguins)

# Recover the estimated parameter outputs
coef_estimates <- coef(model_penguins)
sigma_estimate <- summary(model_penguins)$sigma
r_squared      <- summary(model_penguins)$r.squared

cat("Intercept (beta0):", round(coef_estimates[1], 2), "\n")
cat("Slope (beta1₁):    ", round(coef_estimates[2], 2), "\n")
cat("Residual Std. Dev (s2):", round(sigma_estimate, 2), "g\n")
cat("Coefficient of Determination (R2):", round(r_squared, 4), "\n")

# DIY standard error -----------------------------------------------------------
RSS <- sum(residuals(model_penguins)^2)

# Residual degrees of freedom
df_res <- df.residual(model_penguins)
# Estimate residual variance
sigma2 <- RSS / df_res

# Standard error of the slope (no intercept)
SE_manual <- sqrt(sigma2 / sum(penguins$flipper_length_mm))
SE_manual

# 5) BOOTSTRAPPING UNCERTAINTY -------------------------------------------------
library(boot)
# Fit linear regression and extract parameter of interest
boot_slope <- function(data, indices) {
  boot_data <- data[indices, ]
  fit <- lm(body_mass_g ~ flipper_length_mm, data = boot_data)
  coef(fit)[["flipper_length_mm"]]
}

# Execute the pairs bootstrap
boot_results <- boot(
  data = penguins,
  statistic = boot_slope,
  R = 1000
)

boot_se <- sd(boot_results$t)
boot_ci95 <- quantile(boot_results$t, probs = c(0.025, 0.975))

# Standard regression results
model_summary <- summary(model_penguins)$coefficients
model_ci95 <- confint(model_penguins)

# Comparison table
comparison <- data.frame(
  Method = c("Bootstrap", "Standard OLS"),
  SE = c(
    boot_se,
    model_summary["flipper_length_mm", "Std. Error"]
  ),
  CI_Lower = c(
    boot_ci95[1],
    model_ci95["flipper_length_mm", 1]
  ),
  CI_Upper = c(
    boot_ci95[2],
    model_ci95["flipper_length_mm", 2]
  ),
  row.names = NULL
)

print(comparison, digits = 4)