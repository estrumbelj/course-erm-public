library(ggplot2)
library(dplyr)
library(tidyr)

# 1) LOAD AND CLEAN ------------------------------------------------------------

# Load the dataset directly
penguins_raw <- read.csv("https://raw.githubusercontent.com/allisonhorst/palmerpenguins/main/inst/extdata/penguins.csv")

# Clean missing values for our primary variables
penguins <- penguins_raw |>
  filter(!is.na(body_mass_g), !is.na(flipper_length_mm), !is.na(sex), !is.na(species))

# 2) FIT MODEL USING MLE/OLS ---------------------------------------------------
# Standard output shows:
# - summary of the distribution of residuals,
# - coefficient estimates and SE,
# - R2,
# - and a few things we'll ignore for now (t value, Pr(>|t|), DF, F-statistic, p-value).

model_penguins <- lm(body_mass_g ~ flipper_length_mm, data = penguins)
print(summary(model_penguins))

# we can recover all parameters from the model
coef_estimates <- coef(model_penguins)
sigma_estimate <- summary(model_penguins)$sigma
r_squared      <- summary(model_penguins)$r.squared

cat("Intercept (beta0):", round(coef_estimates[1], 2), "\n")
cat("Slope (beta1₁):    ", round(coef_estimates[2], 2), "\n")
cat("Residual Std. Dev (s2):", round(sigma_estimate, 2), "g\n")
cat("Coefficient of Determination (R2):", round(r_squared, 4), "\n")

# 3) BOOTSTRAPPING UNCERTAINTY -------------------------------------------------
# - Non-parametric bootstrap generalizes to tabular data (we resample entire rows).
# - We can bootstrap any estimate provided by lm().
# - Even with percentile CIs, we get a close match to output from lm().
# - We can additionally quantify uncertainty in residual standard deviation (sigma from model),
#   while this is not readily available from lm().


library(boot)

# bootstrap -----
boot_lm <- function(data, indices) {
  
  # bootstrap resample
  boot_data <- data[indices, ]
  
  # run lm() to get estimates
  fit <- lm(body_mass_g ~ flipper_length_mm, data = boot_data)

  # extract estimates of interest
  c(coef(fit),
    summary(fit)$sigma
  )
}

boot_results <- boot(
  data = penguins,
  statistic = boot_lm,
  R = 1000
)

# Bootstrap SE and 95% CI
boot_se <- apply(boot_results$t, 2, sd)
boot_ci95 <- apply(
  boot_results$t,
  2,
  quantile,
  probs = c(0.025, 0.975)
)

# Standard lm() results
model_summary <- summary(model_penguins)$coefficients
model_ci95 <- confint(model_penguins)

# Comparison table
comparison <- data.frame(
  Parameter = c(
    "Intercept",
    "flipper_length_mm",
    "sigma"
  ),
  Bootstrap_SE = boot_se,
  OLS_SE = c(
    model_summary["(Intercept)", "Std. Error"],
    model_summary["flipper_length_mm", "Std. Error"],
    NA
  ),
  Bootstrap_CI_Lower = boot_ci95[1,],
  Bootstrap_CI_Upper = boot_ci95[2,],
  OLS_CI_Lower = c(model_ci95[,1], NA),
  OLS_CI_Upper = c(model_ci95[,2], NA)
)

print(comparison)

# 4) MODEL AUDIT ---------------------------------------------------------------

# First, we'll audit the four assumptions that are explicit in the formulation 
# of the model y_i ~iid N(beta^T x_i | sigma2):

# - Assuming a linear functional relationship between the inputs x and expectation of target y.
# - Normally distributed residuals.
# - Homoskedasticity (variance the same everywhere).
# - Residuals are independent.

# LINEARITY --------------------------------------------------------------------
# - Standard check is to look at the plot of the residuals against fitted values.
# - If linearity fails, the models is misspecified and estimates are biased. That
#   is, our parameters are not estimating what we want them to estimate.
# - Biased estimates can also lead to incorrect SE/CIs and predictive uncertainty.
# - Example: The red line should be horizontal at 0, but it is not. The misspecification
#   doesn't look very serious, but probably enough to warrant the exploration
#   of a model that better explains what is going on at the edges.
plot(model_penguins, which = 1)

# Toy example of obvious failure: Y = 2*X^2 + noise
set.seed(1)
toy_x <- runif(100, -3, 3)
toy_y <- 2 * toy_x^2 + rnorm(100, sd = 2)
toy_model <- lm(toy_y ~ toy_x)
plot(toy_x, toy_y)
abline(toy_model) # lm() fit
plot(toy_model, which = 1)

