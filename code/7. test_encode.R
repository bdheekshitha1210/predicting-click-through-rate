library(data.table)
library(tidyverse)

d <- fread("training1.csv", data.table = F)

TrainInd <- ceiling(nrow(d)*0.7)
d_train <- d[1:TrainInd,]
rm(d)

# Extracting time data
d_train$hr <- substr(d_train$hour, 7, 8)
d_train$day <- substr(d_train$hour, 5, 6)

# Interactions with day
d_train$day_app <- paste0(d_train$app_id, d_train$day)
d_train$day_site <- paste0(d_train$site_id, d_train$day)
d_train$day_ip <- paste0(d_train$device_ip, d_train$day)
d_train$day_id <- paste0(d_train$device_id, d_train$day)

# Transformation function
logit <- function (x) {
  log(x) - log(1 - x)
}

# Prior for encoding
mu <- mean(d_train$click)
var <- 0.05

# Beta regularization terms
alpha <- ((1 - mu) / var - 1 / mu) * mu^2
beta <- alpha * (1 / mu - 1)

# Getting training click ratios for each feature
summary_list <- list()
for (p in 3:ncol(d_train)) {
  feature <- names(d_train)[p]
  summary_var <- paste0(names(d_train)[p],"ratio")
  
  # Ratio of clicks/obs
  summary <- d_train %>% group_by(!!sym(feature)) %>% summarise(s = sum(click), n=n())
  
  # Posterior prob of click|features,prior
  summary <- as.data.frame(summary)
  
  summary$post_alpha <- summary$s + alpha
  summary$post_beta <- summary$n - summary$s + beta
  summary[,summary_var] <- logit( summary$post_alpha / (summary$post_alpha + summary$post_beta) )
  
  # Center according to global mean
  summary[,summary_var] <- summary[,summary_var] - logit(mean(d_train$click))
  if (is.integer(summary[,1] == T)) summary[,1] <- as.character(as.numeric(summary[,1]))
  summary_list[[p]] <- summary
}

train_names <- names(d_train)
rm(d_train)

d_test <- fread("Project Data/ProjectTestData.csv", data.table = F)

# Extracting time data
d_test$hr <- substr(d_test$hour, 7, 8)
d_test$day <- substr(d_test$hour, 5, 6)

# Interactions with day
d_test$day_app <- paste0(d_test$app_id, d_test$day)
d_test$day_site <- paste0(d_test$site_id, d_test$day)
d_test$day_ip <- paste0(d_test$device_ip, d_test$day)
d_test$day_id <- paste0(d_test$device_id, d_test$day)

for (p in 3:length(train_names)) {
  feature <- train_names[p]
  summary_var <- paste0(train_names[p],"ratio")
  summary <- summary_list[[p]]
  
  # Fill in dataframes with values
  d_test[,summary_var] <- summary[,summary_var][match(d_test[,feature], summary[,1])]
  d_test[,summary_var] <- ifelse(is.na(d_test[,summary_var]), 0, d_test[,summary_var])
}

# Extracting just the click and ratio vars
feature_names <- colnames(d_test)
feature_names <- feature_names[substr(feature_names, nchar(feature_names)-4, nchar(feature_names)) == "ratio"]

d_test <- d_test[,feature_names]
d_test <- round(d_test[,feature_names],5) # save some space in csv

fwrite(d_test, "test_encoding.csv")

