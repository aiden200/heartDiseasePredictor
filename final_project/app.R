#App created by Aiden Chang and Chris Elliot

#loading libraries
library(shiny)
library(tidymodels)
library(tidyverse)
library(rgl)
library(shinydashboard)
library(kknn)


#loading the data
heart_original <- read_csv("./data/heart.csv")

#selecting the columns we are looking at
heart <- heart_original %>%
    select(Age, Sex, RestingBP, Cholesterol, HeartDisease) %>%
    mutate(
        HeartDisease = case_when(
            HeartDisease == 0 ~"Negative",
            HeartDisease == 1 ~"Positive"
        ),
        HeartDisease = as_factor(HeartDisease)
        )
#splitting the dataset into male and female
m_heart <- heart %>%
    filter(Sex == "M") %>%
    select(Age, RestingBP, Cholesterol, HeartDisease)
f_heart <- heart %>%
    filter(Sex == "F") %>%
    select(Age, RestingBP, Cholesterol, HeartDisease)

#Training data
set.seed(639)
m_split <- initial_split(m_heart, prop = 0.8, strata = HeartDisease)
m_train <- training(m_split)
m_test  <- testing(m_split)
f_split <- initial_split(f_heart, prop = 0.8, strata = HeartDisease)
f_train <- training(f_split)
f_test  <- testing(f_split)

#Standardizing training data
m_recipe <- recipe(HeartDisease ~ ., data = m_train) %>%
    step_scale(all_predictors()) %>%
    step_center(all_predictors()) %>%
    prep()

m_train <- bake(m_recipe, m_train)

f_recipe <- recipe(HeartDisease ~ ., data = f_train) %>%
    step_scale(all_predictors()) %>%
    step_center(all_predictors()) %>%
    prep()

f_train <- bake(f_recipe, f_train)

#Standardizing test data
m_test <- bake(m_recipe, new_data = m_test)
f_test <- bake(f_recipe, new_data = f_test)

#Making a model specification that can be tuned later
tune_spec <- nearest_neighbor(
    weight_func = "rectangular",
    neighbors = tune()
) %>%
    set_engine("kknn") %>%
    set_mode("classification")

#creating 5 folds. 20% data for train
set.seed(6050)
m_vfold <- vfold_cv(m_train, v = 5, strata = HeartDisease)
set.seed(7050)
f_vfold <- vfold_cv(f_train, v = 5, strata = HeartDisease)

#k nearest neigbor sizes 1 to 20
k_vals <- tibble(neighbors = seq(1, 20, by = 2))

#creating workflow 
f_knn_fit <- workflow() %>%
    add_recipe(f_recipe) %>%
    add_model(tune_spec) %>%
    tune_grid(
        resamples = f_vfold, 
        grid = k_vals,
        metrics = metric_set(sensitivity)
    )
m_knn_fit <- workflow() %>%
    add_recipe(m_recipe) %>%
    add_model(tune_spec) %>%
    tune_grid(
        resamples = m_vfold, 
        grid = k_vals,
        metrics = metric_set(sensitivity)
    )



#cross validation metrics
m_cv_metrics <- collect_metrics(m_knn_fit) %>%
    arrange(desc(mean))
f_cv_metrics <- collect_metrics(f_knn_fit) %>%
    arrange(desc(mean))

#Since we care about Sensitivity, for male k = 13 with mean of .554, female k = 19 with mean of .983
#We can represent this as a graph
m_cv_metrics %>%
    ggplot(aes(x = neighbors, y = mean, color = .metric)) +
    geom_point() +
    geom_line() +
    labs(y = "Rate") +
    ggthemes::scale_color_colorblind()
f_cv_metrics %>%
    ggplot(aes(x = neighbors, y = mean, color = .metric)) +
    geom_point() +
    geom_line() +
    labs(y = "Rate") +
    ggthemes::scale_color_colorblind()

#spec tuned with the knn
m_knn_spec_tuned <- nearest_neighbor(
    weight_func = "rectangular",
    neighbors = 19
) %>%
    set_engine("kknn") %>%
    set_mode("classification")

f_knn_spec_tuned <- nearest_neighbor(
    weight_func = "rectangular",
    neighbors = 13
) %>%
    set_engine("kknn") %>%
    set_mode("classification")

