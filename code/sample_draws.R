library(data.table)
library(tidyverse)

con <- file("ProjectTrainingData.csv","r")
header <- unlist(strsplit(readLines(con,n=1), ","))

# Making samples
d <- fread("shuf -n 15000000 ProjectTrainingData.csv", data.table=F)
colnames(d) <- header
write_csv(d[,-1], "training1.csv")
#Samples drawn
