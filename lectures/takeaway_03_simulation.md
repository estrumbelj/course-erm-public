---
title: 'Lecture Takeaway: Quantifying Uncertainty with Simulation'
output:
  html_document:
    df_print: paged
---

> *"The new methods are fantastic computational spendthrifts; they can easily expend a million arithmetic operations on the analysis of 15 data points. The payoff for such intensive computation is freedom from two limiting factors that have dominated statistical theory since its beginnings: the assumption that the data conform to a bell-shaped curve and the need to focus on statistical measures whose theoretical properties can be analyzed mathematically."*
>
> — **Persi Diaconis & Bradley Efron**, *Computer-Intensive Methods in Statistics* (1983), *Scientific American*.

---

### The Mathematical Architecture of Inference

$$\begin{aligned}
\text{DGP } (F) \quad &\xrightarrow{\quad \text{Functional } T \quad} \quad \text{Parameter } \theta = T(F) \\[0.6em]
\Big\downarrow {\scriptstyle \text{Sample of size } n} & \\[0.6em]
\text{Data } \mathbf{y} \ (F_n) \quad &\xrightarrow{\quad \text{Estimator } T_{\text{est}} \quad} \quad \text{Estimator } \hat{\theta} = T_{\text{est}}(F_n) \quad \xrightarrow{\quad \text{Realized value} \quad} \quad \text{Estimate } (\text{e.g., } 0.46)
\end{aligned}$$

**Data Generating Process (DGP):** The complete physical, biological, or behavioral reality, combined with the measurement and sampling protocols, that produces observations. Mathematically a **probability distribution** (formally typically characterized by a Cumulative Distribution Function, **$F$**).

**Data ($\mathbf{y}$):** The realized, finite collection of observations captured from the DGP. Mathematically a scalar, vector, matrix, or some other object of recorded values $\mathbf{y} = (y_1, y_2, \dots, y_n)^\top$. Conceptually, the data also constitutes the empirical probability distribution ($F_n$), which assigns an equal probability mass of $1/n$ to each observed point.

**Parameter ($\theta$):** The latent, typically unobservable property of interest that characterizes the true DGP. Mathematically a statistical functional $T$ applied to the true distribution: $\theta = T(F)$. For example, the true mean $\mu = \mathbb{E}_F[Y]$, true proportion $p$, or true variance $\sigma^2$).

**Estimator ($\hat{\theta}$):** The equation or algorithm to deduce the unknown parameter from sample data. Mathematically also a statistical functional that maps from the sample space (all possible $F_n$) to parameter space: $\hat{\theta} = T_{\text{est}}(F_n)$. Because the sample $F_n$ varies from study to study, an estimator is a random variable across repeated runs of the universe, possessing its own **sampling distribution**. The sampling distribution, typically its standard deviation (also called **standard error**) and probability intervals (**confidence intervals**), is of primary interest when characterizing Tier 4 stochastic error due to estimating from a random sample.

**Plug-in estimator:** A special case of estimator that estimate a population property $\theta = T(F)$ by evaluating the exact same functional $T$ directly on the empirical distribution $F_n$. For example, estimating the DGP mean with the sample mean.

**Estimate:** The specific number obtained when a realized dataset is fed into an estimator. Unlike the unknown but constant true parameter theta $\theta$, the estimate is based on a single realized sample and thus carries irreducible Tier 4 stochastic sampling error that we wish to quantify.

### The Power of Simulation: Understanding Distributions by Sampling

A central breakthrough of computational statistics is that we do not need to solve calculus integrals to understand a probability distribution well enough for practical purposes. 

As long as we can generate draws from that distribution, the Law of Large Numbers guarantees that empirical sample statistics converge to the true theoretical properties.

* **Universal Tractability:** Whether you need a mean, variance, custom percentile, or complex region probability, you simply draw $m$ numbers and compute the summary.
* **Arbitrary Precision:** We can estimate almost all properties of a known distribution up to arbitrary precision simply by increasing our computational simulation budget ($m$).
* **Theory vs. Simulation:** When available, analytical solutions remain vital because they are exact and computationally instant. However, simulation serves as both our universal fallback when math is intractable, and an empirical sanity check on our equations.

#### Where Naive Simulation Breaks Down

While skewed and heavy-tailed distributions simply require larger simulation budgets ($m$) to stabilize, standard simulation breaks down fundamentally in three distinct regimes:

