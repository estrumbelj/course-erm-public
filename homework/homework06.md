# Homework 06

Diagnose and remedy non-Gaussian model failure on overdispersed ecological count data using Generalized Linear Models (GLMs).

## Task Overview

Using the provided dataset `insects.csv` (toy dataset, containing trap catch count with temperature as predictor; available in datasets folder), complete the following:

1. **Poisson GLM & Diagnostic Failure:**
   * Fit a standard Poisson regression model predicting insect count from temperature using the log link function.
   * Audit the model using `DHARMa` simulation-based residuals.
   * Identify and explain why the Poisson model is not appropriate for this dataset.

2. **Alternative Model Formulation & Re-Diagnosis:**
   * Fit an alternative GLM with a more appropriate distribution.
   * Re-evaluate the new model using `DHARMa`.

3. **Model Evaluation against the Null Model:**
   * Compare your candidate model from (2) against an intercept-only null model using **AIC** or cross-validated log scores.
   * Explain whether environmental temperature provides substantial predictive signal beyond the baseline mean.
   * Extract the temperature slope coefficient for temperature and interpret its meaning.

---

## Required Project Structure

```text
erm-portfolio-[student_id]/hw-06/
├── hw-06.Rproj              # Mandatory project root anchor
├── data/
│   └── insects.csv          # Raw dataset
└── hw-06-report.qmd         # Main reproducible Quarto report

Allowed additional packages:

```text
tidyverse
here::here() for paths
patchwork
MASS
```

To receive a **PASS** in initial screening:

* The project opens cleanly via `hw-06.Rproj` with no absolute path calls.
* `.qmd` renders to completion in reasonable time and with zero errors.
* The generated output is a clean, 1-page PDF document containing whatever you feel is essential for communicating your work and results.