# NORMALITY --------------------------------------------------------------------
# - Standard check is to look at the quantile-quantile plot of
#   theoretical vs observed residuals. Or just look at the distribution.
# - If residuals are not normally distributed, small sample SE/CIs, etc. may be
#   unreliable. For larger samples, this still affects predictive uncertainty.
# - Estimates remain unbiased/consistent.
hist(model_penguins$residuals)
plot(model_penguins, which = 2)

# Toy example of obvious failure: Y = 2*X + gamma noise
set.seed(1)
toy_x <- runif(100, -3, 3)
toy_y <- 2 * toy_x + rgamma(100, 1, 4)
toy_model <- lm(toy_y ~ toy_x)
plot(toy_x, toy_y)
abline(toy_model) # lm() fit
hist(toy_model$residuals)
plot(toy_model, which = 1)

# HOMOSKEDASTICITY -------------------------------------------------------------
# - Obvious issues can be identified with the residual against fitted plot from
#   before. We can also plot residuals against other values, such as individual
#   input variables.
# - Failure can affect uncertainty (SE/CIs, predictive uncertainty).
# - Estimates remain unbiased/consistent.
plot(model_penguins, which = 1)

# toy example of failure
toy_x_funnel <- seq(1, 10, length.out = 150)
toy_y_funnel <- 3 * toy_x_funnel + rnorm(150, mean = 0, sd = 0.8 * toy_x_funnel)
funnel_model <- lm(toy_y_funnel ~ toy_x_funnel)
plot(funnel_model, which = 1)

# INDEPENDENCE OF ERRORS -------------------------------------------------------
# - Dependence of residuals is typically positive (temporal, spatial, clustering)
#   and results in underestimation of SEs/CIs.
# - In general, it is impossible to show complete independence, as there are infinitely
#   manys ways of how residuals can be dependent. 
#   A typical check is to order the residuals according to another variable
#   (index in dataset, time, input variable...) and test for autocorrelation.
# - NOTE1: Randomizing the order of rows in tabular data will randomize the order
#   of the residuals and obscure any dependency. Note that this does not fix the problem
#   it only prevents us from seeing it.
# - NOTE2: Testing for independence of errors is not an exception in this respect. 
# All of these diagnostics (and other diagnostics as well) are tools for diagnosing 
# specific failure modes out out a continuum of how things can fail. Passing all 
# the diagnostics is not proof that the model does not have any issues. However,
# using standard checks elevates our work to standards of most venues and makes
# it "good enough".
# Example: Penguins feature autocorrelation at even (!) lags up to 16. This suggests
# that we are either missing an explanatory variate or that there is indeed some 
# dependency structure (clusters of penguins).
acf(residuals(model_penguins), main = "Autocorrelation of Penguin Residuals")

# 5) (NEAR)MULTICOLINEARITY ----------------------------------------------------
# - MLE estimation of the standard linear model requires us to invert the matrix
#   t(X) %*% X (matrix of input variables). If the matrix doesn't have full rank,
#   the computation will fail.
# - Most typical example is when we have many more input variables than observations
#   or when two features are identical.
# - Strongly correlated inputs, even if not perfectly correlated, will make 
#   parameter estimation less stable because a single observation can shift the
#   coefficient from one input variable to its correlated counterpart.

# lm() detects redundancy in design matrix and omits one variable.
penguins$flipper_length_copy <- penguins$flipper_length_mm

model_crash <- lm(
  body_mass_g ~ flipper_length_mm + flipper_length_copy,
  data = penguins
)

summary(model_crash)

# Almost identical feature will results in unstable coefficient allocation. Note
# that the difference in coefficients is stable. Run multiple times to observe
# the instability. Also observe how the intercept estimate is stable.

penguins$flipper_length_almost <- 
  penguins$flipper_length_mm + rnorm(
    nrow(penguins), mean = 0, sd = 0.01
  )

model_near <- lm(
  body_mass_g ~ flipper_length_mm + flipper_length_almost,
  data = penguins
)

summary(model_near)

# 6) SIMPSONS PARADOX ----------------------------------------------------------
# Definition: Simpson’s paradox occurs when an association observed across several 
# subgroups reverses direction when the subgroups are combined, or vice versa.
# EXAMPLE: For each species, larger bill depth = larger bill length, but for all
# species combined, the relationship is reversed.

