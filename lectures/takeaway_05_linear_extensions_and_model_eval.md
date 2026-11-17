---
title: 'Lecture Takeaway: Linear Model Extensions and Model Evaluation'
output:
  html_document:
    df_print: paged
---

> *"Since all models are wrong the scientist cannot obtain a "correct" one by excessive elaboration. On the contrary following William of Occam he should seek an economical description of natural phenomena. Just as the ability to devise simple but evocative models is the signature of the great scientist so overelaboration and overparameterization is often the mark of mediocrity."*
>
> — **George E. P. Box**, *Science and Statistics* (1976), *Journal of the American Statistical Association*.

---

### Extending the Linear Regression Model

#### Categorical Features

**Dummy coding:** A categorical variable with $k$ levels is encoded using $k-1$ binary (0/1) variables to prevent multicollinearity. The omitted level serves as the reference. $\beta_0$ is the effect of the reference, while the coefficients for the $k-1$ binary variables are the differences between that level and the reference.

Note that many other codings exist. Common approaches include:

* **Sum (Effect) Coding (`contr.sum`):** Compares each level to the unweighted grand mean across all categories.
* **Successive (Repeated) Difference Coding (`MASS::contr.sdif`):** Compares each category directly to the immediately preceding category (level 2 vs. level 1, level 3 vs. level 2).
* **Helmert Coding (`contr.helmert`):** : Compares each level to the average of all preceding (or subsequent) levels.

Regardless of which coding you select, the model's fitted values ($\hat{y}_i$), residuals, log-likelihood, and $R^2$ remain identical. The codings just simplify the testing of specific hypotheses about group differences without altering the underlying model.

---

#### Nonlinear Functional Relationships

The word "linear" in linear regression requires only that the model is linear in the parameters $\beta$), not in the variables $X$. The design matrix $X$ can contain arbitrary transformations, while keeping the model linear.

The simplest way to introduce curvature is by including powers of a continuous feature (polynomial regression):

\[
Y_i = \beta_0 + \beta_1 X_i + \beta_2 X_i^2 + \dots + \beta_d X_i^d + \varepsilon_i
\]

Raw powers are strongly correlated, so individual coefficients may become unstable. In R, `poly(X, degree = d)` (with default `raw = FALSE`) constructs orthogonal polynomials. This eliminates collinearity, while producing the exact same fitted values and predictions.

Global polynomials become unstable as degree $d$ increases. Instead of one rigid global polynomial, splines (`splines::ns()`) divide the predictor space into local intervals using internal knots, fitting piecewise polynomials constrained to connect smoothly at the joints. This localizes curvature and prevents global edge oscillations.

---

#### Interactions

To model that the effect of one variable depends on the context of another, we add product terms ($X_1 \cdot X_2$) to the design matrix. The model remains linear in its parameters.

The three interaction archetypes are:

* **Categorical $\times$ Categorical (Factorial Cell Means):** Crossing two factors ($X_A \cdot X_B$) lets each specific subgroup have its own unique average, rather than assuming the effects of the two categories simply add together.

* **Categorical $\times$ Continuous (Varying Slopes):** Relaxes the "parallel lines" constraint, allowing distinct slopes for each group:
  \[
  Y_i = \beta_0 + \beta_1 X_i + \beta_2 I_i + \beta_3 (X_i \cdot I_i) + \varepsilon_i
  \]
  
  For the reference group, the slope is $\beta_1$, while $\beta_3$ measures the difference in slopes between groups.

* **Continuous $\times$ Continuous (Dynamic Marginal Effects):**  
  \[
  Y_i = \beta_0 + \beta_1 X_1 + \beta_2 X_2 + \beta_3 (X_1 X_2) + \varepsilon_i
  \]
  The marginal effect of $X_1$ is no longer a single number, but a dynamic linear function of $X_2$. Captures synergy ($\beta_3 > 0$, mutual reinforcement) or antagonism ($\beta_3 < 0$, diminishing returns).

Note that in any model containing an interaction term:
\[
\frac{\partial \mathbb{E}[Y]}{\partial X_1} = \beta_1 + \beta_3 X_2
\]

