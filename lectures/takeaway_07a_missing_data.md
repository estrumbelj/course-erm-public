---
title: 'Lecture Takeaway: Dealing with Missing Data'
output:
  html_document:
    df_print: paged
---

> *"The absence of phenomena is itself a phenomenon."*
>
> — **Howard Wainer**, *“Graphical Visions from William Playfair to John Tukey”* (1990).

---

### Why Do Our Data Go Missing?

We will first classify missingness along two complementary dimensions. The first dimension identifies *why* information becomes unavailable:

| Source | What it encompasses | Examples |
|---|---|---|
| **1. Human and behavioral** | Participant actions, health conditions, and researcher or clerical errors. | Survey refusal, attrition, noncompliance, illness, death, recording oversight. |
| **2. Study design and protocol** | Intentional sampling strategies, eligibility rules, and observation schedules. | Planned missingness, subsampling, gaps between waves, incomplete sampling frames. |
| **3. Technical and measurement** | Instrument bounds, hardware or software failures, and data integration errors. | Detection limits, sensor malfunction or saturation, corrupted files, failed record linkage. |
| **4. Contextual and institutional** | External physical, organizational, or regulatory conditions restricting data collection. | Severe weather, institutional closure, funding termination, privacy or consent restrictions. |

The second dimension characterizes *what* the missingness represents:

| Category | What it represents | Examples |
|---|---|---|
| **1. Unobserved** | A true point value exists conceptually, but no numeric information was captured or retained. | Unanswered survey items, unrecorded blood pressure, lost or corrupted files. |
| **2. Structurally undefined** | No meaningful value exists for a particular subject, state, or situation. | Smoking intensity for a nonsmoker, quality-of-life scores after death. |
| **3. Censored** | A value exists and is partially known to fall beyond a measurement or reporting boundary. | Concentrations below detection limits, survival past study end, privacy-suppressed counts ($<5$). |
| **4. Truncated** | An entire observation (row) is absent because it falls outside a selection or eligibility boundary. | Incomes below a sampling cutoff, individuals excluded by eligibility criteria. |

Together, these two dimensions provide complementary tools for diagnosing and managing missing data. Classifying the source of missingness helps identify how information is lost, detect potential mechanisms of systematic bias, and design preventive protocols. Classifying the statistical nature of missingness prevents treating all missing values as equivalent, guiding whether to impute unobserved values, leave structurally undefined cells alone, model censored bounds explicitly, or adjust for sample truncation.

---

### How Does Data Go Missing? Rubin’s Probabilistic Taxonomy

Once we isolate genuinely unobserved values from structurally undefined, censored, or truncated cases, we introduce a third dimension: the **probabilistic mechanism** governing missingness.

Let $Y = (Y_{\text{obs}}, Y_{\text{miss}})$ denote the complete data partitioned into observed ($Y_{\text{obs}}$) and missing ($Y_{\text{miss}}$) components, and let $M$ be the missingness indicator matrix ($M_{ij} = 1$ if $Y_{ij}$ is missing, and $0$ if observed). Rubin’s taxonomy classifies mechanisms by how the probability distribution of $M$ depends on $Y$:

| Mechanism | Probabilistic definition | What it means | Example |
|---|---|---|---|
| **MCAR**<br>*(Missing Completely at Random)* | $P(M \mid Y_{\text{obs}}, Y_{\text{miss}}) = P(M)$ | Missingness is completely independent of both observed and unobserved data. | A random server glitch drops survey responses, or a lab vial is accidentally broken. |
| **MAR**<br>*(Missing at Random)* | $P(M \mid Y_{\text{obs}}, Y_{\text{miss}}) = P(M \mid Y_{\text{obs}})$ | Conditional on observed data, missingness does not depend on the missing values themselves. | Younger respondents skip the income question more often, but age is fully observed, and within age groups skipping is unrelated to actual income. |
| **MNAR**<br>*(Missing Not at Random)* | $P(M \mid Y_{\text{obs}}, Y_{\text{miss}}) \neq P(M \mid Y_{\text{obs}})$ | Even after conditioning on $Y_{\text{obs}}$, missingness still depends on the unobserved values $Y_{\text{miss}}$. | High earners refuse to disclose their income because of how much they earn, beyond what observed covariates explain. |
To determine which probabilistic mechanism governs our dataset, we combine empirical checks on the missingness indicator $M$ with substantive knowledge of how the data were generated.

