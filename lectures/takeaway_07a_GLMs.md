---
title: 'Lecture Takeaway: Generalized Linear Models (GLMs)'
output:
  html_document:
    df_print: paged
---

### What is a GLM?

Up wo now, we modeled the conditional expectation using the Gaussian linear model:

$$y_i = \boldsymbol{\beta}^\top \mathbf{x} + \varepsilon_i, \quad \varepsilon_i \overset{\text{i.i.d.}}{\sim} \mathcal{N}(0, \sigma^2).$$

This classical formulation fails whenever data depart from continuous, unbounded, constant-variance distributions. Some notable examples are binary outcomes (penguin sex, shot made vs. missed, toxic vs. non-toxic comment, patient survival), count data (customer visits, beetle trap catches, git commits, hospital readmissions), and bounded continuous data (pollution concentrations, server response latency, animal body mass, percentage of canopy cover).

GLMs solve this problem by leaving the data in its natural, untransformed state, modeling the expected value through a mathematical link function while tailoring the likelihood to the true error distribution.

Every Generalized Linear Model unites three explicit structural components:

1. **Random Component:** The probability distribution of the response $Y_i \mid \mathbf{x}_i$ chosen from the *Exponential Dispersion Family* (Gaussian, Bernoulli, Poisson, Negative Binomial, Gamma...).
2. **Systematic Component:** The familiar linear predictor ($\eta_i$):
   $$\eta_i = \boldsymbol{\beta}^\top \mathbf{x}.$$
3. **Link Function $g(\cdot)$:** A strictly monotonic function that maps the restricted physical range of the conditional mean $\mu_i = \mathbb{E}[Y_i \mid \mathbf{x}_i]$ onto the real line $(-\infty, +\infty)$:
   $$\eta_i = g(\mu_i) \iff \mu_i = g^{-1}(\eta_i).$$

Common GLM Families and Link Functions:

| Family / Distribution | Support of $Y$ | Canonical / Common Link $\eta = g(\mu)$ | Inverse Link (Prediction) $\mu = g^{-1}(\eta)$ | Variance Function $\operatorname{Var}(Y \mid \mu)$ | Typical Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Gaussian (Normal)** | $(-\infty, +\infty)$ | **Identity:** $\mu$ | $\eta$ | $\sigma^2$ (constant) | Standard linear regression (Lecture 04). |
| **Bernoulli / Binomial** | $y \in \{0, 1\}$ or counts $k/n$ | **Logit:** $\ln\left(\frac{\mu}{1 - \mu}\right)$<br>*(Also: Probit $\Phi^{-1}$, Cloglog)* | $\frac{1}{1 + e^{-\eta}}$ (Sigmoid) | $\mu(1 - \mu)$ | Binary choices, disease presence, mortality, click-through rates. |
| **Poisson** | $y \in \{0, 1, 2, \dots\}$ | **Log:** $\ln(\mu)$ | $e^\eta$ (Exponential) | $\mu$ (Equidispersion) | Rare event counts, traffic accidents, web traffic arrivals. |
| **Negative Binomial** | $y \in \{0, 1, 2, \dots\}$ | **Log:** $\ln(\mu)$ | $e^\eta$ | $\mu + \frac{\mu^2}{\theta}$ (Overdispersion) | Ecological counts (dung beetles), RNA sequencing reads, customer service calls. |
| **Gamma** | $y \in (0, +\infty)$ | **Log:** $\ln(\mu)$ or **Inverse:** $1/\mu$ | $e^\eta$ or $1/\eta$ | $\mu^2 \cdot \phi$ (Constant CV) | Strictly positive, right-skewed data: server latencies, financial costs, rainfall. |
| **Inverse Gaussian** | $y \in (0, +\infty)$ | **$1/\mu^2$** or **Log:** $\ln(\mu)$ | $1/\sqrt{\eta}$ or $e^\eta$ | $\mu^3 \cdot \sigma^2$ | Heavy-tailed positive data: first-passage times, catastrophic insurance losses. |

---

### Parameter Inference

GLMs apply the exact same Maximum Likelihood Estimation:

$$\hat{\boldsymbol{\beta}}_{\text{MLE}} = \arg\max_{\boldsymbol{\beta}} \sum_{i=1}^n \ln p(y_i \mid \mathbf{x}_i; \boldsymbol{\beta}).$$

The link function is non-linear (except for the already familiar Gaussian linear model), so a closed-form matrix solution like $(\mathbf{X}^\top\mathbf{X})^{-1}\mathbf{X}^\top\mathbf{y}$ does not exist. Software computes a numerical solution using specialized gradient-based algorithms, but in essence it remains a numerical optimization problem that can be solved using many different methods. 

---

### Model Evaluation

Without modification, our evaluation using in- or out-of-sample (LOOCV) log-predictive density remains valid.

---

### Quantifying Uncertainty

Software extracts asymptotic standard errors from the inverse Fisher Information matrix, relying on the asymptotic normality of MLE. Because non-parametric bootstrap makes zero distributional assumptions, we can apply it, without modification, to estimate SE and CIs for GLM parameters and predictions.

