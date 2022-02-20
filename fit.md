## Fit information
```
══ Workflow [trained] ══════════════════════════════════════════════════════════════════════════════════════════
Preprocessor: Recipe
Model: rand_forest()

── Preprocessor ────────────────────────────────────────────────────────────────────────────────────────────────
7 Recipe Steps

• step_mutate_at()
• step_mutate_at()
• step_tokenize()
• step_stopwords()
• step_tokenfilter()
• step_stem()
• step_tfidf()

── Model ───────────────────────────────────────────────────────────────────────────────────────────────────────
Ranger result

Call:
 ranger::ranger(x = maybe_data_frame(x), y = y, num.trees = ~100,      num.threads = 1, verbose = FALSE, seed = sample.int(10^5,          1), probability = TRUE) 

Type:                             Probability estimation 
Number of trees:                  100 
Sample size:                      3479 
Number of independent variables:  99 
Mtry:                             9 
Target node size:                 10 
Variable importance mode:         none 
Splitrule:                        gini 
OOB prediction error (Brier s.):  0.05910723 
```
