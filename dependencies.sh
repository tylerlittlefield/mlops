# system depedencies
sudo apt-get update -y
sudo apt-get install -y libssl-dev libcurl4-openssl-dev libxml2-dev
sudo apt-get install -y libicu-dev
sudo apt-get install -y libglpk-dev
sudo apt-get install -y libgmp3-dev
sudo apt-get install -y libxml2-dev
sudo apt-get install -y pandoc

# r dependencies
Rscript -e \
'install.packages(c(
  "tidymodels",
  "textrecipes",
  "stringr",
  "aws.s3",
  "tibble",
  "stopwords",
  "ranger",
  "knitr"
), repos = c(CRAN = "https://packagemanager.rstudio.com/all/__linux__/focal/latest"))'