m_fit <- m_knn_spec_tuned %>%
    fit(HeartDisease ~ ., data = m_test)
f_fit <- f_knn_spec_tuned %>%
    fit(HeartDisease ~ ., data = f_test)

m_test_preds <- predict(m_fit, new_data = m_test)
f_test_preds <- predict(f_fit, new_data = f_test)

testing <- predict(m_fit, new_data = bake(m_recipe, new_data = tibble(Age = 23, RestingBP = 100, Cholesterol = 200)))

bind_cols(m_test, m_test_preds) %>%
    conf_mat(HeartDisease, .pred_class)
bind_cols(f_test, f_test_preds) %>%
    conf_mat(HeartDisease, .pred_class)


negative_number<-heart %>% 
    filter(HeartDisease == "Negative") 
negative_number <- nrow(negative_number)
positive_number<-heart %>% 
    filter(HeartDisease == "Positive")
positive_number <- nrow(positive_number)




# Define UI for application that draws a histogram
ui <- dashboardPage(skin = 'red', 

    # Application title
    dashboardHeader(title = "Predicting Heart Failure"),
    dashboardSidebar(
        sidebarMenu(
            menuItem('Dashboard',
                     tabName = 'Dashboard',
                     icon = icon('dashboard'), badgeColor = 'red'),
            menuItem('Data',tabName = 'Data', icon = icon('database'), badgeColor = 'red'),
            menuItem('About the Data',tabName = 'dataInfo', icon = icon('database'), badgeColor = 'red')
        )
    ),
    dashboardBody(
        tabItems(
            tabItem(tabName = 'Dashboard',
                    h2('Dashboard tab content'),
                    fluidRow(
                        box(title = 'Enter Your Data', background = 'black',
                            "Predictor",
                            h5("Upon entering your Sex, Age, Resting Blood Pressure ",
                               "Rate, and Cholesterol Level, click the submit button ",
                               "for a prediction of you having Cardiovascular diseases."),
                            selectInput("sex", label = "Sex", choices = c("M", "F")),
                            numericInput("age", label = "Age", value = 0),
                            numericInput("restingBP", label = "Resting Blood Pressure", value = 0),
                            numericInput("cholesterol", label = "Cholesterol", value = 0),
                            actionButton("update", label = "Submit"),
                            helpText("When you click the button above, you should see",
                                     "the output below update to reflect the value you",
                                     "entered at the top. Negative means no signs of",
                                     "heart disease. Positive means potential heart",
                                     "disease:"),
                            verbatimTextOutput("value"),
                            helpText("The graph on the right represents where you lie compared",
                                     "in relation to the rest of the data. The big yellow sphere",
                                     "represents you, while the blue circles represent no heart",
                                     "disease points and the green represent the heart disease",
                                     "points")
                        ),
                        box(
                            title = 'Heart Disease Plot', background = 'red', solidHeader = TRUE,
                            rglwidgetOutput("graph",  width = 600, height = 600)
                        ),
                        # Value Box showing # of positives from data set
                        valueBox(value = positive_number, 
                                 'Number of Positives for Heart Disease', 
                                 icon = icon('plus-circle'),
                                 color = 'green'),
                        
                        valueBox(value = negative_number,
                                 'Number of Negatives for Heart Disease',
                                 icon = icon('minus-circle'),
                                 color = 'red')
                    )),
            tabItem(tabName = 'Data',
                    h2('Search the database'),
                    dataTableOutput('mytable')),
            tabItem(tabName = 'dataInfo',
                    HTML(
                        paste(
                            '<a href=', "https://www.kaggle.com/fedesoriano/heart-failure-prediction", '>',h2("Source"),'</a>',  '<br/>',
                            h4("This dataset is an open source dataset from Kaggle", " containing information about Cardiovascular diseases (CVDs)."), '<br/>',
                            h4("From our source, it was stated that This dataset was created by combining different datasets",
                               "already available independently but not combined before. In this dataset, 5 heart datasets",
                               "are combined over 11 common features which makes it the largest heart disease dataset",
                               "available so far for research purposes. The five datasets used for its curation are:"), '<br/>',
                            h4("Cleveland: 303 observations"), '<br/>',
                            h4("Hungarian: 294 observations"), '<br/>',
                            h4("Switzerland: 123 observations"), '<br/>',
                            h4("Long Beach VA: 200 observations"), '<br/>',
                            h4("Stalog (Heart) Data Set: 270 observations"), '<br/>',
                            h4("Total: 1190 observations, Duplicated: 272 observations, Final dataset: 918 observations"), '<br/>',
                            h4("additional data can be found under this link: "), '<a href=',"https://archive.ics.uci.edu/ml/machine-learning-databases/heart-disease/", '>',h3("Click here!"),'</a>',
                            h2("Attribute Information"), '<br/>',
                            h4("Age: age of the patient [years]"), '<br/>',
                            h4("Sex: sex of the patient [M: Male, F: Female]"), '<br/>',
                            h4("ChestPainType: chest pain type [TA: Typical Angina, ATA: Atypical Angina, NAP: Non-Anginal Pain, ASY: Asymptomatic"), '<br/>',
                            h4("RestingBP: resting blood pressure [mm Hg]"), '<br/>',
                            h4("Cholesterol: serum cholesterol [mm/dl]"), '<br/>',
                            h4("FastingBS: fasting blood sugar [1: if FastingBS > 120 mg/dl, 0: otherwise]"), '<br/>',
                            h4("RestingECG: resting electrocardiogram results [Normal: Normal, ST: having ST-T wave abnormality (T wave inversions and/or ST elevation or depression of > 0.05 mV), LVH: showing probable or definite left ventricular hypertrophy by Estes' criteria]"), '<br/>',
                            h4("MaxHR: maximum heart rate achieved [Numeric value between 60 and 202]"), '<br/>',
                            h4("ExerciseAngina: exercise-induced angina [Y: Yes, N: No]"), '<br/>',
                            h4("Oldpeak: oldpeak = ST [Numeric value measured in depression]"), '<br/>',
                            h4("ST_Slope: the slope of the peak exercise ST segment [Up: upsloping, Flat: flat, Down: downsloping]"), '<br/>',
                            h4("HeartDisease: output class [1: heart disease, 0: Normal]"), '<br/>'
                            
                        )
                    )
                    )
        )
        
    ))

    


