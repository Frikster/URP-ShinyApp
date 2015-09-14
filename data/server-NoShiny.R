rm(list = ls())
inFile<-'C:/Users/user/Documents/Dirk/Non-Murphy/ICORD/data/Dat formatted L+R removed most numeric CCS motorImprovement.csv'
inF<-read.csv(inFile)

an <- 'LEMS.6Months'
preds <- names(inF)
preds <- names(inF)[grepl('1Month',names(inF))]

datSubset<-subset(inF,inF[,an]!="NA")  
anchor <- datSubset[,an]
predictors <- datSubset[,preds]
urp<-ctree(anchor~., data=data.frame(anchor,predictors))
node<-where(urp)
datSubset<-cbind(anchor,node,datSubset)
colnames(datSubset)[1]<-an
plot(urp,main='Title')

# Get statistics for each node (i.e. median values)
medianList <- by(anchor,where(urp),median) #or whatever function you desire for median
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
  grid.edit(gridNode_Ref, label=paste("Median",medianList[[i]],"Cohort",nodeNum))
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