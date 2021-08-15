library(data.table)
library(tidyverse)
library(ranger)

rf <- readRDS("rf.rds")
glm_1 <- readRDS("glm_1.rds")

header <- names(fread("test_encoding.csv", data.table=F, nrows=1))

# Convienience function
inv_logit <- function (x) {
  p <- 1/(1 + exp(-x))
  p <- ifelse(x == Inf, 1, p)
  p
}

# We'll make predictions on test data in chunks to conserve memory
n_test <- 13015341
ind_seq <- c(1,(floor(n_test/5))*(1:5) )
ind_seq[length(ind_seq)] <- n_test

for (s in 1:(length(ind_seq)-1)) {
  
if (s == 1) row_select <- ind_seq[s]:ind_seq[s+1]
if (s > 1) row_select <- (ind_seq[s]+1):ind_seq[s+1]

skip_seq <- 1:n_test %in% row_select
seq <- rle(skip_seq)
idx <- c(0, cumsum(seq$lengths))[which(seq$values)] + 1
indx <- data.frame(start=idx, length=seq$length[which(seq$values)])

d_test <- do.call(rbind,apply(indx,1, function(x) return(fread("test_encoding.csv",nrows=x[2],skip=x[1], data.table=F))))

id <- do.call(rbind,apply(indx,1, function(x) return(fread("Project Data/ProjectSubmission-TeamX.csv",nrows=x[2],skip=x[1], data.table=F))))[,1]

names(d_test) <- header

set.seed(205)
pred_rf <- predict(rf, data=cbind(click=rep(0, nrow(d_test)), d_test))

col_pick <- which.min(apply(pred_rf$predictions, 2, mean))
PHat <- pred_rf$predictions[,col_pick]

glm_pred <- inv_logit(predict(glm_1, newdata=d_test))
ensemble_pred <- data.frame(id = id, p_click=(glm_pred + PHat)/2 )
names(ensemble_pred)[2] <- "P(click)"

rm(glm_pred)
rm(pred_rf)

if (s == 1) fwrite(ensemble_pred, "ProjectSubmission-Team6.csv", append=FALSE)
if (s > 1) fwrite(ensemble_pred, "ProjectSubmission-Team6.csv", append = TRUE)
rm(ensemble_pred)
print(paste("s =",s))
}

