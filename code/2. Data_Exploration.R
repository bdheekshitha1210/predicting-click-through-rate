library(readr)
library(data.table)
df <- fread("C:/Users/banva/Desktop/ML Project/Mayur Kumar/ProjectTrainingData.csv")


############################################Data Exploration, Understanding, Cleaning######################################


#Let's check for NAs in the data
sapply(df, function(i) sum(is.na(i))) #No NAs in the data


#Let's check the distribution for "Target" Variable.
Y_variable = sort(table(df$click))/sum(sort(table(df$click))) #83% No clicks, 17% Clicks. Imbalanced data
Y_variable



#Let's Understand Independent Variables

#Let's check classes for each independent variable
sapply(df, function(i) class(i)) #Looks like there are a lot of variables whose classes need to be changed to appropriate class  


#Get names of categorical variables
factor_cols <- colnames(df[,4:24]) 


#factorise categorical variables
df[, (factor_cols) := lapply(.SD, as.factor), .SDcols=4:24] #This changed all the mentioned columns to factors


#Get number of levels for each categorical variable
Levels <- df[, lapply(.SD, function(i) length(levels(i))), .SDcols=4:24] # get table with frequency of occurrence for each variable
Levels <- melt(Levels,  measure.vars=c(1:21), variable.name="variable", value.name="frequency") # transpose format to get a frequency table


# for each variable to fix, get data table with count and proportion of values by each unique level, ordered from highest to lowest 
num_rows <- nrow(factors_data) # get total number of rows in data for proportion calculation
freq_tables_list <- data.table() # initialize an empty list

# store a datatable that has the frequency count for each variable in a nested list
for (n in Levels$variable){ # loop through variable names 
  temp <- df[, .(freq=.N, prop=.N/nrow(df)), by=n][order(-freq)] # get data table containing each variable's data by level
  freq_tables_list <- c(freq_tables_list, list(temp))
}



device_ip = data.frame(freq_tables_list[[9]])

# split the dataset into 60% for training, 20% for validation 1 and 20% for validation 2
trainIndex <- sample(1:nrow(df), size = round(0.6 * nrow(df)),replace = FALSE) # get training index for split
train <- df[trainIndex,] # create training data
val <- df[-trainIndex,] # create validation data

# further split the validation data into val1 and val2, to have separate datasets for parameter optimization and model evaluation
valindex <- sample(1:nrow(val), size = round(0.5 * nrow(val)),replace = FALSE)
val1 <- val[valindex,]
val2 <- val[-valindex,]