| Failure Regime | Mathematical Cause | Observable Consequence | Epistemic Lesson |
| :--- | :--- | :--- | :--- |
| **1. Undefined Moments** (for example, Cauchy, Pareto $\alpha \le 1$) | $\mathbb{E}[\|X\|] = \infty$; Law of Large Numbers fails. | Cumulative sample averages fluctuate wildly forever; never stabilizes. | Simulation cannot approximate a quantity that does not mathematically exist. |
| **2. Rare Events** (Extreme Tails) | Event probability $p \ll 1/m$. | With $m = 10^4$ and $p = 10^{-6}$, expected hits $= 0.01$; simulation returns $\hat{p} = 0$. | Naive simulation is blind to extreme tails. |
| **3. Boundary / Extreme Estimators** ($\max$, $\min$) | Strictly one-sided bias: sample extreme can never exceed the true ceiling ($X_{(n)} < \theta$). | For unbounded distributions, sample extremes drift toward infinity. Bootstrap creates a discrete 63.2% spike. | Extremes depend on sharp edges rather than smooth mass; standard simulation cannot reliably explore beyond observed limits. |

---

### The Fundamental Conundrum of Inference

If nature gave us access to the true Data Generating Process ($F$), a simulation would be all we ever need. But in empirical science, $F$ is unknown and our sample size $n$ budget is limited. Statistical inference is the bridge from the data we saw (empirical distribution $F_n$) to the process we didn't see (DGP $F$).

---

### Tier 4 Stochastic Error & The Square-Root Law

Even if theoretical models (Tier 1), methoology (Tier 2), and instruments (Tier 3) are flawless, Tier 4 Stochastic Error is unavoidable whenever $n < \infty$.

* **The Scaling Law:** Standard error decreases inversely with the square root of $n$:
  $$\operatorname{SE}(\bar{Y}) = \frac{\sigma}{\sqrt{n}} \propto n^{-1/2}$$
* **Diminishing Returns:** Halving your margin of error requires $4\times$ the sample size. Cutting error by a factor of 10 requires $100\times$ the sample size.
* **Sampling Error $\neq 0$:** Unless you systematically enumerate the entire finite population, sampling-based estimates are never completely certain!

---

### The Nested Inner PPDAC: Sample-Size Planning in Stage Plan

To choose $n$ before collecting data, we encounter a paradox: we need a model of the DPG to calculate $n$, but PPDAC says we build models during stage Analysis. We resolve this by embedding a nested Inner PPDAC cycle inside Stage Plan:

$$\text{OUTER PPDAC: } \text{Problem} \longrightarrow \left[ \text{Plan} \longrightarrow \mathbf{\text{Inner PPDAC (Find } n\text{)}} \longrightarrow \text{Lock } n \right] \longrightarrow \text{Data} \longrightarrow \text{Analysis} \longrightarrow \text{Conclusion}$$

Note that statistics alone cannot tell you what error is acceptable. That is a domain constraint decided in Stage Problem. Furthermore, because we can never be completely certain with finite samples, we can only give error guarantees with a certain probability!

To compute the required sample size, we must determine the properties of the underlying DPG, which depend on the very parameters we are trying to estimate. In practice, we need some additional information. Sources of information can be existing empirical results, a pilot study, or derivation from first principles. Even when completely ignorant, we can often determine worst-case bounds.

*In our beads case we chose the Bernoulli distribution as a good enough approximation to the underlying DGP. The parameter of interest was $p$, the proportion of 1s. We opted for the standard 95% probability that the error stays within perscriped error tolerance $|\hat{p} - p| \le 0.15$ ($95\%$ confidence, or $\le 5\%$ error rate). Theory tells us that $\operatorname{Var}(Y) = p(1 - p)$ achieves its global maximum at $p = 0.50$ ($\operatorname{Var}_{\max} = 0.25$). Designing for $p = 0.50$ guaranted that sample-size precision guarantees hold in the worst-case scenario. Under $p = 0.50$, our simulation bounds showed that $n = 50$ ensures that $P(|\hat{p} - p| > 0.15) \le 0.05$. We could also have arrived to a similar conclusion without simulation, taking into account that error is approximately the squared root of variance divided by sample size $n$.*

---

### The Non-Parametric Bootstrap