If observed variables $Y_{\text{obs}}$ empirically predict $M$, MCAR is ruled out, leaving MAR or MNAR. However, failing to reject independence does not prove MCAR, because $M$ could still depend directly on unseen values $Y_{\text{miss}}$ (MNAR). Classifying data as MCAR therefore requires both no empirical association with $Y_{\text{obs}}$ and a clear substantive justification (such as planned random subsampling or an isolated technical glitch).

Data point toward MAR when $Y_{\text{obs}}$ predicts $M$ (ruling out MCAR), paired with a substantive argument against MNAR. Because data alone cannot separate MAR from MNAR, defending MAR requires domain reasoning that once we condition on observed covariates and auxiliary predictors in $Y_{\text{obs}}$, any remaining missingness is unrelated to $Y_{\text{miss}}$ itself.

Regardless of whether $Y_{\text{obs}}$ predicts $M$ or not, MNAR cannot be diagnosed empirically without external audit data or follow-up subsamples of non-respondents. We classify data as MNAR on substantive grounds whenever theory, clinical knowledge, or reporting incentives indicate that the unseen value $Y_{\text{miss}}$ directly drives nonresponse even after conditioning on all observed variables.

---

### The Statistical Toolkit

Once we understand the probabilistic mechanisms governing missingness, we can discuss missing-data methods from the software default of dropping incomplete rows, through naive attempts to rescue sample size, up to principled modern estimation.

#### Complete-Case Analysis (Listwise Deletion)

Discards any observation (row) containing one or more missing values and fits the model on fully observed units. **When it works and fails:** Under MCAR, complete cases represent a true random subsample of the original data, so parameter estimates remain unbiased. Discarding partial records reduces sample size and inflates standard errors. Under MAR and MNAR, complete-case analysis generally produces systematic selection bias because the retained sample is no longer representative of the target population.

#### Single Imputation (Unconditional)

Replaces each missing cell with a unconditional constant—such as the variable’s observed mean, median, or last observation carried forward (LOCF)—and fits the model as if all values were genuinely observed. **When it works and fails:** Can fail across all mechanisms, including MCAR (aside from preserving the sample mean under MCAR mean substitution). Concentrating imputed values at a single value artificially shrinks variance, attenuates correlations and regression slopes toward zero, and underestimates standard errors, inflating Type I error rates.

#### Single Imputation (Conditional)

Replaces each missing cell with its predicted value from a model conditioned on observed variables ($\hat{Y}_{\text{miss}} = E[Y_{\text{miss}} \mid Y_{\text{obs}}]$) and fits the downstream model on the completed dataset. **When it works and fails:** Under MCAR and MAR, conditioning on observed predictors recovers unbiased parameter estimates, whereas estimates remain biased under MNAR. However, it still fails inferential testing under all mechanisms because imputed points fall directly on the prediction surface without residual noise or parameter uncertainty, causing standard errors to be severely underestimated.

#### Multiple Imputation (MI)

Even if we upgrade conditional single imputation by adding random residual noise—drawing once from $P(Y_{\text{miss}} \mid Y_{\text{obs}}, \hat{\psi})$ so that variances, slopes, and relationships between variables are preserved—analyzing a single completed dataset still yields overly narrow standard errors, because downstream models treat imputed guesses as genuinely observed measurements.

MI addresses this problem not by improving relationships within a single dataset, but by repeating stochastic imputation across multiple realizations, allowing us to assess how much our target estimate fluctuates due to missing-data uncertainty.

