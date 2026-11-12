---
title: 'Lecture Takeaway: Linear Model Basics'
output:
  html_document:
    df_print: paged
---

> *"Linear models were largely developed in the precomputer age of statistics, but even in today’s computer era there are still good reasons to study and use them.
They are simple and often provide an adequate and interpretable description of how the inputs affect the output."*
>
> — **Trevor Hastie, Robert Tibshirani, & Jerome Friedman**, *The Elements of Statistical Learning (2nd Edition, Ch. 3)* (2009).

---

### Basic Linear Regression

A linear model expresses the relationship between a scalar response (dependent variable) $y_i$ and a set of $k$ explanatory variables (predictors) $\mathbf{x}_i = (x_{i1}, x_{i2}, \dots, x_{ik})$ as:

$$y_i = \beta_0 + \beta_1 x_{i1} + \beta_2 x_{i2} + \dots + \beta_p x_{ik} + \varepsilon_i.$$

In compact matrix notation for $n$ observations (note that the intercept $\beta_0$ can be represented by a predictor that is always 1):
$$\mathbf{y} = \mathbf{X}\boldsymbol{\beta} + \boldsymbol{\varepsilon}$$

Where:

* **$\mathbf{X}\boldsymbol{\beta}$** represents the **systematic component** (the conditional expectation $\mathbb{E}[y \mid \mathbf{x}]$, assuming $\mathbb{E}[\boldsymbol{\varepsilon} \mid \mathbf{X}] = \mathbf{0}$).
* the residuals **$\boldsymbol{\varepsilon}$** are the **stochastic component** representing the unobservable stochastic errors (random noise, unmeasured factors, and measurement error).

A fundamental distinction in linear modeling that is often blurred in informal practice is the difference between the **error term** ($\varepsilon_i$) and the **residual** ($e_i$). The error term is an unobservable, population-level quantity representing the true stochastic disturbance of an observation from the underlying DGP ($\varepsilon_i = y_i - \mathbf{x}_i^\top \boldsymbol{\beta}$); because the true parameters $\boldsymbol{\beta}$ are latent and never known with certainty, $\varepsilon_i$ can never be directly observed. In contrast, the residual is an observable, sample-level quantity representing the vertical deviation of a data point from the estimated sample regression line ($e_i = y_i - \mathbf{x}_i^\top \hat{\boldsymbol{\beta}}$). In everyday statistical parlance, textbook prose, and software output, the two terms are frequently used interchangeably. However, treating them as identical is a category error: errors are theoretical properties of the physical system governed by model assumptions, whereas residuals are merely empirical, sample-specific estimates (for example, $\sum_{i=1}^n e_i = 0$ is mechanically forced by OLS whenever an intercept is included, even if the true error term does not have zero mean).

---

### Estimating the Parameters of a Linear Model

#### General Principle: Maximum Likelihood Estimation (MLE)

MLE is a parametric method that estimates parameters that make the data most probable under an assumed probability distribution. It is a general inference framework that we will use for all of our statistical models.

Given observed data $\mathcal{D} = \{(\mathbf{x}_1, y_1), \dots, (\mathbf{x}_n, y_n)\}$ drawn independently from a conditional distribution with probability density function $p(y_i \mid \mathbf{x}_i; \boldsymbol{\theta})$, the **likelihood function** $L(\boldsymbol{\theta})$ is the joint probability of the observations viewed as a function of the parameter vector $\boldsymbol{\theta}$:

$$L(\boldsymbol{\theta}; \mathcal{D}) = \prod_{i=1}^n f(y_i \mid \mathbf{x}_i; \boldsymbol{\theta})$$

MLE is defined as:

$$\hat{\boldsymbol{\theta}}_{\text{MLE}} = \arg\max_{\boldsymbol{\theta}} L(\boldsymbol{\theta}; \mathcal{D})$$

#### MLE for the Gaussian Linear Model

Assume the standard linear model with additive, independent, and identically distributed (i.i.d.) Gaussian errors:

$$y_i = \mathbf{x}_i^\top \boldsymbol{\beta} + \varepsilon_i, \quad \varepsilon_i \overset{\text{i.i.d.}}{\sim} \mathcal{N}(0, \sigma^2) \implies y_i \mid \mathbf{x}_i \overset{\text{ind}}{\sim} \mathcal{N}(\mathbf{x}_i^\top \boldsymbol{\beta}, \, \sigma^2)$$

