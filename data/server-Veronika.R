# server.R
library(shiny)
library(party)

rm(list=ls())

inFile<-'C:/Users/User/Documents/CTree/attachment.csv'
dat<-read.csv(inFile)

shinyServer(function(input, output, clientData, session) {
  
  sliderWidth<-reactive({
    as.integer(input$sliderWidth)
  })
  
  sliderHeight<-reactive({
    as.integer(input$sliderHeight)
  })
  
  
  # Construct URP-Ctree
  output$plot <- renderPlot({ 
    if(input$go==0){
      return()
    }
    else {
      isolate({
        an<-"CCS"
        # Only columns with "2Weeks" as part of their title are selected as predictors
        control_preds<-"2Weeks"
        
        preds<-names(dat)[grepl(paste(control_preds),names(dat))]
        datSubset<-subset(dat,dat[,an]!="NA")  
        anchor <- datSubset[,an]
        predictors <- datSubset[,preds]
        urp<-ctree(anchor~., data=data.frame(anchor,predictors))
        plot(urp) 
      })
    }
  }, height = reactive({sliderHeight()}), width = reactive({sliderWidth()}))
}) 