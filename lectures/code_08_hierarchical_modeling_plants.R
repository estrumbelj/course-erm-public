# Soil warming treatment (trt = 1 vs. control trt = 0) increases plant height. 
# We have 10 field sites (5 warmed, 5 control) and measure 20 plants per site.
# A total of 200 rows.
# Actual effect is 0 (it doesn't help).
# But there is variability between sites due to unmeasured microclimate.
# Within-site variability is smaller.

library(lme4)
library(DHARMa)

# 1) TOY SOIL WARMING DATASET --------------------------------------------------

set.seed(0)

n_sites <- 10    
n_per_site <- 20  
N <- n_sites * n_per_site

site <- factor(rep(1:n_sites, each = n_per_site))
trt  <- rep(c(0, 1), each = (n_sites / 2) * n_per_site)

beta_0 <- 50
beta_trt <- 0
sigma_site <- 8      # Strong site-to-site variation
sigma_resid <- 4     # Plant-level variation within a site

u_site <- rnorm(n_sites, mean = 0, sd = sigma_site)
height <- beta_0 + beta_trt * trt + u_site[site] + rnorm(N, mean = 0, sd = sigma_resid)

df <- data.frame(height = height, trt = trt, site = site)

# 2) Quick visual: plants within the same site move together -------------------

boxplot(height ~ site, data = df, col = ifelse(1:10 <= 5, "lightblue", "salmon"),
        xlab = "Field Site", ylab = "Plant Height (cm)",
        main = "Blue = Control, Red = Warmed (True Effect = 0)")

# 3) Best Attempt Using lm() ---------------------------------------------------

m_naive <- lm(height ~ trt, data = df)
summary(m_naive)

# Is it only a coincidence? How often do we find something?

p_vals <- replicate(500, {
  u <- rnorm(10, 0, 8)
  y_sim <- 50 + 0 * trt + u[site] + rnorm(N, 0, 4)
  summary(lm(y_sim ~ trt))$coefficients["trt", "Pr(>|t|)"]
})
mean(p_vals < 0.05) # ~62% false positives instead of 5%!

# 4) Why not just control for site as a fixed effect in lm()? ------------------

m_fe1 <- lm(height ~ site + trt, data = df)
summary(m_fe1) # Look at 'trt': NA!

m_fe2 <- lm(height ~ trt + site, data = df)
summary(m_fe2)

# 5) Naive Bootstrap (treats 200 plants as independent) FAILS! -----------------
boot_naive <- replicate(1000, {
  idx <- sample(nrow(df), replace = TRUE)
  coef(lm(height ~ trt, data = df[idx, ]))["trt"]
})
sd(boot_naive) # ~1.3 cm (Matches m_naive's false confidence!)

# Cluster Bootstrap (resamples whole sites within each arm)
sites_list <- split(df, df$site)
boot_cluster <- replicate(1000, {
  sampled <- c(sample(1:5, 5, replace = TRUE), sample(6:10, 5, replace = TRUE))
  d_boot <- do.call(rbind, sites_list[sampled])
  coef(lm(height ~ trt, data = d_boot))["trt"]
})
sd(boot_cluster)

# 6) Mixed model fit -----------------------------------------------------------

m_lmm <- lmer(height ~ trt + (1 | site), data = df, REML = F)
summary(m_lmm)

# - Compact fit & clean residuals: Fit via ML with only 4 parameters
# - Fixed effects: Warmed sites happen to average 6.99 cm lower, purely from site-to-site sampling luck.
# - No false positive: Because lmer uses the site-aware SE = 5.574 (t = -1.253), it correctly avoids rejecting trt = 0

# A. Overall hierarchical residual diagnostics (re-simulates REs + residuals)
sim_res <- simulateResiduals(m_lmm, plot = TRUE)

# B. Residual checks grouped by treatment and by site
plotResiduals(sim_res, form = df$site, xlab = "Site",
              main = "DHARMa Residuals by Site")

# C. Influential clusters: Cook's distance dropping 1 whole site at a time
infl_site <- influence(m_lmm, groups = "site")
cd_site   <- cooks.distance(infl_site)

plot(seq_along(cd_site), as.numeric(cd_site), type = "h", lwd = 2,
     xaxt = "n", xlab = "Site", ylab = "Cook's Distance",
     main = "Site-Level Influence (Cook's D)")
axis(1, at = seq_along(cd_site), labels = names(cd_site))
abline(h = 4 / length(cd_site), lty = 2, col = "red") # 4/K heuristic line