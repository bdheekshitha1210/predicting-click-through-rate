# Predicting-Click-Through-Rate

## Introduction
Online advertising is a form of marketing which delivers promotional messages to consumers via the Internet. Due to the volume of advertisements being published & huge cost associated with marketing campaigns, serving the right advertisement to the right consumer is extremely important. Hence, the ability to predict whether a consumer will click an advertisement on a search engine such as Google will help the firm determine the right advertisement to serve the right consumer. Our project intends to unravel this prediction by creating a classification model, utilizing data of 9 days (Oct 21st - 29th 2014) during which more than 30 million instances of advertisements were served to various consumers.

## Data: 
30 MM records with 21 variables containing demographic information and some undisclosed variables

## Key Challenges and how I addressed them:

### ML algorithm on Rstudio or Python doesn’t accept categorical variables with more than 32 categories:
o	Some of the categorical variables have more than 5000 categories, so I kept the 31 most occurring categories as are, and clubbed the remaining categories into one. I am losing some part of information but this would help from over fitting. #Tradeoff

### Big Dataset:
o	Building models with such a big dataset is very time taking, so I randomly sampled to a dataset which is still a true representation to the original dataset in terms of the category proportions. I found that a randomly sampled dataset size> 4MM is a close representation of the original dataset

### Too many variables after converting to dummy variables:
o	After converting all the categorical variables to dummy variables, our entire dataset bombarded to 300+ dimensional data, which is huge and could lead to curse of dimensionality, so I Int back to the first step which is to further remove certain categories. I removed more categories by building individual logistic regressions between each categorical variable and a target variable, and kept only those categories which have p-value <0.05

## Feature Engineering:
Multi correlation: Removed highly correlated variables. 0.9 is the cut-off I used.
Sequential Forward Selection: Finding out the best combination of variables that lead to the Lowest AIC value.  
Variables removed: Ip address, and mobile devices because these variables are data identifies
Variables created: Instead of Login and Logout timings, I created a duration variable to have the same info in one variable.
### Performance metric: 
Recall and Log Loss:
False Negatives and False positives have uneven costs and benefits. False Negative is very expensive as I am predicting a potential customer as a non-potential customer, which means I am losing out on potential customers. Hence to minimize False negatives, I chose recall as the performance metric, and I want to maximize the recall. Also minimize Log Loss

## Modeling:
•	Train:Test = 80:20
•	GridSearchCV for Hyperparameter Tuning

## Models implemented:

We built and implemented models using the following algorithms:

* Lasso logistic regression
* Ridge logistic regression
* Trees
* Bagging
* Random Forest

The parameters were tuned using different parameters to come up with the optimum values. The performance on validation dataset was as follows:

* Lasso regression - Log loss - 0.4065
* Ridge regression - Log loss - 0.4068
* Trees - Log loss - 0.4229
* Bagging - Log loss - 0.8478
* Random forest - Log loss - 1.14

Hence the best algorithm was lasso regression which was used to predict the clicks on the test set.
