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
install.packages("tidymodels")
install.packages("textrecipes")
install.packages("stringr")
install.packages("aws.s3")
install.packages("tibble")
install.packages("stopwords")
install.packages("ranger")
install.packages("knitr")
'
