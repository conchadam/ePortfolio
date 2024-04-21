##Mitzie Irene Conchada
##Test 2

#1.SLG = (1B) + (2 × 2B) + (3 × 3B) + (4 × HR) /  AB 
#Who holds the top career SLG record and why? Use the baseball dataset within the plyr package
install.packages("plyr")
library(plyr)
data("baseball")
head(baseball)
tail(baseball)

#check first if there are any NAs in the dataframe
any(is.na(baseball))

#say we want to replace NAs with 0s for the variables: h,X2b, X3b, hr, ab
baseball$sf[is.na(baseball$h)]
baseball$sf[is.na(baseball$h)] <- 0
any(is.na(baseball$h))

baseball$sf[is.na(baseball$X2b)]
baseball$sf[is.na(baseball$X2b)] <- 0
any(is.na(baseball$X2b))

baseball$sf[is.na(baseball$X3b)]
baseball$sf[is.na(baseball$X3b)] <- 0
any(is.na(baseball$X3b))

baseball$sf[is.na(baseball$hr)]
baseball$sf[is.na(baseball$hr)] <- 0
any(is.na(baseball$hr))

baseball$sf[is.na(baseball$ab)]
baseball$sf[is.na(baseball$ab)] <- 0
any(is.na(baseball$ab))

#Using the formula: SLG = (1B) + (2 × 2B) + (3 × 3B) + (4 × HR) /  AB
a <- baseball$X2b*2
b <- baseball$X3b*3
c <- baseball$hr*4

baseball$a <- baseball$X2b*2
baseball$b <- baseball$X3b*3
baseball$c <- baseball$hr*4

baseball1 <- ddply(baseball, .(id), summarize, numerator=sum(h,a,b,c), denomenator=sum(ab), 
      SLG=(numerator/denomenator), order(SLG) <= 2)

baseball1


#Based on the results, player with ID aaronha01 holds the top career record because he has the highest SLG of 0.67397282

#2. Using the sleep dataset in the datasets package, calculate the average difference in 
#extra sleep between group 1 and 2 using aggregate. Which group had more sleep?
data("sleep")
summary(sleep)

library(skimr)
skim(sleep)

aggregate(extra ~ group, sleep, each(mean))

#Visually inspect the data by plotting histograms of sleep by group using ggplot. 
install.packages("ggplot2")
library(ggplot2)

ggplot(data = sleep) + geom_histogram(aes(x=extra))
#not sure about the by group

#Compute a two-sampled t-test in the data and report the p-value. 
#In words, describe what the resulting p-value for this test means.

##conduct a 2 sample t test checking if the mean extra is equal for Group 1 and 2
#Null hypothesis: equal sleep for Group 1 and 2
#Alternative hypothesis: sleep is not the same/not equal between Group 1 and 2

install.packages('reshape2')
library(reshape2)

mean(sleep$extra)

t.test(sleep$extra,sleep$group, alternative='two.sided', mu=1.54)
t.test(extra ~ group, data=sleep, var.equal=T)

#Interpretation: since p-value is 0.07919 (pvalue is insignificant, greater than 0.05), 
#we fail to reject the Null hypothesis which mean that the mean extra is the same for Group 1 and 2


#3. Do better movie reviews translate to larger box office revenues? 
#To answer this question, we will regress box office revenues against a coarse 
#measure of movie reviews taken from a popular movie review website
#a. download file (from my local computer)
moviereview <- read.csv(file.choose())
path <- "C:/Users/Dell/Downloads/box_office.xls"
movie <- read_excel(path)

#b. Next use whatever exploratory data methods you prefer to familiarize yourself with the data.
summary(movie)
library(skimr)
skim(movie)

cor(movie[,c(:)])
#c.	Present at least two regression models which in some way answers the questions:
#i.do top critics reviews affect estimated revenues different from all critics?,
#ii.	and do more good or bad reviews increase revenues?
#iii.	Present summary statistics for linear models

movie <- lm(     data= movie) 
summary( )

install.packages("readxl")
install.packages("dplyr")
install.packages("ggplot")

library(readxl)
library(dplyr)
library(ggplot2)

url <- "http://www.stat.ufl.edu/~winner/data/box_office.xls"
download.file(url,"box_office.xls", mode = "wb")
box_office <- read_xls("box_office.xls")
summary(box_office)
str(box_office)

model1 <- lm(Revenues ~ AllPos, data = box_office)
model1
summary(model1)

model2 <- lm(Revenues ~ AllPos +AllNeg, data = box_office)
model2
summary(model2)


#4.Load the orings dataset from the package DAAG. The dataset contains information on 
#characteristics of space shuttle launches in the early 1980s, and the number and type of O-ring failures . 

install.packages("DAAG")
library(DAAG)

data("orings")

#We will investigate using logistic regression whether temperature of the launch has an impact on the 
#probability of O-ring failure. First, create a binary indicator of whether there is any erosion (Erosion) 
#or "blow-by" (Blowby), which are both indicators of damage to the O-ring seals. 
summary(orings)

#Predict 
orings$yvar <- with(orings,Total >= 0.4783)
head(orings)

names(orings)
orings_model <- orings[,c(5,1)]
dim(orings_model)



#split data set first
set.seed(1)
sample <- sample(c(TRUE,FALSE),nrow(orings_model),replace=TRUE,prob=c(0.7,0.3)) #70%train and 30%test; usually bigger for train 
sample

#Next, estimate a GLM model 
#where this binary indicator is the response (y), and temperature is a predictor(x). 
#Does temperature impact the risk?

#create train dataset
train <- orings_model[sample,]
test <- orings_model[!sample,]

names(orings_model)
orings_model <- glm(yvar ~ Temperature, data=train,
                    family='binomial'(link='logit'))

summary(orings_model)
#interpretation: Since the p-value of temperature (0.0736) is less than 0.05, 
#it is not significant in affecting changes in erosion or blowby


orings_model


head(test)
test$prob <- predict(orings_model, test, type='response')

#if we highlight predict onwards, we get the ff.
#then run all

head(test)
#at what prob will you convert yes to know; at least 50% 

#create new col
test$class <- ifelse(test$prob > 0.5, TRUE, FALSE)
head(test)

#create   matrix 
table(test$yvar, test$class)
table(test$yvar, test$class)/8

#if we increase cut off to 0.6
test$class <- ifelse(test$prob > 0.6, TRUE, FALSE)
head(test)
table(test$yvar, test$class)
table(test$yvar, test$class)/8
#the .5 and .6 will depend on the accuracy 

#we get the same answer

#5. Load the us.civil.war.battles dataset in the package cluster.datasets.
install.packages("cluster.datasets")
library(cluster.datasets)
data("us.civil.war.battles")

#Identify the optimal number of clusters using the elbow method.
install.packages('GGally')
library(GGally)

cor(us.civil.war.battles[,c(2:5)])

battle <- read.table('us.civil.war.battles,header' = FALSE, sep = ",", stringsAsFactors = T,
                     col.names = c('union.forces','union.shot','confederate.forces','confederate.shot'))




#Run an off-the-shelf k-means clustering algorithm with optimal k.
#How did the model do?
#Plot the PCA representation of the model using the plot function from useful and examine the fit.
