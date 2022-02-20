library(tidymodels)
library(textrecipes)
library(stringr)

tweets <- tibble::as_tibble(read.csv("data/tweets.csv"))

tweets_split <- initial_split(tweets, strata = medical_device)
tweets_train <- training(tweets_split)
tweets_test <- testing(tweets_split)

str_clean <- function(x) {
  x <- str_remove_all(x, pattern = "[[:digit:]]")
  x <- str_remove_all(x, pattern = "[[:punct:]]")
  x <- str_replace_all(x, pattern = "(.)\\1{2,}", " ")
  str_squish(x)
}

# preprocessing recipe
tweets_rec <- recipe(medical_device ~ text, data = tweets_train) %>%
  step_mutate_at(medical_device, fn = as.factor, skip = TRUE) %>%
  step_mutate_at(text, fn = str_clean) %>%
  step_tokenize(text) %>%
  step_stopwords(text) %>%
  step_tokenfilter(text) %>%
  step_stem(text) %>%
  step_tfidf(text)

# # whats it look like?
# tweets_rec %>%
#   prep() %>%
#   juice()

# workflow
tweets_wf <- workflow() %>%
  add_recipe(tweets_rec)

# model spec
tweets_spec <- rand_forest(trees = 100) %>%
  set_mode("classification") %>%
  set_engine("ranger")

# tie preprocess and model spec together
tweets_mod <- tweets_wf %>%
  add_model(tweets_spec)

# fit
tweets_fit <- tweets_mod %>%
  fit(tweets_train)

# results
tweets_res <- tweets_fit %>%
  predict(tweets_test) %>%
  bind_cols(predict(tweets_fit, tweets_test, type = "prob")) %>%
  bind_cols(tweets_test %>% select(medical_device)) %>%
  mutate(medical_device = as.factor(medical_device))

# ------------------------------------------------------------------------------
#' outputs for pull request
# ------------------------------------------------------------------------------

# recipe in free text form
writeLines(
  text = c("## Fit information", "```", capture.output(tweets_fit), "```"),
  con = "fit.md"
)

# confusion matrix
writeLines(
  text = c("## Confusion matrix", "```", capture.output(conf_mat(tweets_res, truth = medical_device, .pred_class)), "```"),
  con = "conf.md"
)

# accuracy
writeLines(
  text = c("## Accuracy", capture.output(knitr::kable(accuracy(tweets_res, truth = medical_device, .pred_class)))),
  con = "accuracy.md"
)

# metrics.json
metrics <- list(
  metrics = metrics(tweets_res, medical_device, .pred_class),
  roc_auc_false = roc_auc(tweets_res, medical_device, .pred_FALSE),
  roc_auc_true = roc_auc(tweets_res, medical_device, .pred_TRUE),
  precision = precision(tweets_res, medical_device, .pred_class)
)


jsonlite::write_json(metrics, "metrics.json", pretty = TRUE)