This requires an appropriate stochastic imputation approach, which is itself a challenging modelling task. A widely used approach is Multiple Imputation by Chained Equations (MICE). Rather than specifying one joint model for all variables, MICE builds a separate conditional model for each variable containing missing values, using the other variables as predictors. It cycles through these models, repeatedly drawing plausible values for missing observations from their predictive distributions. After multiple iterations, this process produces $m$ completed datasets, each representing a different plausible realization of the missing values.

While a single imputation pass ($m = 1$) preserves relationships between variables, it conceals imputation variability—uncertainty both in estimating the imputation parameters $\hat{\psi}$ and in the unseen values $Y_{\text{miss}}$—which sits atop ordinary row-sampling variability. Note that imputing once first and bootstrapping afterward fails, as it freezes the imputed cells. Instead, we **bootstrap before imputing**:

   1. For $b = 1, \dots, B$, resample $n$ rows with replacement from the raw incomplete dataset (retaining its missingness pattern) to form $D^{*(b)}$.
   2. Fit the imputation model to generate a stochastically completed dataset, and fit the substantive analysis model to obtain $\hat{\theta}^{*(b)}$.  

Resampling the incomplete rows propagates both ordinary sampling error and parameter uncertainty, while stochastic imputation draws inject missing-value noise, yielding valid standard errors and confidence intervals directly from $\hat{\theta}^{*(1)}, \dots, \hat{\theta}^{*(B)}$.

*Classical Analytical Shortcut — Rubin’s Rules:* Rather than repeatedly bootstrapping the data, standard MI generates multiple completed datasets, fits the analysis model to each, and combines the results using Rubin’s rules. These rules account for both ordinary sampling uncertainty and the additional uncertainty introduced by missing data.

**When it works and when it fails:** MI generally produces reliable estimates when data are MCAR or MAR, provided the imputation model is appropriate and includes the variables relevant to the analysis. It must also account for uncertainty in the imputed values and model estimates.

*Honorable Mention:* Full Information Maximum Likelihood (FIML): An alternative approach that uses all available observed data to estimate model parameters without creating multiple imputed datasets. Like standard MI, it generally relies on the MAR assumption and a correctly specified model.

*Honorable Mention:* Sensitivity Analysis for MNAR ($\delta$-Adjustment): Under MNAR, we cannot produce unbiased estimates from $Y_{\text{obs}}$ alone because unseen values systematically differ from observed ones. Aside from specialized joint models of $(Y, M)$, the most practical analytical tool is tipping-point ($\delta$-adjustment) on top of MI: After generating $m$ datasets under MAR, we shift the imputed values by a systematic offset $\delta$ and re-pool via Rubin’s rules. Repeating this across a range of $\delta$ values identifies the*tipping point—the exact magnitude of MNAR departure required to overturn the study’s conclusion.

*Honorable Mention:* In principle, any generative model can be combined with bootstrap to produce a MI method. For example, a diffusion model. However, this is computationally very intensive and, if the dataset is small, the chained linear models of MICE will be more robust.

---

### Post-Lecture Reflections

* **Self-Test with your favorite AI tool:** Find an empirical research paper that reports missing data (or uses survey, clinical, or observational data where missingness is inevitable). Audit the paper's handling of missingness along the topics discussed in this takeaway. Once you have completed your assessment, prompt an AI tool to audit the same paper's missing-data strategy independently (giving it this takeway for reference).
* **Recommended Readings:**
  * **Bartlett, J. W., & Hughes, R. A. (2020). Bootstrap inference for multiple imputation under uncongeniality and misspecification. *Statistical Methods in Medical Research*, 29(12), 3533–3546.**
  * **van Buuren, S. (2018). *Flexible Imputation of Missing Data* (2nd ed.). CRC Press.** *(Specifically Section 4.5: "Fully conditional specification" and Section 4.5.1: "MICE algorithm"; open-access at [stefvanbuuren.name/fimd/sec-FCS.html](https://stefvanbuuren.name/fimd/sec-FCS.html))*
