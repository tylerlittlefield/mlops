library(tidymodels)
library(textrecipes)
library(stringr)
library(themis)

params <- yaml::read_yaml("params.yaml")

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
  step_upsample(medical_device) %>%
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
p <- params$tune$penalty
tweets_spec <- logistic_reg(penalty = p, mixture = 1) %>%
  set_mode("classification") %>%
  set_engine("LiblineaR")

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
  text = c("```", capture.output(tweets_fit), "```"),
  con = "fit.md"
)

# confusion matrix
ggsave(
  filename = "conf.png",
  plot = autoplot(conf_mat(tweets_res, truth = medical_device, .pred_class), type = "heatmap"),
  width = 10,
  height = 10
)

# roc curves
ggsave(
  filename = "roc_true.png",
  plot = autoplot(roc_curve(tweets_res, medical_device, .pred_TRUE)) +
    labs(title = "ROC Curve for TRUE class")
)

ggsave(
  filename = "roc_false.png",
  plot = autoplot(roc_curve(tweets_res, medical_device, .pred_FALSE)) +
    labs(title = "ROC Curve for FALSE class")
)

# metrics.json
metrics <- summary(conf_mat(tweets_res, truth = medical_device, .pred_class))

jsonlite::write_json(
  x = lapply(split(metrics, metrics$.metric), jsonlite::unbox),
  path = "metrics.json",
  pretty = TRUE
)