The coefficient $\beta_1$ is **not** the average effect of $X_1$. It is the effect of $X_1$ when $X_2 = 0$. If $X_2 = 0$ is unphysical or outside the data range, the $\beta_1$ and $\beta_2$ become meaningless and potentially unstablew. To address this, continuous variables should be centered ($X' = X - \bar{X}$). When $X'_2 = 0$, $\beta_1$ cleanly represents the effect of $X_1$ for an average unit.

Note that in R, `X1 * X2` automatically expands to both main effects and the interaction product:
```r
# Fits: Y = β₀ + β₁·X1 + β₂·X2 + β₃·(X1·X2)
lm(Y ~ X1 * X2, data = df)
```

---

### Model Evaluation

How do we decide if adding parameters genuinely improves our model? The gold standard of a model is not how tightly it fits training data, but how accurately it forecasts new, unseen observations from the same data generating process.

Let $p(y_{\text{new}})$ be the true, unknown data-generating process. If we fit a model on our training sample, obtaining parameter estimates $\hat{\boldsymbol{\theta}}$, the ideal goal of model evaluation is the **Expected Log Predictive Density (ELPD)**:

\[
\text{ELPD} = \mathbb{E}_{y_{\text{new}}}\left[ \ln p(y_{\text{new}} \mid \hat{\boldsymbol{\theta}}) \right] = \int p(y_{\text{new}}) \ln p(y_{\text{new}} \mid \hat{\boldsymbol{\theta}}) \, dy_{\text{new}}
\]

This is mathematically well founded: maximizing ELPD is strictly equivalent to minimizing the Kullback–Leibler Divergence between our model and true physical reality!

---

#### The Problem: In-Sample Likelihood is a Biased Estimate

In practice, we do not have access to future observations $y_{\text{new}}$. The naive temptation is to simply evaluate the log-likelihood on the sample we already collected:

\[
\ell_{\text{in-sample}} = \sum_{i=1}^n \ln p(y_i \mid \hat{\boldsymbol{\theta}})
\]

Because we fit parameter values $\hat{\boldsymbol{\theta}}$ that minimize error on these exact $n$ points (overfitting), in-sample evaluation is systematically biased upward (optimistic):

\[
\mathbb{E}[\ell_{\text{in-sample}}] > n \cdot \text{ELPD}
\]

To estimate true out-of-sample performance, statistical science developed two distinct methodological families: **Analytical Approximations** and **Held-out Data Approaches**.

---

#### Family A: Analytical Approximations (Penalized Likelihood)

Instead of splitting data, this family fits the model to the full dataset and relies on mathematical theory to estimate and subtract the in-sample optimism.

**Akaike Information Criterion (AIC):**
  \[
  \text{AIC} = -2\ell(\hat{\boldsymbol{\theta}}) + 2k,
  \]

where $k$ is the number of model parameters. Smaller AIC indicates lower expected out-of-sample information loss. AIC is simply an asymptotic approximation to the total out-of-sample ELPD multiplied by -2.

Beyond standard AIC, several related criteria analytically penalize in-sample likelihood to estimate out-of-sample performance: $\text{AIC}_c$, $\text{BIC}$, $C_p$, $\text{WAIC}$, each with its own advantages and disadvantages.

---

#### Family B: Held-Out Sample Approaches (Cross-Validation)

Rather than mathematically approximating the optimism, this family evaluates the model on observations it was not allowed to see during parameter estimation.

* **Simple Holdout Validation (Train/Test):**  Randomly partition data into a training set to estimate $\hat{\boldsymbol{\theta}}$, and a test set to evaluate log-likelihood. The main limitation is inefficient use of data. The result is also sensitive to the train-test partition, but this can be mitigated by repeating across several partitions of the data.
* **$k$-Fold Cross-Validation:**  Partition data into $k$ equal, mutually exclusive subsets. For each fold, fit the model on the remaining $k - 1$ folds and evaluate out-of-sample log-loss on that fold. Average the validation performance across all $k$ iterations. The standard error of a k-fold cross-validation estimator is computed by across all individual observations. If $k$ is small, the result is also sensitive to the partition.
* **Leave-One-Out Cross-Validation (LOOCV):** The extreme case where $k = n$. Hold out observation $i$, train on the remaining $n - 1$ observations, evaluate on observation $i$, and repeat $n$ times. *Stone's Theorem:* For linear models, LOOCV is asymptotically equivalent to AIC!

---

#### Targeted Model Comparison: Pointwise Differences and Standard Errors

When comparing two models, researchers often naively compute the total out-of-sample score for Model 0 ($\text{Score}_0$) and Model 1 ($\text{Score}_1$) and look at whether the difference is positive or negative.

Model 0 and Model 1 are evaluated on the exact same data points. Their predictions are heavily correlated! Treating $\text{Score}_0$ and $\text{Score}_1$ as two separate, independent random variables ignores their covariance and makes it impossible to know if the observed difference is real or within random noise.

Instead of subtracting two aggregate totals, we compute the pointwise difference in out-of-sample log-predictive density for each individual observation $i$:

\[
d_i = \ln p\left( y_i \mid \mathbf{x}_i, \; \hat{\boldsymbol{\theta}}_{1, (-i)} \right) - \ln p\left( y_i \mid \mathbf{x}_i, \; \hat{\boldsymbol{\theta}}_{0, (-i)} \right)
\]

We now have a single sample of $n$ independent predictive differences: $(d_1, d_2, \dots, d_n)$. From here we can proceed with any procedure for estimating the mean of a continuous random variable.

---

### Post-Lecture Reflections

* Suppose you design 100 different models, and select the model that achieves the lowest 10-fold cross-validation loss. Is that winning CV score a good estimate of how well the model will predict on future real-world data? How would you improve the model selection process to mitigate potential issues?
* Recommended Readings:
  * **Schad, D. J., Vasishth, S., Hohenstein, S., & Kliegl, R. (2020).** *How to capitalize on a priori contrasts in linear (mixed) models: A tutorial.* Journal of Memory and Language, 110, 104038 [1].
  * **Brambor, T., Clark, W. R., & Golder, M. (2006).** *Understanding interaction models: Improving empirical analyses.* Political Analysis, 14(1), 63–82 [1].
  * **James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021).** *An Introduction to Statistical Learning: with Applications in R* (2nd ed.), Chapter 7: "Moving Beyond Linearity." Springer [2].