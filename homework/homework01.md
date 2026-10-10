# Homework 01

This homework is a short exercise in basic data wrangling using the basketball.csv dataset (copy it from homework datasets subfolder).

Group by `shot_type` and `movement` and compute:
   * Total attempts ($n$)
   * Mean distance (m)
   * Mean angle (degrees)
   * Standard error of mean angle ($\text{SE} = \frac{\text{SD}}{\sqrt{n}}$)

Display the output as a formatted table.

Formalize the sample standard error in displayed LaTeX: $$\text{SE}(\bar{x}) = \frac{s}{\sqrt{n}} = \sqrt{\frac{\sum_{i=1}^n (x_i - \bar{x})^2}{n(n-1)}}$$. 

Visualize the relationship between **shot distance** and **shot angle**, segmented by `shot_type`. Provide a 3-sentence substantive interpretation of the relationship.

Your submission must be organized strictly as an R Project with the following folder structure:

```text
hw-01-[student_id]/
├── hw-01.Rproj              # Mandatory project root anchor
├── data/
│   └── basketball.csv       # Raw dataset
└── hw-01-report.qmd         # Main reproducible Quarto report
```

Allowed additional packages:

```text
tidyverse
here::here() for paths
knitr::kable() for table formatting
```

To receive a **PASS** in initial screening:
* The project opens cleanly via `hw-01.Rproj` with no absolute path calls.
* `.qmd` renders to completion in reasonable time and with zero errors.
* The generated output is a clean, 1-page PDF document containing the equation, table, and figure.