ggplot(penguins, aes(x = bill_length_mm, y = bill_depth_mm)) +
  # Points colored by species
  geom_point(aes(color = species), alpha = 0.7, size = 2) +
  # Overall aggregate regression line (NAIVE)
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dashed", linewidth = 1.1) +
  # Species-specific regression lines (CONTROLLED)
  geom_smooth(aes(color = species, group = species), method = "lm", se = FALSE, linewidth = 1.2) +
  annotate("text", x = 52, y = 20.5, label = "Overall: β̂ = -0.08 (Negative)", color = "black", fontface = "bold") +
  annotate("text", x = 35, y = 14.5, label = "Within Species: β̂ = +0.20 (Positive)", color = "#2980b9", fontface = "bold") +
  labs(
    title = "Simpson's Paradox: Confounding by Species",
    subtitle = "Omitting species completely inverts the biological scaling law",
    x = "Bill Length (mm)",
    y = "Bill Depth (mm)",
    color = "Species"
  ) +
  theme_minimal(base_size = 13)

# 7) OUTLIERS, LEVERAGE, AND INFLUENTIAL POINTS --------------------------------
# - Linear fit can be strongly affected by even a single observation, if that
#   observation is a highly influential point.
# - A highly influential point must be both an outlier and have high leverage.
#   Such points should be removed purely on statistical grounds, because of how
#   they affect the fit, even if they are plausible observations. Alternatively,
#   the model can be extended to handle them.
#
# "Outlierness": How unusual an observation's response (y-value) is relative to
# the value predicted by the regression model. Commonly assessed using
# residuals.
#
# Leverage: How unusual an observation's predictor value(s) are compared with
# the other observations. High-leverage points have the potential to pull the
# fitted regression line toward themselves. It is defined as the i-th diagonal element
# of the hat matrix H = X(X^TX)^{-1}X^T, where X is the model matrix.

# EXAMPLE: Four points and how they'd change the linear fit:

set.seed(123)
dat <- data.frame(x = runif(40, -2, 2))
dat$y <- 2 * dat$x + rnorm(40, sd = 0.8)
model_original <- lm(y ~ x, data = dat)

# Add four observations: low/high leverage × low/high residual
y_pred <- predict(model_original, newdata = data.frame(x = c(0, 6)))

new_points <- data.frame(
  Type = c("Low leverage, low residual", "Low leverage, high residual",
           "High leverage, low residual", "High leverage, high residual"),
  x = c(0, 0, 6, 6),
  y = c(y_pred[1] + 0.1, y_pred[1] + 8,
        y_pred[2] + 0.1, y_pred[2] + 7)
)

# Fit models with each added point and plot regression lines
models <- lapply(seq_len(nrow(new_points)), function(i) {
  lm(y ~ x, data = rbind(dat, new_points[i, c("x", "y")]))
})

line_data <- do.call(rbind, lapply(seq_along(models), function(i) {
  grid <- data.frame(x = seq(-2.5, 6.5, length.out = 200))
  data.frame(
    x = grid$x,
    Fitted = c(predict(model_original, grid), predict(models[[i]], grid)),
    Model = rep(c("Original", "Augmented"), each = nrow(grid)),
    Type = new_points$Type[i]
  )
}))

ggplot() +
  geom_point(data = dat, aes(x, y), color = "grey65") +
  geom_line(data = line_data,
            aes(x, Fitted, color = Model, linetype = Model),
            linewidth = 1) +
  geom_point(data = new_points, aes(x, y), color = "darkorange", size = 3) +
  facet_wrap(~Type, ncol = 2) +
  scale_color_manual(values = c(Original = "blue", Augmented = "red")) +
  scale_linetype_manual(values = c(Original = "dashed", Augmented = "solid")) +
  coord_cartesian(xlim = c(-2.5, 6.5)) +
  labs(title = "Effect of Adding Individual Observations",
       x = "x", y = "y", color = "Regression", linetype = "Regression") +
  theme_minimal() +
  theme(legend.position = "bottom")

# The typical diagnostic tool is plotting standardized residuals against leverage.
# The points beyond the dashed line (Cook's distance) are considered problematic.
# Example: Plot for our dataset with all points added (only one is clearly problematic):
dat_augmented <- rbind(dat, new_points[, c("x", "y")])
model_augmented <- lm(y ~ x, data = dat_augmented)
plot(model_augmented, which = 5)