If all the properties of the underliying DGP are know, as is the case in our theoretical analysis of minimum required $n$, we can rely on simulation to estimate error with arbitrary precision. However, for analyzing the error of our estimate on the final sample, the properties of the DGP are not known and we only have one sample if size $n$.

It turns out that we can still rely on simulation, just with another layer of approximation, additionally relying on the empirical sample $F_n$ being similar to the underlying DGP $F$:

* **One iteration if the DGP were known:**
  $$\text{DGP } (F) \xrightarrow{\quad \text{Draw a sample of size } n \quad} \text{Observed Sample } (F_n)$$
* **One iteration with the Bootstrap:**
  $$\text{DATA } (F_n) \xrightarrow{\quad \text{Draw a sample of size } n \text{ with replacement} \quad} \text{Bootstrap Replication } (F_n^*)$$
  
Statistical theory all ready tells us that $F_n$ converges to $F$ as $n$ grows. With rare exceptions that require deeper mathematical exploration, a parameter $T(F_n)$ also converges to $T(F)$ as $n$ grows. So, for practical purposes, it is not a question whether this key assumption of bootstrap works, but only how big does $n$ have to be in order for it to work well enough (see Readings below).
  
With the exception of this additional assumption, bootstrap is identical to our simulation of the distribution of a property of a known DGP:

#### The 4-Step Bootstrap Algorithm
1. **Input:** Dataset of size $n$: $\mathbf{y} = (y_1, y_2, \dots, y_n)$.
2. **Resample:** Draw $n$ observations **with replacement** from $\mathbf{y}$ to form a bootstrap sample $\mathbf{y}^*$.
3. **Compute:** Calculate the statistic of interest: $\hat{\theta}^* = T(\mathbf{y}^*)$.
4. **Repeat:** Repeat Steps 2–3 a total of $B$ times to generate the sampling distribution. This distribution allows us to compute, among other things, the two primary currencies of uncertainty:
   * **Bootstrap Standard Error:** $\widehat{\text{SE}}_{\text{boot}}(\hat{\theta}) = \operatorname{sd}(\hat{\theta}^*)$
   * **95% Percentile Confidence Interval:** $[\hat{\theta}^*_{0.025}, \; \hat{\theta}^*_{0.975}]$

#### Why the Non-Parametric Bootstrap is so Powerful
* **No Closed-Form Required:** Works seamlessly for medians, 90th percentiles, variance ratios, or complex non-linear indices where analytical math is intractable.
* **One Universal Code Pattern:** The exact same resampling loop applies whether the estimator is a simple mean or a high-dimensional machine learning pipeline.
* **Distribution-Free:** Works directly with the empirical shape of the data, naturally tracking skewness.

---

### The Epistemic Meaning of a Confidence Interval

If a 95% bootstrap percentile interval for our beads proportion yields $[0.32, \; 0.60]$:

* **What it DOES NOT mean:** There is a 95% probability that the true proportion $p$ lies between 0.32 and 0.60. *(In the frequentist framework, the parameter $p$ is a fixed physical constant of nature. It does not move, fluctuate, or have a probability distribution).*
* **What it ACTUALLY means:** The interval is the random entity. If we repeat this entire sampling and analysis pipeline thousands of times, approximately 95% of the resulting intervals will successfully cover the fixed true parameter, and 5% will miss it entirely.

Confidence is an epistemic property of the procedure over repeated deployments, not a probability attached to a single realized interval.

---

### Post-Lecture Reflections

* What is the fundamental difference between sample size ($n$) and bootstrap replications ($B$)? What happens to the result (mean and confidence interval) if we increase or decrease one versus the other?
* If our physical shaking between beads draws was extremely lazy, what would happen to the result (mean, standard error, and confidence interval), and what diagnostic check would expose this?
* Recommended Readings:
  * **Hesterberg, T. C. (2015).** *What teachers should know about the bootstrap: Resampling in the undergraduate statistics curriculum.* The American Statistician, 69(4), 371–386.
  * **Krzywinski, M., & Altman, N. (2013)**. *Points of Significance: Error bars.* Nature Methods, 10(10), 921–922.
  * **Zrimšek, U., & Štrumbelj, E. (2026).** *Quantifying uncertainty: all we need is the bootstrap?* Journal of Statistical Computation and Simulation, 96(4), 1009–1027.
