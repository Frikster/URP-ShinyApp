rm(list=ls())
library(shiny)
library(party)

# Define the overall UI
shinyUI(fluidPage(
  titlePanel("Unbiased Recursive Partitioning"),
  fileInput("file", label = h3("File input")),    
  fluidRow(    
    column(2, wellPanel(
      selectInput("an", 
                  "Anchor:", 
                  c("data not loaded")),
      textInput("control_preds",
                "Type to check all predictors that contain a string. Erase to select all",
                "Note: Alphanumerics only"),
      textInput("title_urp",
                "Insert Title"),
      # Create a new Row in the UI for selectInputs
      actionButton("go", "Plot URP-Ctree"),
      checkboxGroupInput('preds', 'Choose Predictors',
                         c("data not loaded"), selected = c("data not loaded"))
    )),
    
    column(2, wellPanel(
      textInput("control_tableviewPreds",
                "Type to check all predictors that contain a string. Erase to select all",
                "Note: Alphanumerics only"),
      actionButton("tableButton", "Tabulate"),
      checkboxGroupInput('tableviewPreds', 'Choose Predictors to display',
                         c("data not loaded"), selected = NA)
    )),
    
    column(8, wellPanel(
      # Create a new row for the URP plot.
      plotOutput("plot", width = "100%"),
      # 31 linebreaks
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      br(),
      # Create a new row for the table for the nodes.
      dataTableOutput(outputId="table"),
      h4("AIS distribution for each cohort at 6 months"),
      tableOutput("AISTable"),
      # Create a starting point for the radioButtons. More radioButtons should be added after pressing the actionButton because then the ctree will be created and terminal nodes will be defined
      radioButtons("nodesRadio", label = h3("Choose Node to Display"),
                   choices = c(1,2), selected = 1, inline = TRUE),
      plotOutput("nodePlot",height = 1000, width = 1000),
      plotOutput("recovCurve_plot",height = 1000, width = 1000),
      textInput("bl",
                "Insert Baseline. e.g. 2Weeks, 1Month, 3Months..."),
      h4("Power Calculations"),
      plotOutput("powerCalcPts",height = 1000, width = 1000),
      tableOutput("powerCalcTable")
      
    
      
      ##        NOT WORKING YET     
      #         radioButtons('format', 'Document format', c('PDF', 'HTML', 'Word'),
      #                      inline = TRUE),
      #         downloadButton('downloadReport'),
      
      
      #         radioButtons("nodesRadio", label = h3("Choose Node to Display"),
      #                      choices = 1, 
      #                      selected = 1,
      #                      inline = TRUE),
      #         
      #         plotOutput("nodePlot", width = "100%")
      
    ))
  )
)  
)