rm(list = ls())
# Immediately enter the browser/some function when an error occurs
# options(error = some funcion)

library(shiny)
library(DT)

shinyUI(fluidPage(
  titlePanel("Unbiased Recursive Partitioning"),
  sidebarLayout(
    sidebarPanel(
      conditionalPanel(
        'input.tab === "Subsetting"',  
        fileInput('file1', 'Choose CSV File',
                  accept=c('text/csv', 
                           'text/comma-separated-values,text/plain', 
                           '.csv')),
        checkboxInput('header', 'Header', TRUE),
        radioButtons('sep', 'Separator',
                     c(Comma=',',
                       Semicolon=';',
                       Tab='\t'),
                     ','),
        radioButtons('quote', 'Quote',
                     c(None='',
                       'Double Quote'='"',
                       'Single Quote'="'"),
                     '"'),
        selectizeInput('colDisplay', 'Choose Columns to display', choices = c("data not loaded"), multiple = TRUE),
        
        #       textInput("control_cols",
        #                 "Type to check display all columns that contain a string. Erase to select all. NOTE: Selecting many columns will slow down the time it takes for the table to be displayed. Be patient.",
        #                 "Note: Alphanumerics only"),
        actionButton("updateColsDisplay", "Update columns to display")
        #       checkboxGroupInput('colDisplay', 'Choose Columns to display',
        #                          c("data not loaded"), selected = c("data not loaded"))
      ),
      
      # SIDEBAR UI FROM JUNE 2015 MASTER
      conditionalPanel(
        'input.tab === "URP"', 
        selectInput("an", 
                    "Anchor:", 
                    c("data not loaded")),
        textInput("control_preds",
                  "Select predictors that contain the following in their name (Seperate with comma). Enter no text to select all. Alphanumerics only"),
        textInput("control_preds_remove",
                  "Deselect predictors that contain the following in their name (Seperate with comma). Alphanumerics only"),
        actionButton("updatePreds", "Update Predictors"),
        textInput("title_urp",
                  "Insert Title"),
        # Create a new Row in the UI for selectInputs
        actionButton("go", "Plot URP-Ctree"),
        checkboxGroupInput('preds', 'Choose Predictors',
                           c("data not loaded"), selected = c("data not loaded"))
        
      ),
      
      conditionalPanel(
        'input.tab === "URP-table"', 
        selectizeInput('tableviewPreds', 'Choose Predictors to display', choices = c("data not loaded"), multiple = TRUE)
        
        #       textInput("control_tableviewPreds",
        #                 "Type to check all predictors that contain a string. Erase to select all",
        #                 "Note: Alphanumerics only"),
        #actionButton("tableButton", "Tabulate")
        #       checkboxGroupInput('tableviewPreds', 'Choose Predictors to display',
        #                          c("data not loaded"), selected = NA)
      )
      
    ),    
    
    mainPanel(
      tabsetPanel(
        id = 'tab',
        tabPanel('Subsetting',       
                 hr(),
                 DT::dataTableOutput("subsettingTable"),
                 downloadButton('downloadSubset', 'Download Subset')
                 #tableOutput('contents')),
        ),   
        tabPanel('URP', 
                 sliderInput("sliderWidth", label = "Adjust width", min = 10, max = 5000, value = 1000),
                 sliderInput("sliderHeight", label = "Adjust height", min = 10, max = 5000, value = 1000),
                 plotOutput("plot", inline = TRUE,width='auto',height='auto')),
        tabPanel('URP-table',
                 DT::dataTableOutput(outputId="postUrpTable"),
                 downloadButton('downloadCtreeSubset', 'Download Ctree Subset'))
        
      )
      
      
      
    )
  )
))