---

### Interpretation and Diagnostics

For the Gaussian GLM, the link function is the identity, so the natural scale of the data is the same as the scale of the linear term in the model. This is not true for any of the other GLMs. Therefore, to correctly interpret and diagnose GLMs, it becomes necessary to distinguish between the **link scale** ($\hat{\eta} = \mathbf{x}^\top\hat{\boldsymbol{\beta}}$) and the **natural scale** ($\hat{\mu} = g^{-1}(\hat{\eta})$).


#### How It Affects Parameter Interpretation

Because the link function $g(\cdot)$ non-linearly warps the real line $(-\infty, +\infty)$ onto the constrained physical space of the response, regression coefficients have two fundamentally different interpretations depending on the scale:

* **On the Link Scale ($\eta$): Relationships are Linear and Additive**  
  Each coefficient $\beta_j$ represents the constant, additive change in the link function per 1-unit increase in $x_j$, holding all other predictors fixed:
  $$\frac{\partial \eta}{\partial x_j} = \beta_j$$
  * *In Logistic Regression:* $\beta_j$ is the additive change in **log-odds** ($\ln\left(\frac{p}{1-p}\right)$).
  * *In Poisson Regression:* $\beta_j$ is the additive change in the **log-rate** ($\ln(\mu)$).

* **On the Natural Scale ($\mu$): Relationships are Multiplicative or Sigmoidal**  
  Because the inverse link $g^{-1}(\cdot)$ is non-linear, a 1-unit increase in $x_j$ does **not** have a constant additive effect on the physical response $\mu$:
  * **Logistic Regression $\implies$ Odds Ratios:** Exponentiating the coefficient gives the multiplicative effect on the odds:
    $$\text{OR} = e^{\beta_j} = \frac{\text{Odds}(x_j + 1)}{\text{Odds}(x_j)}$$
    *(The effect on probability $\Delta p$ depends on the baseline value: a 1-unit shift has a large effect near $p = 0.5$, but almost zero effect near $p = 0$ or $p = 1$).*
  * **Poisson Regression $\implies$ Incidence Rate Ratios (IRR):** Exponentiating gives the multiplicative scaling factor on the expected count:
    $$\text{IRR} = e^{\beta_j} = \frac{\mathbb{E}[Y \mid x_j + 1]}{\mathbb{E}[Y \mid x_j]}$$
    *(An estimate of $\hat{\beta}_j = 0.25$ means each 1-unit increase in $x_j$ multiplies expected counts by $e^{0.25} \approx 1.28$, a $28\%$ increase).*

* **The Software Rule:**  
  * `predict(model, type = "link")` returns values on the linear scale ($\hat{\eta} \in (-\infty, +\infty)$).
  * `predict(model, type = "response")` applies the inverse link to return physical probabilities ($\hat{p} \in [0, 1]$) or counts ($\hat{\mu} > 0$).


#### How It Affects Standard Diagnostic Plots

When you call `plot(glm_model)`, base R gives you the exact same four diagnostic plots as linear regression (`lm`), but it swaps out the residuals: It replaces raw errors ($y - \hat{\mu}$) with **Deviance Residuals** (which adjust for the non-linear link function) and **Pearson Residuals** (which divide by $\sqrt{\operatorname{Var}(Y)}$ to compensate for non-constant variance).

For continuous outcomes and continuous-like ordinal data, the plots are informative. However, for outcomes with only a few discrete values, they break down visually. They mechanically collapse into parallel curved stripes and clumpy Q-Q lines. The one exception is the Cook’s distance / leverage plot, which works for all models because it simply measures which points pull the hardest on the coefficients. To deal with this issue, we can use simulated residuals (see the **`DHARMa`** package readings).

#### What DHARMa Does Differently
Instead of calculating residuals with an equation like $y - \hat{\mu}$, **it uses simulation**:

1. It takes your fitted model and **simulates 250 synthetic outcomes** for every single observation in your data.
2. It compares your real data point to those 250 simulated values and calculates its **percentile rank** (i.e., did the real point fall in the 10th percentile, 50th percentile, or 99th percentile of what the model expected?).

#### Why This Fixes Binary and Count Data
* Even if the raw data is binary (0/1) or discrete counts, **percentile ranks are always continuous and uniformly distributed between 0 and 1**.
* The curved stripes vanish.
* If your model is correctly specified, the residuals on the plot will form a **flat, uniform band**, and the Q-Q plot will be a **straight diagonal line**.

---

### Post-Lecture Reflections

* **Recommended Readings:**
  * **Faraway, J. J. (2016). Chapter 8: "Generalized Linear Models". In *Extending the Linear Model with R: Generalized Linear, Mixed Effects and Nonparametric Regression Models* (2nd ed., pp. 23–48). CRC Press.**
  * **Hartig, F. (2022). *DHARMa: Residual Diagnostics for Hierarchical (Multi-Level / Mixed) Regression Models* [R package vignette]. Comprehensive R Archive Network (CRAN).** *(Link](https://cran.r-project.org/web/packages/DHARMa/vignettes/DHARMa.html))*