The unknown parameter vector is $\boldsymbol{\theta} = (\boldsymbol{\beta}, \sigma^2)^\top$.

##### Step 1: Write the Likelihood and Log-Likelihood
The density for each observation is:
$$f(y_i \mid \mathbf{x}_i; \boldsymbol{\beta}, \sigma^2) = \frac{1}{\sqrt{2\pi\sigma^2}} \exp\left( -\frac{(y_i - \mathbf{x}_i^\top \boldsymbol{\beta})^2}{2\sigma^2} \right)$$

Because the natural logarithm is strictly monotonically increasing, maximizing $L(\boldsymbol{\theta})$ is identical to maximizing the **log-likelihood** $\ell(\boldsymbol{\theta}) = \ln L(\boldsymbol{\theta})$:

$$\ell(\boldsymbol{\beta}, \sigma^2) = \sum_{i=1}^n \left[ -\frac{1}{2}\ln(2\pi) - \frac{1}{2}\ln(\sigma^2) - \frac{(y_i - \mathbf{x}_i^\top \boldsymbol{\beta})^2}{2\sigma^2} \right]$$

In matrix notation:
$$\ell(\boldsymbol{\beta}, \sigma^2) = -\frac{n}{2}\ln(2\pi) - \frac{n}{2}\ln(\sigma^2) - \frac{1}{2\sigma^2}(\mathbf{y} - \mathbf{X}\boldsymbol{\beta})^\top (\mathbf{y} - \mathbf{X}\boldsymbol{\beta})$$

##### Step 2: Solve for $\hat{\boldsymbol{\beta}}_{\text{MLE}}$
Take the gradient with respect to $\boldsymbol{\beta}$ and set it to zero:
$$\nabla_{\boldsymbol{\beta}} \ell(\boldsymbol{\beta}, \sigma^2) = \frac{1}{\sigma^2}\mathbf{X}^\top(\mathbf{y} - \mathbf{X}\boldsymbol{\beta}) = \mathbf{0}$$

$$\mathbf{X}^\top\mathbf{X}\boldsymbol{\beta} = \mathbf{X}^\top\mathbf{y} \implies \hat{\boldsymbol{\beta}}_{\text{MLE}} = (\mathbf{X}^\top \mathbf{X})^{-1}\mathbf{X}^\top\mathbf{y}$$

##### Step 3: Solve for $\hat{\sigma}^2_{\text{MLE}}$
Take the partial derivative with respect to $\sigma^2$ and set it to zero:
$$\frac{\partial \ell}{\partial \sigma^2} = -\frac{n}{2\sigma^2} + \frac{1}{2(\sigma^2)^2}(\mathbf{y} - \mathbf{X}\boldsymbol{\beta})^\top (\mathbf{y} - \mathbf{X}\boldsymbol{\beta}) = 0$$

$$\hat{\sigma}^2_{\text{MLE}} = \frac{1}{n}\sum_{i=1}^n (y_i - \mathbf{x}_i^\top\hat{\boldsymbol{\beta}})^2 = \frac{1}{n}\sum_{i=1}^n e_i^2$$

#### Asymptotic Properties of MLE

Under standard regularity conditions (e.g., correct model specification, identifiable parameters, non-singular Fisher Information matrix), the MLE has three foundational asymptotic guarantees as the sample size $n \to \infty$:

1. **Consistency:** 
   $$\hat{\boldsymbol{\theta}}_n \xrightarrow{p} \boldsymbol{\theta}_0$$
   As the sample size grows infinitely large, the estimate converges in probability to the true population parameter $\boldsymbol{\theta}_0$.

2. **Asymptotic Normality:**
   $$\sqrt{n}(\hat{\boldsymbol{\theta}}_n - \boldsymbol{\theta}_0) \xrightarrow{d} \mathcal{N}\left(\mathbf{0}, \, \mathcal{I}^{-1}(\boldsymbol{\theta}_0)\right)$$
   The distribution of the estimator approaches a multivariate normal distribution centered at the truth, where $\mathcal{I}(\boldsymbol{\theta}_0)$ is the expected **Fisher Information matrix** per observation:
   $$\mathcal{I}(\boldsymbol{\theta}) = -\mathbb{E}\left[ \nabla^2_{\boldsymbol{\theta}} \ln f(Y \mid \mathbf{X}; \boldsymbol{\theta}) \right]$$

