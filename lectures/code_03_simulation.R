library(dplyr)
library(ggplot2)



# EXAMPLE 1: Estimating the mean and variance of a distribution with simulation:
set.seed(1) # set seed for reproduciblity (Fallibilism audit trail)
theta <- 0.5
n     <- 50
y     <- rbinom(n = n, size = 1, prob = theta)  # our theoretical DGP

print(mean(y))  # E[X] = 0.5
print(var(y))   # Var[X] = 0.25

# EXAMPLE 2: Finding the n where P(error <= 0.15 | y) <= 0.95

library(ggplot2)
library(dplyr)

# Experimental grid
n_values   <- c(10, 15, 20, 30, 50, 70, 100, 200, 500, 1000)
p_values   <- c(0.10, 0.20, 0.3, 0.50)
m          <- 10000   # Number of simulated experiments
target_tol <- 0.15   # Maximum acceptable error (+/- 15%)

sim_grid <- expand.grid(n = n_values, p = p_values)

res <- NULL

for (i in 1:nrow(sim_grid)) {
  n <- sim_grid$n[i]
  p <- sim_grid$p[i]
  
  is_error <- numeric(m)
  for (j in 1:m) {
    p_hat <- rbinom(1, size = n, prob = p) / n
    abs_err  <- abs(p_hat - p)
    is_error[j] <- abs_err > target_tol

  }
  rate    <- mean(is_error)
  rate_se <- sqrt(rate * (1 - rate) / m)
  
  res <- rbind(res, data.frame(n = n, p = p, rate = rate, rate_se = rate_se))

}

# Visualize the error rate vs. sample size
ggplot(res, aes(x = n, y = rate, color = factor(p), group = factor(p))) +
  geom_line(linewidth = 1) +
  # Error bars representing +/- 1 SE of the estimated error rate
  geom_errorbar(
    aes(ymin = rate - 2 * rate_se, ymax = rate + 2 * rate_se),
    width = 0.05,
    linewidth = 0.7,
    alpha = 0.8
  ) +
  geom_point(size = 2.5) +
  # Target error rate: 5% (0.05)
  geom_hline(yintercept = max_risk, linetype = "dashed", color = "red", linewidth = 0.9) +
  annotate("text", x = 300, y = 0.06, label = "5% risk of abs. error exceeding 15%", color = "red", fontface = "bold") +
  scale_x_log10(breaks = n_values) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title = "Estimating the Error Rate via Simulation",
    subtitle = paste0("P(|p̂ - p| > 0.15) across m = ", format(m, big.mark = ","), " runs with ±1 SE bars"),
    x = "Sample Size n (log scale)",
    y = "Error Rate (P(|p̂ - p| > 0.15))",
    color = "Proportion (p)"
  ) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank())


# Experiment reveals several things:
# - Worst-case we need about 50 to drop critical error rate below 5%.
# - If true parameter is closer to 0 (1), the results will be more favorable.
# - We can observe the 1 / sqrt(n) drop in error.
# - The simulation is in itself a sampling exercise and has Tier 4 error, which we quantify with 95% CI.
# - In simulation, I can make the stochastic error arbitrarily small, by increasing sample size.

# EXAMPLE 3: Illustrating Tier 4 error due to sampling

set.seed(123)

# Five researchers each draw n = 50 marbles from the same bag (p = 0.50),
# and using the same exact sampling procedure:

researcher_draws <- replicate(5, rbinom(n = 1, size = 50, prob = 0.50) / 50)
data.frame(
  Researcher = paste("Researcher", LETTERS[1:5]),
  Sample_Proportion = researcher_draws,
  Error = researcher_draws - 0.50
)

# EXAMPLE 3: Quantifying estimator error with a simulation when DGP is known

set.seed(0)
n <- 50
p <- 0.5

estimates <- numeric(m)
for (i in 1:m) {
  estimates[i] <- rbinom(1, size = n, prob = p) / n
}

mean(estimates)
2 * sd(estimates)
hist(estimates)

# EXAMPLE 4: Our beads data
set.seed(1)
y <- sample(0:1, 50, rep = T)
n <- length(y)
B <- 2000     # How many bootstrap replications (higher is better in most cases)
alpha <- 0.05 # Risk for CI

# Resample with replacement and compute the statistic (e.g., the mean)
boot_estimates <- numeric(B)
for (b in 1:B) {
  resample <- sample(y, size = n, replace = TRUE)
  boot_estimates[b] <- mean(resample)
}

# Compute the point estimate, standard error, and 95% percentile CI
est   <- mean(y)
SE    <- sd(boot_estimates)
ci_lb <- quantile(boot_estimates, probs = alpha / 2, names = FALSE)
ci_ub <- quantile(boot_estimates, probs = 1 - alpha / 2, names = FALSE)

cat(sprintf("%.2f +/- %.2f OR %.2f [%.2f, %.2f]\n", est, SE, est, ci_lb, ci_ub))