# Define server logic required to draw a histogram
server <- function(input, output) {

    predict_new <- eventReactive(input$update,{
        tibble(Age = strtoi(input$age), RestingBP = strtoi(input$restingBP), Cholesterol = strtoi(input$cholesterol), Sex = input$sex)
    })
    
    output$value <- renderPrint({
        tempData <- predict_new()
        
        if(tempData$Sex == "M"){
            print(as.character(predict(m_fit, new_data = bake(m_recipe, new_data = tempData%>%select(Age, RestingBP, Cholesterol)))[[1]]))
        } else{
            print(as.character(predict(f_fit, new_data = bake(f_recipe, new_data = tempData%>%select(Age, RestingBP, Cholesterol)))[[1]]))
        }
    })
    
    output$graph <- renderRglwidget({
        tempData <- predict_new()
        if(tempData$Sex == "M"){
            dataSet <- m_heart
        } else{
            dataSet <- f_heart
        }
        # Plot
        tempData <- tempData%>%mutate(HeartDisease = "Unknown") %>%select(Age, RestingBP, Cholesterol, HeartDisease)
        # Add a new column with color
        rgl.open(useNULL=T)
        mycolors <- c('blue', 'green')
        dataSet$color <- mycolors[as.numeric(dataSet$HeartDisease)]
        plot3d(
            x=dataSet$Age, y=dataSet$Cholesterol, z=dataSet$RestingBP, 
            col = dataSet$color,
            xlab="Age", ylab="Cholesterol", zlab="RestingBP", axes = TRUE) 
        rgl.spheres(x = tempData$Age, y = tempData$Cholesterol, z = tempData$RestingBP, r = 20, color = "yellow")
        bg3d("white")
        rglwidget()
        
        
        
    })
    output$mytable <- renderDataTable({
        heart_original
    })
}





# Run the application 
shinyApp(ui = ui, server = server)
