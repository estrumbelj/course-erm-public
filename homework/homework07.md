# Homework 07

Diagnose missing data mechanisms using logistic regression and quantify uncertainty via Bootstrap-before-Multiple-Imputation with `mice`.

## Task Overview

Using the built-in dataset `datasets::airquality`, complete the following:

1. **Missingness Exploration & MCAR Check via Logistic Regression:**
   * Quantify and visualize the missingness pattern across all variables.
   * Create a binary missingness indicator for `Ozone` (`1` = missing, `0` = observed) and fit a logistic regression model predicting missingness from the fully observed covariates (`Wind`, `Temp`, `factor(Month)`, and `Day`).
   * Evaluate the model and decide whether the data are consistent with **MCAR** or show evidence of **MAR**, and briefly explain why observed data alone cannot rule out **MNAR**.

2. **Bootstrap before Multiple Imputation:**
   * Implement the Boot-MI procedure: draw $B = 200$ bootstrap resamples (with replacement) from the original incomplete dataset, run `mice` ($m = 1$ imputations per bootstrap sample) within each bootstrap replicate, fit a Gamma regression (log link) model on each imputed dataset (Ozone ~ Wind + Temp), and average the regression coefficients within each bootstrap replicate.
   * Compute 95% percentile bootstrap confidence intervals across the $B$ bootstrap estimates for the `Temp` and `Wind` slope coefficients.
   * Compare the point estimates and 95% confidence interval widths across Complete-Case Analysis (removing all rows with Ozone, Wind or Temp missing). NOTE: Compute the confidence intervals in the same bootstrap loop, dropping rows instead of imputing.

---

## Required Project Structure

```text
erm-portfolio-[student_id]/hw-07/
├── hw-07.Rproj              # Mandatory project root anchor
└── hw-07-report.qmd         # Main reproducible Quarto report

Allowed additional packages:

```text
tidyverse
here::here() for paths
patchwork
mice
```

To receive a **PASS** in initial screening:

* The project opens cleanly via `hw-07.Rproj` with no absolute path calls.
* `.qmd` renders to completion in reasonable time and with zero errors.
* The generated output is a clean, 1-page PDF document containing whatever you feel is essential for communicating your work and results.