library(lme4)



# 1) TOY DATASET ---------------------------------------------------------------
# 20 individuals, each with a score trajectory measured at weeks 0-5.
# Average trajectory has no slope, but slopes vary a lot between individuals.

set.seed(1)

n_id <- 20; n_wks <- 6; N <- n_id * n_wks
id   <- factor(rep(1:n_id, each = n_wks))
week <- rep(0:5, times = n_id)

# True parameters: NO average time effect (beta_1 = 0), but strong random slopes!
beta_0 <- 50; beta_1 <- 0
s_int  <- 4;  s_slope <- 3; rho <- -0.5; s_res <- 2

# Simulate correlated random intercepts & slopes (2-line Cholesky in Base R)
z0 <- rnorm(n_id); z1 <- rnorm(n_id)
u0 <- s_int * z0
u1 <- s_slope * (rho * z0 + sqrt(1 - rho^2) * z1)

score <- beta_0 + beta_1 * week + u0[id] + u1[id] * week + rnorm(N, 0, s_res)
df_traj <- data.frame(score = score, week = week, id = id)

# 2) Visual: crossing/fanning trajectories around a roughly flat population line

plot(NA, xlim = c(0, 5), ylim = range(df_traj$score),
     xlab = "Week", ylab = "Focus Score",
     main = "20 Individual Trajectories (True Population Slope = 0)")
for (p in levels(df_traj$id)) {
  d_p <- df_traj[df_traj$id == p, ]
  lines(d_p$week, d_p$score, col = adjustcolor("steelblue", 0.55), lwd = 1.5)
}
abline(lm(score ~ week, data = df_traj), col = "red", lwd = 3)

# 3) Best lm() Attempts & The "Random-Intercept Trap" --------------------------

library(lme4)

# Attempt 1: Ignore participant ID completely
m_lm1 <- lm(score ~ week, data = df_traj)
summary(m_lm1)
# FAILS: 
# - Pseudoreplication (treats 120 rows as independent).
# - Poor person-level predictions.
# - Fixed effect slope for 'week' doesn't reveal between individual differences.
# - Poor predictions for new individuals.

# Attempt 2: Control for participant as a fixed intercept (parallel lines!)
m_lm2 <- lm(score ~ week + id, data = df_traj)
summary(m_lm2)
# FAILS: 
# - Allows for different week 0 scores, but forces parallel slopes (all individuals have same slope).
# - Slope differences go into the residuals.
# - Can't predict new individuals.

# Attempt 3: Fixed intercepts + fixed slopes (No Pooling: 40 parameters!)
m_lm3 <- lm(score ~ week * id, data = df_traj)
summary(m_lm3)
# FAILS: 
# - Uses 40 params (overfitting)
# - Can't predict for new individuals.

# Attempt 4: Random-Intercept-Only Mixed Model
m_lm4  <- lmer(score ~ week + (1 | id), data = df_traj)
summary(m_lm4)
# FAILS: 
# - Allows for different week 0 scores, but forces parallel slopes (all individuals have same slope).

# 4) Fit random intercept + random slope (including intercept-slope correlation rho)
m_rs <- lmer(score ~ week + (1 + week | id), data = df_traj)
summary(m_rs)

# bootstrapping
ids_list <- split(df_traj, df_traj$id)

# Non-parametric cluster bootstrap: resample original participants intact
boot_rs <- replicate(500, {
  s <- sample(length(ids_list), replace = TRUE)
  
  # Give each sampled copy a fresh boot_id (1..20) so duplicates aren't merged!
  d_boot <- do.call(rbind, lapply(seq_along(s), function(k) {
    d <- ids_list[[s[k]]]
    d$boot_id <- k
    d
  }))
  
  m_star <- suppressMessages(
    lmer(score ~ week + (1 + week | boot_id), data = d_boot)
  )
  
  c(beta_week = fixef(m_star)[["week"]],
    sd_slope  = sqrt(diag(VarCorr(m_star)$boot_id))[["week"]])
})

# 95% non-parametric bootstrap CIs
apply(boot_rs, 1, quantile, probs = c(0.025, 0.975))


# (Built-in lme4 shortcut that does the exact same thing:)
confint(m_rs, method = "boot", nsim = 500, signames = FALSE)

# 4) Unbalanced data -----------------------------------------------------------
# Random effects easily deal with missing observations.

# ==============================================================================
# 1. CREATE DROPOUTS from df_traj (Scenario 3)
#    - IDs  1-14: complete (6 weeks)
#    - IDs 15-18: drop out early (only weeks 0 & 1)
#    - IDs 19-20: drop out immediately (only week 0)
# ==============================================================================
id_num <- as.numeric(as.character(df_traj$id))
keep   <- (id_num <= 14) | (id_num %in% 15:18 & df_traj$week <= 1) | (id_num %in% 19:20 & df_traj$week == 0)

df_obs    <- df_traj[keep, ]
df_future <- df_traj[!keep, ] # Held-out future weeks for the 6 dropouts!
tapply(df_obs$score, list(df_obs$week, df_obs$id), mean)


# ==============================================================================
# 2. COMPARE THREE APPROACHES ON MESSY DATA
# ==============================================================================

# True participant slopes from Scenario 3 simulation (beta_1 + u1)
true_slopes <- beta_1 + u1

m_nopool <- lm(score ~ week * id, data = df_obs)
ols_slopes <- sapply(levels(df_obs$id), function(p) {
  d <- df_obs[df_obs$id == p, ]
  if (nrow(d) < 2) NA_real_ else coef(lm(score ~ week, data = d))[["week"]]
})

# B. Random-Slope LMM: keeps all 20 participants and shrinks noisy dropouts
set.seed(123)
rmse_sim <- replicate(100, {
  z0 <- rnorm(n_id); z1 <- rnorm(n_id)
  u0s <- 4 * z0; u1s <- 3 * (-0.5 * z0 + sqrt(1 - 0.5^2) * z1)
  ts <- 0 + u1s
  y  <- 50 + u0s[df_traj$id] + u1s[df_traj$id] * df_traj$week + rnorm(nrow(df_traj), 0, 2)
  
  d_sim <- df_traj[keep, ]
  d_sim$score <- y[keep]
  
  ols <- sapply(levels(d_sim$id)[1:18], function(p) {
    coef(lm(score ~ week, data = d_sim[d_sim$id == p, ]))[["week"]]
  })
  lmm <- coef(suppressMessages(lmer(score ~ week + (1 + week | id), data = d_sim)))$id[, "week"]
  
  c(OLS_1_18 = sqrt(mean((ols - ts[1:18])^2)),
    LMM_1_18 = sqrt(mean((lmm[1:18] - ts[1:18])^2)),
    OLS_2wk  = sqrt(mean((ols[15:18] - ts[15:18])^2)),
    LMM_2wk  = sqrt(mean((lmm[15:18] - ts[15:18])^2)))
})

rowMeans(rmse_sim)