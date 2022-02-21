if command -v apt-get &> /dev/null
then
  # system depedencies
  sudo apt-get update -y
  sudo apt-get install -y libssl-dev libcurl4-openssl-dev libxml2-dev
  sudo apt-get install -y libicu-dev
  sudo apt-get install -y libglpk-dev
  sudo apt-get install -y libgmp3-dev
  sudo apt-get install -y libxml2-dev
  sudo apt-get install -y pandoc
fi

# r dependencies
Rscript -e \
'
options(repos = c(CRAN = "https://packagemanager.rstudio.com/all/__linux__/focal/latest"))
if (!require("tidymodels")) install.packages("tidymodels")
if (!require("textrecipes")) install.packages("textrecipes")
if (!require("stringr")) install.packages("stringr")
if (!require("aws.s3")) install.packages("aws.s3")
if (!require("tibble")) install.packages("tibble")
if (!require("stopwords")) install.packages("stopwords")
if (!require("ranger")) install.packages("ranger")
if (!require("knitr")) install.packages("knitr")
'
