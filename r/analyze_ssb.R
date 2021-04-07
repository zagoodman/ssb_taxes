## Import packages and data ----

# packages
library('did')
library('dplyr')
library('here')

# data

df <- read.csv('../data/gen_data/panelist_nutrition_month.csv')
summary(df)
head(df)


## Diff-in-diff ----

IRkernel::installspec(user = FALSE) 
