# Homework 03

Extend the bootstrap with percentile intervals from the lab from vectors to data frames and compare with package boot BCa on the basketball dataset:

* Extend `my_bootstrap()` from the lab to resample entire rows with replacement from a `data.frame` (i.e., sampling row indices $1, \dots, n$), preserving joint dependencies across columns.
* The function (statistic) supplied must accept arbitrary statistical functionals that take a (resampled) data.frame and return a scalar estimate.

Use your implementation and to estimate and provide 95% CI for (**for NBA games only!**):

   * Mean shot distance
   * Proportion of transition shots (`Transition` $\in \{0, 1\}$)
   * Pearson correlation between shot angle and distance 
   * Difference in Median Shot Distance of Transition and non-Transition shots
     $$\Delta_{\text{median}} = \operatorname{Median}(\text{Distance}_{\text{Transition} = 1}) - \operatorname{Median}(\text{Distance}_{\text{Transition} = 0})$$

Repeat the estimation with boot package (BCa intervals).

Build a publication-grade, self-contained 4-panel figure (one for each statistic above). For each chosen statistic, compare your percentile and boot package 95% CI.

In a concise paragraph, compare the Percentile and BCa intervals. Identify where they agree, where they diverge, and why.

Required Project Structure:

```text
hw-03-[student_id]/
├── hw-03.Rproj              # Mandatory project root anchor
├── data/
│   └── basketball.csv       # Raw dataset
└── hw-03-report.qmd         # Main reproducible Quarto report
```

Allowed additional packages:

```text
tidyverse
here::here() for paths
patchwork
boot
```
To receive a **PASS** in initial screening:

* The project opens cleanly via `hw-03.Rproj` with no absolute path calls.
* `.qmd` renders to completion in reasonable time and with zero errors.
* The generated output is a clean, 1-page PDF document containing the captioned figure.