3. **Asymptotic Efficiency:**
   The MLE achieves the theoretical lower bound on variance for any consistent estimator (**Cramér-Rao Lower Bound**). In large samples, no other consistent estimator has smaller variance:
   $$\operatorname{Var}(\hat{\boldsymbol{\theta}}_n) \approx \frac{1}{n}\mathcal{I}^{-1}(\boldsymbol{\theta}_0)$$

#### Relationship to Log Loss (Negative Log-Likelihood)

In machine learning and optimization, problems are typically framed as minimization rather than maximization. We convert the likelihood maximization task by defining the **Negative Log-Likelihood (NLL)**, also known as the **log loss** or cross-entropy:

$$\mathcal{L}_{\text{NLL}}(\boldsymbol{\theta}) = -\ell(\boldsymbol{\theta}) = -\sum_{i=1}^n \ln p(y_i \mid \mathbf{x}_i; \boldsymbol{\theta})$$

Because negating a function flips its extrema:

$$\arg\max_{\boldsymbol{\theta}} L(\boldsymbol{\theta}) \iff \arg\max_{\boldsymbol{\theta}} \ell(\boldsymbol{\theta}) \iff \arg\min_{\boldsymbol{\theta}} \mathcal{L}_{\text{NLL}}(\boldsymbol{\theta})$$

Minimizing log loss is strictly equivalent to maximizing likelihood.

#### Equivalence to Ordinary Least Squares (SSE Minimization)

Recall the Gaussian log-likelihood:

$$\ell(\boldsymbol{\beta}, \sigma^2) = \sum_{i=1}^n \left[ -\frac{1}{2}\ln(2\pi) - \frac{1}{2}\ln(\sigma^2) - \frac{(y_i - \mathbf{x}_i^\top \boldsymbol{\beta})^2}{2\sigma^2} \right].$$

When optimizing with respect to $\boldsymbol{\beta}$ (treating $\sigma^2$ as fixed), the first two terms are constant and the third term is maximized by minimizing the squared residuals.

Therefore, maximizing Gaussian likelihood (which has a negative quadratic term) is mathematically identical to minimizing the Sum of Squared Errors (SSE). Ordinary Least Squares is simply a special case MLE under the assumption of independent, identically distributed normal errors.

---

### Assumptions, Advantages, and Disadvantages

##### Explicit Assumptions

* **Linearity in Parameters:** The relationship between predictors and the response is linear with respect to the coefficients: $\mathbb{E}[y \mid \mathbf{x}] = \mathbf{x}^\top\boldsymbol{\beta}$. If violated:** **Biased & Inconsistent Estimates:** The parameter estimates $\hat{\boldsymbol{\beta}}$ are systematically wrong and do not converge to the truth, even as $n \to \infty$. **Systematic Prediction Error:** The model systematically over- or under-predicts across different regions of the predictor space. **Invalid Inference:** Standard errors, confidence intervals, and hypothesis tests become meaningless because the functional form itself is misspecified.

* **Homoskedasticity:** The error variance is constant across all values of the predictors: $\operatorname{Var}(\varepsilon_i \mid \mathbf{x}_i) = \sigma^2$. **If violated (Heteroskedasticity):** **Estimates Remain Unbiased:** $\hat{\boldsymbol{\beta}}$ is still unbiased and consistent, but OLS is **no longer BLUE** (it loses statistical efficiency; Weighted Least Squares would have lower variance). **Distorted Standard Errors:** Standard OLS standard errors are biased (usually underestimated), leading to spuriously narrow confidence intervals, deflated $p$-values, and artificially high Type I error rates (detecting false positives).

