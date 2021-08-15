#Import Libraries
library(data.table)
install.packages("mltools")
library(mltools)


###########function to reduce the levels

sparse20_fac <- function(x) {
  x <- as.character(x)
  freq <- table(x)
  
  max_level <- min(c(length(freq),20))[1]
  freq <- sort(freq, decreasing=T)
  
  x[!(x %in% names(freq[1:max_level]))] <- "z"
  x<-as.factor(x)
  return(x)
}


############set the directory
getwd()
setwd("C:/Users/banva/Desktop/ML Project/Mayur Kumar")
getwd()

############Import the training dataset
train= fread("ProjectTrainingData.csv")
names(train)[3]<-"time"

#let's assign to new dataframe just so incase if we mess up
data=train

############Get hours and weekdays from the dataset
data[, time:= as.POSIXct(as.character(data$time), format="%y%m%d%H")] # convert format of time variable to date
data[, hour:= hour(time) ] # get hour of day from date
data[, day_of_week := weekdays(time)] # get day of week from date
data$time <- NULL # get rid of broader time variable since no longer needed


############# split the dataset into 6% for training, 
trainIndex <- sample(1:nrow(data), size = round(0.006 * nrow(data)),replace = FALSE) # get training index for split
train_df <- data[trainIndex,] # create training data

#see the distribution of target variable
table(train_df$click)

val_df <- data[-trainIndex,] # create validation data

# further split the validation data into val1 and val2, to have separate datasets for parameter optimization and model evaluation
valindex <- sample(1:nrow(val_df), size = round(0.005 * nrow(val_df)),replace = FALSE)
val1 <- val_df[valindex,]

