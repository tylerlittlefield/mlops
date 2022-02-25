suppressPackageStartupMessages({
  library(tidymodels)
  library(textrecipes) # >= 0.4.1.9000
  library(themis)
  library(patchwork)
  library(sessioninfo)
  library(purrr)
  library(jsonlite)
  library(knitr)
})

# ------------------------------------------------------------------------------
#' Read in parameters.
# ------------------------------------------------------------------------------

params <- yaml::read_yaml("params.yaml")

# ------------------------------------------------------------------------------
#' Read in data and prepare training/testing sets.
# ------------------------------------------------------------------------------

set.seed(3435)
data       <- as_tibble(read.csv("data/tweets.csv"))
data       <- select(data, text, class = medical_device)
data_split <- initial_split(data, strata = class)
data_train <- training(data_split)
data_test  <- testing(data_split)
data_fold  <- vfold_cv(data_train)

# ------------------------------------------------------------------------------
#' Preprocessing strategy.
# ------------------------------------------------------------------------------

preprocessor <- data_train %>%
  recipe(class ~ text) %>%
  step_mutate_at(class, fn = as.factor, skip = TRUE) %>%
  step_mutate_at(text, fn = tolower, skip = TRUE) %>%
  step_upsample(class) %>%
  step_tokenize(text) %>%
  step_stopwords(text) %>%
  step_tokenfilter(text, filter_fun = function(x) nchar(x) > 3) %>%
  step_tokenfilter(text, filter_fun = function(x) !grepl("[[:digit:]]", x)) %>%  # removes any words with numeric digits
  step_tokenfilter(text, filter_fun = function(x) !grepl("[[:punct:]]", x)) %>%  # removes any remaining punctuations
  step_tokenfilter(text, filter_fun = function(x) !grepl("(.)\\1{2,}", x)) %>%   # removes any words with 3 or more repeated letters
  step_tokenfilter(text, filter_fun = function(x) !grepl("\\b(.)\\b", x)) %>%    # removes any remaining single letter words
  step_tokenfilter(text, filter_fun = function(x) !grepl("^http", x)) %>%         # remove urls
  step_tokenfilter(text, max_tokens = params$tune$tokens_max) %>%
  step_stem(text) %>%
  step_tfidf(text)

# ------------------------------------------------------------------------------
#' Model selection.
# ------------------------------------------------------------------------------

model <- logistic_reg(penalty = tune(), mixture = 1) %>%
  set_mode("classification") %>%
  set_engine("glmnet")

# ------------------------------------------------------------------------------
#' Workflow.
# ------------------------------------------------------------------------------

flow <- workflow() %>%
  add_recipe(preprocessor) %>%
  add_model(model)

# ------------------------------------------------------------------------------
#' Tune model.
# ------------------------------------------------------------------------------

lambda <- grid_regular(
  x = penalty(range = c(
    params$tune$penalty_min,
    params$tune$penalty_max
  )),
  levels = params$tune$penalty_levels
)

tune <- flow %>%
  tune_grid(data_fold, grid = lambda)

p_tune <- tune %>%
  autoplot()

chosen_auc <- tune %>%
  select_by_one_std_err(metric = "roc_auc", -penalty)

final_flow <- flow %>%
  finalize_workflow(chosen_auc)

# ------------------------------------------------------------------------------
#' Fit model on training folds.
# ------------------------------------------------------------------------------

data_fit <- final_flow %>%
  fit_resamples(data_fold, control = control_resamples(save_pred = TRUE))

p_fit_roc_false <- data_fit %>%
  collect_predictions() %>%
  group_by(id) %>%
  roc_curve(class, .pred_FALSE) %>%
  autoplot() +
  labs(title = "FALSE") +
  theme(legend.position = "none")

p_fit_roc_true <- data_fit %>%
  collect_predictions() %>%
  group_by(id) %>%
  roc_curve(class, .pred_TRUE) %>%
  autoplot() +
  labs(title = "TRUE") +
  theme(legend.position = "none")

p_fit_conf <- data_fit %>%
  conf_mat_resampled(tidy = FALSE) %>%
  autoplot(type = "heatmap")

p_fold  <- p_fit_conf + p_fit_roc_true + p_fit_roc_false

# ------------------------------------------------------------------------------
#' Fit model on testing data.
# ------------------------------------------------------------------------------

final_fit <- last_fit(final_flow, data_split)

p_final_fit_roc_false <- final_fit %>%
  collect_predictions() %>%
  group_by(id) %>%
  roc_curve(class, .pred_FALSE) %>%
  autoplot() +
  labs(title = "FALSE") +
  theme(legend.position = "none")

p_final_fit_roc_true <- final_fit %>%
  collect_predictions() %>%
  group_by(id) %>%
  roc_curve(class, .pred_TRUE) %>%
  autoplot() +
  labs(title = "TRUE") +
  theme(legend.position = "none")

p_final_fit_conf <- final_fit %>%
  conf_mat_resampled(tidy = FALSE) %>%
  autoplot(type = "heatmap")

 estimates <- final_fit %>%
  extract_fit_parsnip() %>%
  tidy() %>%
  arrange(-estimate)

 p_final <- p_final_fit_conf + p_final_fit_roc_true + p_final_fit_roc_false

# ------------------------------------------------------------------------------
#' Model analysis outputs.
# ------------------------------------------------------------------------------

# save graphics
ggsave("tune.png", p_tune, width = 12, height = 6)
ggsave("final.png", p_final, width = 12, height = 6)
ggsave("fold.png", p_fold, width = 12, height = 6)

# save estimates
write.csv(estimates, "estimates.csv", row.names = FALSE)

# save flow record
writeLines(c("```", capture.output(final_flow), "```"), "fit.md")

# save preprocessor summary
writeLines(knitr::kable(summary(preprocessor)), "preprocessor_summary.md")

# save session info
writeLines(c("```", capture.output(session_info()), "```"), "session.md")

# save metrics
metrics <- final_fit %>%
  conf_mat_resampled(tidy = FALSE) %>%
  summary() %>%
  group_split(.metric) %>%
  map(jsonlite::unbox)

names(metrics) <- final_fit %>%
  conf_mat_resampled(tidy = FALSE) %>%
  summary() %>%
  .[[".metric"]]

write_json(metrics, "metrics.json", pretty = TRUE)