* **Independent Errors (i.i.d.):** Error terms are uncorrelated across observations: $\operatorname{Cov}(\varepsilon_i, \varepsilon_j) = 0$ for all $i \neq j$. **If violated (Autocorrelation / Clustered Noise):** **Estimates Remain Unbiased:** $\hat{\boldsymbol{\beta}}$ remains unbiased, but OLS is no longer optimal. **Severely Compromised Inference:** Standard error formulas drastically underestimate true sampling variability (especially under positive serial correlation or unmodeled spatial/cluster grouping), resulting in severely inflated $t$-statistics and spurious claims of statistical significance.

* **Normally Distributed Errors:** $\varepsilon_i \overset{\text{i.i.d.}}{\sim} \mathcal{N}(0, \sigma^2)$. **If violated (Non-Normal / Heavy-Tailed Errors):** In **small samples**, exact $t$-tests, $F$-tests, and confidence intervals are invalid because the finite-sample distribution of $\hat{\boldsymbol{\beta}}$ is not strictly Student's $t$. In **large samples**, inference is rescued by the **Central Limit Theorem (CLT)**, which guarantees asymptotic normality of $\hat{\boldsymbol{\beta}}$. **Inaccurate Prediction Intervals:** Unlike parameter confidence intervals, individual prediction intervals ($y_{\text{new}}$) rely directly on the error distribution and remain distorted regardless of sample size.

##### Implicit & Structural Considerations

* **Full Column Rank (No Multicollinearity):** The design matrix $\mathbf{X}$ cannot be rank-deficient ($\operatorname{rank}(\mathbf{X}) = p + 1$). Perfect multicollinearity makes $(\mathbf{X}^\top\mathbf{X})$ non-invertible, while high multicollinearity inflates parameter standard errors and destabilizes estimates.

* **Sensitivity to Outliers & Leverage Points:** Because least squares minimizes squared residuals, extreme outliers or high-leverage observations exert disproportionate influence on the estimated slope and intercept.

* **Fragility Under Extrapolation:** Linear projections beyond the observed range (support) of the training data are unreliable and assume the linear trend persists indefinitely into unobserved regions.

#### Standard Diagnostic Procedures

* Residuals vs. Fitted Plot (Checks Linearity & Zero-Mean Error)
* Normal Q-Q Plot (Checks Normality of Errors)
* Scale-Location / Spread-Location Plot (Checks Homoskedasticity)
* Cook’s Distance & Leverage Plot (Detects Outliers & Influential Points)
* Residuals vs. Time/Order Plot & Autocorrelation (ACF) (Checks Independence of Errors)

#### Advantages

* **Interpretability and Parsimony:** Transparent parametric structure; each coefficient $\beta_j$ provides an intuitive, *ceteris paribus* marginal effect of predictor $x_j$ on $y$.

* **Computational Simplicity:** Has a closed-form analytical solution ($(\mathbf{X}^\top\mathbf{X})^{-1}\mathbf{X}^\top\mathbf{y}$) that computes rapidly without iterative tuning or non-convex optimization traps.

* **Flexibility via Input Transformations:** While linear in parameters, the model can capture complex non-linear patterns through polynomial expansions, basis functions, splines, interaction terms, or logarithmic transformations.

---

### Quantifying the Uncertainty in the Estimates

Standard errors for coefficients $\beta$ are typically provided by the library used to fit a linear model. From these, under the assumption of normality, we can also derive confidence intervals. Note that these numbers are derived under the assumptions of the linear model, but, if the assumptions hold, are exact (not approximations).

Alternatively, we can use non-parametric bootstrap. The key observation here is that the unit of resampling is the entire row in our dataset. We can create a bootstrap replicated dataset by resampling rows with replacement. To each replication we fit a linear model and extract the parameter estimates, to form the sampling distribution.

When the assumptions of the model hold, bootstrap SE and confidence intervals will be practically identical to the exact ones. However, if the assumptions do not hold, non-parametric bootstrap will be more robust, particularly in the presence of heteroskedasticity and non-normal errors.

---

### Post-Lecture Reflections

* Recommended Readings:
    * **James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021).** *An Introduction to Statistical Learning: with Applications in R* (2nd ed.), Chapter 3: "Linear Regression". Springer.
    * **Fox, J., & Weisberg, S. (2019).** *An R Companion to Applied Regression* (3rd ed.), Chapters 8.1 - 8.5: "Regression Diagnostics." SAGE Publications. *(Accompanying web vignette available via the `car` package).*