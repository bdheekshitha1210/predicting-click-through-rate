library(data.table)
library(tidyverse)
library(ranger)

###########################################
d <- fread("training1.csv", data.table = F)

# Doing a 70-15-15 split on into 'calibration' and validation samples
TrainInd <- ceiling(nrow(d)*0.7)
d_train <- d[1:TrainInd,]
d_cal <- d[(TrainInd+1):(nrow(d)-floor(nrow(d)*0.15)),]
d_val <- d[((nrow(d)-floor(nrow(d)*0.15))+1):nrow(d),]

rm(d)

# Extracting time data
d_train$hr <- substr(d_train$hour, 7, 8)
d_val$hr <- substr(d_val$hour, 7, 8)
d_cal$hr <- substr(d_cal$hour, 7, 8)

d_train$day <- substr(d_train$hour, 5, 6)
d_val$day <- substr(d_val$hour, 5, 6)
d_cal$day <- substr(d_cal$hour, 5, 6)

# Interactions with day
d_train$day_app <- paste0(d_train$app_id, d_train$day)
d_val$day_app <- paste0(d_val$app_id, d_val$day)
d_cal$day_app <- paste0(d_cal$app_id, d_cal$day)

d_train$day_site <- paste0(d_train$site_id, d_train$day)
d_val$day_site <- paste0(d_val$site_id, d_val$day)
d_cal$day_site <- paste0(d_cal$site_id, d_cal$day)

d_train$day_ip <- paste0(d_train$device_ip, d_train$day)
d_val$day_ip <- paste0(d_val$device_ip, d_val$day)
d_cal$day_ip <- paste0(d_cal$device_ip, d_cal$day)

d_train$day_id <- paste0(d_train$device_id, d_train$day)
d_val$day_id <- paste0(d_val$device_id, d_val$day)
d_cal$day_id <- paste0(d_cal$device_id, d_cal$day)

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

# Visualize prior
hist(rbeta(10000, alpha, beta))

# Getting training click ratios for each feature
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
  
  # Fill in dataframes with values
  d_cal[,summary_var] <- summary[,summary_var][match(d_cal[,feature], summary[,1])]
  d_cal[,summary_var] <- ifelse(is.na(d_cal[,summary_var]), 0, d_cal[,summary_var])
  d_val[,summary_var] <- summary[,summary_var][match(d_val[,feature], summary[,1])]
  d_val[,summary_var] <- ifelse(is.na(d_val[,summary_var]), 0, d_val[,summary_var]) 
}

# Extracting just the click and ratio vars
feature_names <- colnames(d_cal)
feature_names <- c("click", feature_names[substr(feature_names, nchar(feature_names)-4, nchar(feature_names)) == "ratio"])

d_cal <- d_cal[,feature_names]
d_val <- d_val[,feature_names]

d_cal[,1] <- as.factor(d_cal[,1])
d_val[,1] <- as.factor(d_val[,1])

### Fitting glm, first calibrate parameters, then validate predictions
##### Logistic regression #####
glm_1 <- glm(click ~ ., family="binomial", data=d_cal)
saveRDS(glm_1, "glm_1.rds")

# Convienience function
inv_logit <- function (x) {
  p <- 1/(1 + exp(-x))
  p <- ifelse(x == Inf, 1, p)
  p
}

# Log loss for GLM
glm_pred <- inv_logit(predict(glm_1, newdata=d_val))
ll_glm <- as.numeric(as.character(d_val$click)) * log(glm_pred) + (1-as.numeric(as.character(d_val$click)))*log(1-glm_pred)
ll_glm <- -1 * sum(ll_glm) * (1/length(ll_glm))

#### Random forest ####
rf <- ranger(click ~., data=d_cal, num.trees = 150, probability=T)
saveRDS(rf, "rf.rds")
pred_rf <- predict(rf, data=d_val)


col_pick <- which.min(apply(pred_rf$predictions, 2, mean))

PHat <- pred_rf$predictions[,col_pick] # verify using col 1 rather than 2, depends on how data was factored and read from csv. Use the col that has the smaller predictions--that's the Pr of click.
hist(pred_rf$predictions[,1])
hist(pred_rf$predictions[,2])

PHat <- ifelse(PHat == 0, 0.001, PHat)
PHat <- ifelse(PHat == 1, 0.999, PHat)

ll_rf <- as.numeric(as.character(d_val$click)) * log(PHat) + (1-as.numeric(as.character(d_val$click)))*log(1-PHat)
ll_rf <- -1 * sum(ll_rf) * (1/length(ll_rf))

