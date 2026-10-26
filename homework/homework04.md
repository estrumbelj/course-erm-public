# Homework 04

As shown below, load the *mammals* dataset from mass and fit a linear model with brain mass (g) as the target variable and body mass as the input variable (kg):

```text
data(mammals, package = "MASS")
plot(brain ~ body, data = mammals)
model <- lm(brain ~ body, data = mammals)
```
Inspect the data and model and diagnose potential influential points that prevent a sensible model fit. Justify why they are influential and remove them.

Fit the model again, this time on the data with influential points removed. Diagnose if the assumptions of linearity, normality of residuals, homoskedasticity, and independence of residuals are potentially violated. For each of these 4 dimensions supply at least one supporting plot or numerical justification. Report the body coefficient and intercept estimates (quantify uncertainty).

Required Project Structure:

```text
hw-04-[student_id]/
├── hw-04.Rproj              # Mandatory project root anchor
└── hw-04-report.qmd         # Main reproducible Quarto report
```

Allowed additional packages:

```text
tidyverse
here::here() for paths
patchwork
boot
```
To receive a **PASS** in initial screening:

* The project opens cleanly via `hw-04.Rproj` with no absolute path calls.
* `.qmd` renders to completion in reasonable time and with zero errors.
* The generated output is a clean, 1-page PDF document containing the captioned figure.