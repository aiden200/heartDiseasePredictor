Stat 220, Final Project
================

## URL for webpage/shiny app

<https://aiden200.shinyapps.io/final_project/>

## URL to screencast (if not embedded in webpage):

<https://carleton.hosted.panopto.com/Panopto/Pages/Viewer.aspx?id=d3723920-9468-4105-b95f-ade60022d512>

## List of files in the repository

within the final\_project directory two files are contained. The
directory “data” contains our data, which in this case is only
heart.csv. This dataset is an open source dataset of medical records
related to Cardiovascular diseases from kaggle. app.R is our shiny app
that contains the code that manupilates our data in order to be deployed
as a shiny app.

## Brief technical report

Interested by the heart disease dataset and modern efforts to predict
future medical issues and diagnoses, we wanted to create an interactive
app that made a heart disease diagnosis accessible to users who may not
have the resources or time to visit a doctor. This heart disease dataset
is composed of five individual heart datasets pertaining to
heart-related data in Cleveland, Hungary, Switzerland, Long Beach (VA),
and the Statlog data set. With this in mind, we knew that the heart
disease diagnosis would require classification. Thus, we needed to
determine which variables from the dataset are the most significant in
typical diagnoses. After researching heart disease, we established that
five variables from our data set essential for any heart disease
diagnosis. These include the sex (male or female), age (in years),
resting blood pressure (mm Hg), cholesterol amount (mm/dl), and whether
or not the person has heart disease. Given that the diagnosis is a
matter of classification, it was evident that the heart disease variable
would be the result/classifier of the data because we are trying to
determine whether or not the user will have heart disease. Understanding
that using four variables in a k-nearest-neighbors model and graphs
would be overly complicated or nearly impossible, we decided to split
the data by sex. This also works given that female heart data and male
heart data are significantly different in the data set. Left with the
three variables of age, resting blood pressure, and cholesterol amount,
we decided to use these as our predictor variables. Thus for our data,
we performed the necessary steps to perform classification. First we
split our data into training and testing data sets. Then we performed
10-fold cross validation to tune our data to evaluate our metrics to see
which nearest neighbor we should use for classification of the
diagnosis. Since, this is a medical diagnosis, we focused on the
sensitivity metric for determining a nearest neighbor for future
predictions/diagnoses. This is because the purpose of our test is to
correctly identify those with the disease and with sensitivity, the
people who have heart disease will be highly likely to be identified and
diagnosed correctly. Also, with sensitivity, it is the more “safer than
sorry” route for diagnoses. This is because more false positives will
occur while less false negative results occur. So, as a predictor of a
serious medical condition, we would rather our application have a false
positive and diagnose the user with heart disease which can evaluated in
the future and determined to not be true instead of there being users
who have the disease but aren’t diagnosed with it (false negatives).
With our focused metric being sensitivity, we plotted the metric’s value
against 1 nearest neighbor to 20 nearest neighbors evaluated for both
the female and male data sets. Upon graphing, it ws evident that 13
nearest neighbors for males and 19 nearest neighbors for females allowed
for the most accurate predictions of heart disease. Thus for when a user
specifies their sex as female and enters their age, resting blood
pressure, and cholesterol amount, we will classify whether their values
indicate that they have heart disease by evaluating whether the majority
of the nearest neighbors were classified as having heart disease or not
having heart disease (the majority-represented class/diagnosis
indicating what the user’s diagnosis is). For males, we do the same only
with 19 nearest neighbors. To visualize the classified values against
their three variables of age, resting blood pressure, and cholesterol
amount, we create a 3D scatterplot (since we are using 3 variables) and
color the points by class (having heart disease or not having heart
disease).
