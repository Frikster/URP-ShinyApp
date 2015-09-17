rm(list = ls())
# Uncomment below to ummediately enter the browser when an error occurs
# options(error = browser)
# To exit browser = Q

library(shiny)
library(leaflet)
library(DT)
library(party)
library(stringr)
options(shiny.maxRequestSize=30*1024^2) 

shinyServer(function(input, output, clientData, session) {
  ####################################
  # ------- Subsetting Tab ----------#
  ####################################
  inFile<-reactive({
    # Input csv
    input$file1
    if(is.null(input$file1)){
      return(NULL)
    }
    else{
      inF<-read.csv(input$file1$datapath, header=input$header, sep=input$sep, quote=input$quote) 
      inF
    }
  })
  
  observe({ 
    # Set the label, choices, and selected item based on written input
    if(is.null(inFile)){
      #Do jack diddly-squat
    }
    else{
      updateSelectizeInput(session, "colDisplay",
                           'Choose Columns to display',
                           choices = names(inFile()))  
    }
  })
  
  subsetTable<-reactive({
    input$updateColsDisplay
    isolate({
      if(is.null(input$colDisplay)){
        # inFile()[,c(colnames(inFile())[1],colnames(inFile())[2])]
      }
      else{ 
        if(input$updateColsDisplay>0)
        {
          #  inFile()[,c(colnames(inFile())[1],input$colDisplay)]
          outSubTable<-inFile()[,input$colDisplay,drop=FALSE]
          outSubTable
        }
      }
    })
  })
  
  output$subsettingTable <- DT::renderDataTable(
    subsetTable(), filter = 'top', server = FALSE, 
    options = list(pageLength = 5, autoWidth = TRUE))
  
  # download the filtered data
  output$downloadSubset = downloadHandler('filtered.csv', content = function(file) {
    write.csv(subsetToURP(), file)
  })
  
  #############################
  # ------- URP Tab ----------#
  #############################
  observe({ 
    updateSelectInput(session,"an", "Anchor:", c(unique(as.character(names(inFile())))))
  })  
  
  # Observe to update all wigets in one go on the URP tab as soon as csv is loaded
  observe({
    # Set the label, choices, and selected item based on written input
    #toBeChecked<-names(dataset())[grepl(paste(input$control_preds),names(dataset()))]
    if(input$updatePreds==0&&!is.null(inFile)){
      updateCheckboxGroupInput(session, "preds",
                               'Choose Predictors',
                               choices = names(inFile()))  
    }
    if(input$updatePreds>0){
      isolate({
        # Set the label, choices, and selected item based on written input
        # Cannot select anchor via textBox. Must be done manually
        if(input$control_preds_remove==""){
          strSplitSelections <- strsplit(input$control_preds,",")[[1]]
          strSplitSelections_removeSpaces <- str_replace_all(strSplitSelections, fixed(" "), "")
          toBeChecked<-names(inFile())[grepl(paste(strSplitSelections_removeSpaces,collapse="|"),names(inFile()),ignore.case=TRUE)]
          
          
        }
        else{
          strSplitSelections <- strsplit(input$control_preds,",")[[1]]
          strSplitSelections_removeSpaces <- str_replace_all(strSplitSelections, fixed(" "), "")
          toBeChecked<-names(inFile())[grepl(paste(strSplitSelections_removeSpaces,collapse="|"),names(inFile()),ignore.case=TRUE)]
          
          strSplitSelections <- strsplit(input$control_preds_remove,",")[[1]]
          strSplitSelections_removeSpaces <- str_replace_all(strSplitSelections, fixed(" "), "")
          toBeUnchecked<-names(inFile())[grepl(paste(strSplitSelections_removeSpaces,collapse="|"),names(inFile()),ignore.case=TRUE)]
          
          toBeChecked<-toBeChecked[!(toBeChecked %in% toBeUnchecked)]
        }
        # Remove toBeUnchecked predictors
        updateCheckboxGroupInput(session, "preds",
                                 'Choose Predictors',
                                 choices = names(inFile()),
                                 selected = toBeChecked[toBeChecked!=input$an])  
      })
    }
  })
  
  # Slider reactive and observe expressions
  sliderWidth<-reactive({
    as.integer(input$sliderWidth)
  })
  
  sliderHeight<-reactive({
    as.integer(input$sliderHeight)
  })
  
  observe({
    w<<-sliderWidth()
    h<<-sliderHeight()
  })
  
  # Set the subset for URP based on the subsetting tab
  subsetToURP<-reactive({
    if(is.null(input$subsettingTable_rows_all)){
      inFile()
    }
    else{
      inFile()[input$subsettingTable_rows_all,]
    }
  })
  
  # Construct URP-Ctree
  output$plot <- renderPlot({
    dummy<-sliderHeight()
    dummy<-sliderWidth()
    #browser()
    if(input$go==0){
      return()
    }
    else {
      isolate({
        datSubset<<-subset(subsetToURP(),subsetToURP()[,input$an]!="NA") 
        anchor <- datSubset[,input$an]
        predictors <- datSubset[,input$preds]
        urp<<-ctree(anchor~., data=data.frame(anchor,predictors))
        node<-where(urp)
        datSubset<<-cbind(anchor,node,datSubset)
        colnames(datSubset)[1]<<-input$an
        plot(urp,main=input$title_urp)
        
        # Get statistics for each node (i.e. median values)
        # Don't try to get the median if we're dealing with a non-numeric anchor outcome
        if(is.numeric(anchor)){
          medianList <- by(anchor,where(urp),median) # or whatever function you desire for median
        }
        treeGridList<-numeric(dim(datSubset)[1]) 
        # Create a list of all grid elements from the tree
        for(gg in grid.ls(print=F)[[1]]) {
          if (grepl("text", gg)) {
            treeGridList[gg]<-(paste(gg, grid.get(gg)$label,sep=": "))
          }
        }
        treeGridList<-subset(treeGridList,treeGridList!=0)
        
        
        # Change the label "node" to "cohort" and specifiy median for each
        treeGridList_Nodes<-subset(treeGridList,grepl("Node",treeGridList))
        for(i in 1:length(treeGridList_Nodes)){
          gridNode_Ref<-sub("(.*?):.*", "\\1", treeGridList_Nodes)[i]
          nodeNum<-sub(".*:", "", treeGridList_Nodes)[i]
          nodeNum<-substring(nodeNum[[1]],7)
          if(is.numeric(anchor)){
            grid.edit(gridNode_Ref, label=paste("Median",medianList[[i]],"Cohort",nodeNum))
          }
          else{
            grid.edit(gridNode_Ref, label=paste("Cohort",nodeNum))
          }
          #grid.edit(gridNode_Ref, gp=gpar(fontsize=15))
        }
        # increase size of title
        gridTitle_Ref<-sub("(.*?):.*", "\\1", treeGridList)[1]
        grid.edit(gridTitle_Ref, gp=gpar(fontsize=20))
        
        # Incrase the size of the yaxis label
        treeGridList_yaxis<-numeric(dim(datSubset)[1])
        for(gg in grid.ls(print=F)[[1]]) {
          if (grepl("yaxis", gg)) {
            treeGridList_yaxis[gg]<-(paste(gg, grid.get(gg)$label,sep=": "))
          }
        }
        treeGridList_yaxis<-subset(treeGridList_yaxis,treeGridList_yaxis!=0)
        for(i in 1:length(treeGridList_yaxis)){
          gridAxis_Ref<-sub("(.*?):.*", "\\1", treeGridList_yaxis)[i]
          grid.edit(gridAxis_Ref, gp=gpar(fontsize=18))
        }
      })
    }
  },height = reactive({sliderHeight()}), width = reactive({sliderWidth()}))
  
  output$nodePlot <- renderPlot({ 
    input$nodesRadio
    if(exists("datSubset")&&!is.null(datSubset$node)){   
      if(!is.numeric(datSubset[datSubset$node==input$nodesRadio,][,colnames(datSubset)[1]]))
      {
        barplot(table(datSubset[datSubset$node==input$nodesRadio,][,colnames(datSubset)[1]]),cex.main=1.4,cex.axis=1.6)
      }
      else{
        n<-length(datSubset[datSubset$node==input$nodesRadio,][,colnames(datSubset)[1]])
        median<-boxplot(datSubset[datSubset$node==input$nodesRadio,][,colnames(datSubset)[1]])$stats[3,1]
        boxplot(datSubset[datSubset$node==input$nodesRadio,][,colnames(datSubset)[1]],main=paste("median = ",median," n = ",n),cex.main=1.4,cex.axis=1.6)
      }
    }
  })
  
  ###################################
  # ------- URP-table Tab ----------#
  ###################################  
  
  observe({ 
    # Set the label, choices, and selected item based on written input
    if(is.null(inFile)||input$go==0){
      #Do jack diddly-squat
    }
    else{
      updateSelectizeInput(session, "tableviewPreds",
                           'Choose Predictors',
                           choices = names(inFile())) 
    }
  })
  
  subsetCtreeTable<-reactive({
    input$tab
    if(is.null(input$tableviewPreds)||input$tableviewPreds=="data not loaded"){
      datSubset[,c(colnames(datSubset)[1],"node")]
    }
    else{ 
      datSubset[,c(colnames(datSubset)[1],"node",input$tableviewPreds)]
    }
  })
  
  # Filter data based on selections
  output$postUrpTable <- DT::renderDataTable(
    subsetCtreeTable(), filter = 'top', server = FALSE,
    options = list(pageLength = 5, autoWidth = TRUE))
  
  
  # download the filtered data
  output$downloadCtreeSubset = downloadHandler('ctree-filtered.csv', content = function(file) {
    s = input$postUrpTable_rows_all
    write.csv(datSubset[s, , drop = FALSE], file)
  })
  
  
  # toBeChecked<-names(inFile())[grepl(paste(strsplit(input$control_preds,",")[[1]],collapse="|"),names(inFile()))]
  
  
  
  ############### EVERYTHING BELOW HAS NOT GOT A PART IN UI YET ######################
  
  
#   output$AISTable<-renderTable({
#     if(input$tableButton<=0){
#       return()
#     }
#     else{
#       table(datSubset[c("AIS.6Months","node")])
#     }
#   })
#   
#   # Creates recovery curves, showing how anchor outcome distributions change from 2 weeks to 12 months for cohort input$nodesRadio
#   output$recovCurve_plot<-renderPlot({
#     input$nodesRadio
#     if(exists("datSubset")&&!is.null(datSubset$node)){
#       allTimes<-list()
#       for(i in c("2Weeks","1Month","3Months","6Months","12Months"))
#       {
#         if(i=="2Weeks"){i_str<-"2 weeks"}
#         if(i=="1Month"){i_str<-"1 month"}
#         if(i=="3Months"){i_str<-"3 months"}
#         if(i=="6Months"){i_str<-"6 months"}
#         if(i=="12Months"){i_str<-"12 months"}
#         #input$nodesRadio<-1
#         anchorType<-strsplit(names(datSubset)[1],"\\.")[[1]][1]
#         distribution_str<-paste(anchorType,".",i,sep="")
#         allGroups<-list()
#         #correctFlags<-list()
#         #while(input$nodesRadio<=max(datSubset$node,na.rm=TRUE)){
#         group<-subset(datSubset,node==input$nodesRadio)
#         if(length(group$node)>0){
#           #correctFlags<-append(correctFlags,input$nodesRadio)
#           distribution<-subset(group,select=distribution_str)
#           allGroups<-append(allGroups,distribution)
#           names(allGroups)[length(allGroups)]<-paste("Cohort",input$nodesRadio,"at",i_str)
#         }
#         #  input$nodesRadio<-input$nodesRadio+1                                                   
#         #}
#         allTimes<-append(allTimes,allGroups)    
#       }
#       
#       quagmire<-sapply(allTimes,'[',seq(max(sapply(allTimes,length))))
#       quagmire<-apply(quagmire,2,as.numeric)
#       
#       #correctFlags<-as.numeric(correctFlags)
#       
#       #for(input$nodesRadio in correctFlags){
#       distributions<-subset(quagmire,select=grepl(paste("Cohort",input$nodesRadio),colnames(quagmire)))
#       
#       for(i in 1:5){
#         if(i==1){i_str<-"2 weeks"}
#         if(i==2){i_str<-"1 month"}
#         if(i==3){i_str<-"3 months"}
#         if(i==4){i_str<-"6 months"}
#         if(i==5){i_str<-"12 months"}
#         
#         currentTime<-distributions[,i]
#         n<-length(currentTime[!is.na(currentTime)])
#         
#         colnames(distributions)[i]<-paste(i_str,"n =",n)
#       }    
#       rangeFinder<-subset(datSubset,select=grepl(paste(anchorType,".",sep=""),colnames(datSubset),fixed=TRUE))
#       rangeFinder<-sapply(rangeFinder,as.numeric)
#       rangeFix<-max(cbind(rangeFinder,datSubset$anchor[,1]),na.rm=TRUE)  
#       boxplot(distributions,cex.main=1.4,ylim=c(0,rangeFix),cex.axis=1.6)
#     }
#   })
#   
#   
#   #REQUIRES CONTINUOUS DATA
#   #Output power plots for each cohort that show what sample size is needed for partcular powers where the 
#   #treatment effect is defined by user. i.e. pts is the by how many points each patient recovers
#   output$powerCalcPts<-renderPlot({
#     baseline<-input$bl
#     flag<-input$nodesRadio
#     
#     if(exists("datSubset")&&!is.null(datSubset$node)&&(baseline!="")&&exists("flag")&&exists("baseline")){
#       #powerCalcPts(flag,baseline,pts){
#       anchorType<-strsplit(names(datSubset)[1],"\\.")[[1]][1]
#       title_anchor<-names(datSubset[1])
#       #flag<-1
#       #while(flag<=max(datSubset$node,na.rm=TRUE)){
#       group<-subset(datSubset,node==flag)
#       
#       # If the current value of flag is a valid node
#       if(length(group$node)>0){
#         distribution2<-subset(group,select=title_anchor)
#         distribution1<-subset(group,select=paste(anchorType,".",baseline,sep=""))
#         
#         changeDistControl<-distribution2[[1]]-distribution1[[1]]
#         changeDistControl<-subset(changeDistControl,changeDistControl!="NA")
#         avgChangeControl<-mean(changeDistControl)
#         
#         #     upperHinge<-boxplot(distribution2[[1]])$stats[4,1]
#         #     lowerHinge<-boxplot(distribution2[[1]])$stats[4,1]
#         #     if(anchorType=="at10m"){
#         #       hinge<-lowerHinge
#         #     } else{
#         #       hinge<-upperHinge
#         #     }
#         
#         rangeFinder<-subset(datSubset,select=grepl(paste(anchorType,".",sep=""),colnames(datSubset),fixed=TRUE))
#         rangeFinder<-sapply(rangeFinder,as.numeric)
#         # FIX THIS LINE (datSubset$anchor undefined):
#         rangeFix<<-max(cbind(rangeFinder,datSubset$anchor[,1]),na.rm=TRUE)  
#         # boxplot(distributions,cex.main=1.4,ylim=c(0,rangeFix),cex.axis=1.6)
#         
#         # range of treatment effect
#         ptsRange <- c(2:rangeFix)
#         
#         sampleNeededY<-numeric(rangeFix)
#         populationSampleNeededY<-numeric(rangeFix)
#         effectSizeY<-numeric(rangeFix)
#         
#         
#         for(pts in ptsRange){
#           distribution_ptsInc<-distribution2[[1]]+pts
#           distribution_ptsInc[distribution_ptsInc>rangeFix]<-rangeFix
#           
#           changeDistExp<-distribution_ptsInc-distribution1[[1]]
#           changeDistExp<-subset(changeDistExp,changeDistExp!="NA")
#           avgChangeExp<-mean(changeDistExp)
#           
#           changeInChange<-avgChangeExp-avgChangeControl 
#           
#           varControl<-sd(changeDistControl)^2
#           varExp<-sd(changeDistExp)^2
#           nControl<-length(changeDistControl)
#           nExp<-length(changeDistExp)
#           x<-(nControl-1)*varControl
#           y<-(nExp-1)*varExp
#           stanDev<-sqrt((x+y)/(nControl+nExp-2)) #pooled standard deviation
#           
#           # Compute effect size (cohen's d)
#           d <- changeInChange/stanDev
#           
#           # compute 95% confidence interval
#           stError<-sqrt((varControl/nControl)+(varExp/nExp))
#           lower<-changeInChange-1.96*(stError)
#           upper<-changeInChange+1.96*(stError)
#           
#           tTestList<-numeric(12)
#           if(!is.na(changeInChange)&&!is.na(changeInChange)){
#             totalN<-(power.t.test(n=NULL, delta=(changeInChange), sd=stanDev, sig.level=0.05 ,power=0.8,type="two.sample",alternative="two.sided")$n)*2
#             fromPop<-ceiling(totalN)*(length(datSubset$node)/length(which(datSubset$node==flag)))
#             
#             #power.t.test(n=NULL, delta=(hinge-avgChangeControl), sd=stanDev, sig.level=0.05 ,power=0.80,type="paired",alternative="two.sided")
#             
#             tTestList[1]<-"Paired t test power calculation"
#             tTestList[2]<-paste("pairs =",power.t.test(n=NULL, delta=(changeInChange), sd=stanDev, sig.level=0.05 ,power=0.8,type="two.sample",alternative="two.sided")$n)
#             tTestList[3]<-paste("total n =",totalN)
#             tTestList[4]<-paste("delta =",power.t.test(n=NULL, delta=(changeInChange), sd=stanDev, sig.level=0.05 ,power=0.8,type="two.sample",alternative="two.sided")$delta)
#             tTestList[5]<-paste("sd =",power.t.test(n=NULL, delta=(changeInChange), sd=stanDev, sig.level=0.05 ,power=0.8,type="two.sample",alternative="two.sided")$sd)
#             tTestList[6]<-paste("sig. level =",power.t.test(n=NULL, delta=(changeInChange), sd=stanDev, sig.level=0.05 ,power=0.8,type="two.sample",alternative="two.sided")$sig.level)
#             tTestList[7]<-paste("power =",power.t.test(n=NULL, delta=(changeInChange), sd=stanDev, sig.level=0.05 ,power=0.8,type="two.sample",alternative="two.sided")$power)
#             tTestList[8]<-paste("alternative =",power.t.test(n=NULL, delta=(changeInChange), sd=stanDev, sig.level=0.05 ,power=0.8,type="two.sample",alternative="two.sided")$alternative)
#             tTestList[9]<-"NOTE: sd is std.dev. of *differences* within pairs"
#             tTestList[10]<-paste("effect size =",d)
#             tTestList[11]<-paste("Confidence Interval =","(",lower,",",upper,")")
#             tTestList[12]<-paste("Population sample needed for cohort",flag,"=",fromPop)
#           } else {
#             tTestList[1]<-"UNDEFINED"
#           }   
#           sampleNeededY[pts]<-totalN
#           populationSampleNeededY[pts]<-fromPop
#           effectSizeY[pts]<-d
#         }
#         
#         xrange<-c(1:rangeFix)
#         yrange<-c(1:max(500,rangeFix))
#         
#         #sampleNeededY
#         #populationSampleNeededY
#         #effectSizeY
#         
#         sampleNeededY_diff<-numeric(length(sampleNeededY)-1)
#         
#         for(i in 1:length(sampleNeededY_diff)){
#           sampleNeededY_diff[i]<-sampleNeededY[i]-sampleNeededY[i+1]
#         }
#         # Only include sample requirements where the difference between subsequent increases in the threshold leads to no more than one less person required
#         sampleNeededY_plot<<-sampleNeededY[sampleNeededY_diff>1]   
#         ptsRange_plot<<-ptsRange[sampleNeededY_diff>1]
#         
#         effectSizeY_plot<<- effectSizeY[sampleNeededY_diff>1]
#         populationSampleNeededY_plot<<-populationSampleNeededY[sampleNeededY_diff>1]
#         
#         plot(ptsRange_plot, sampleNeededY_plot, type="n",xlab="Therapeutic Improvement over Control",ylab="Sample Size Required")
#         lines(ptsRange_plot, sampleNeededY_plot, type="b")
#         #lines(ptsRange, populationSampleNeededY, type="b")
#         #lines(ptsRange, effectSizeY, type="b")
#         
#         sampleNeededY<<-sampleNeededY
#         populationSampleNeededY<<-populationSampleNeededY
#         effectSizeY<<-effectSizeY
#         
#         ptsRange_plot<<-ptsRange_plot
#         sampleNeededY_plot<<-sampleNeededY_plot
#         
#         effectSizeY_plot<<- effectSizeY_plot
#         populationSampleNeededY_plot<<-populationSampleNeededY_plot
#       }
#     }
#   })
#   
#   output$powerCalcTable <- renderTable({
#     baseline<-input$bl
#     flag<-input$nodesRadio
#     if(exists("ptsRange_plot")&&exists("sampleNeededY_plot")&&(length(ptsRange_plot)==length(sampleNeededY_plot)))
#     {
#       head(cbind(ptsRange_plot,sampleNeededY_plot,populationSampleNeededY_plot,effectSizeY_plot),n=length(ptsRange_plot))
#     }
#   })
  
  
  
  
  
  
})