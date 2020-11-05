### Behaviral Pattern Analysis Pipeline ###
# unsupervised trial-by-trial characterization
# to classify behavioral patterns

# (1) dimensionality reduction using parallel factor analysis 
# (2) clustering Gaussian mixture model
# see: https://rdrr.io/cran/multiway/man/parafac.html for PARAFAC

library(tidyverse)
library(multiway) 
library(mclust)
library(dirichletprocess)
library(rlist)

TM = theme(axis.text.x = element_text(family = "Times New Roman",size = rel(4), colour = "black"),
           axis.text.y = element_text(family = "Times New Roman",size = rel(4), colour = "black"),
           axis.title.x = element_text(family = "Times New Roman",size = rel(2), colour = "black", vjust = .1),
           axis.title.y = element_text(family = "Times New Roman",size = rel(2), colour = "black"),
           title = element_text(family = "Times New Roman",size = rel(1), colour = "black"),
           # legend.position = "none", # maybe used later?
           # panel.grid = element_blank(),
           # panel.background = element_rect(fill="white"),
           panel.border = element_rect(colour = "black", fill=NA, size=1.5),
           axis.ticks = element_line(colour = "black", size=1.3))

###--------------------------------------------------------------------------------###
### workflow (0) : generation of  demo data
set.seed(12345)
trialFrames = 360
fps = 1/60
trialNum = 100
trialType = 5
noiseLevel = .5
numFeatures = 2


# for simplicity features are defined by sine curves
# define the frequency of sine  curves
# but in true analysis, these may be trajectories of tracking, 
# or other time-series observations!

define_trial_feature = function(numFeatures, trialType){
  res = runif(trialType * numFeatures, 0.01, 10)
  res = matrix(res, trialType, numFeatures )
  return(res)
}


# get a trial trajectory
get_trial = function(trialFrames, fps, numFeatures, trialType, features){
  type = sample(1:trialType, 1)
  
  res = matrix(NA, trialFrames, numFeatures)
  
  
  for(i in 1:numFeatures){
    res[,i] = sin( features[type, i] * 1:trialFrames * fps) + rnorm(trialFrames, 0, noiseLevel)
  }
  
  
  res = as.data.frame(res)
  colnames(res) = paste0( "feature", 1:numFeatures )
  res$true_class = type
  return(res)
}



### get all results ###
features = define_trial_feature(numFeatures, trialType)

res = list()
for(i in 1:trialNum){
  trial =  get_trial(trialFrames, fps, numFeatures, trialType, features)
  trial$trial = i
  trial$time = 1:nrow(trial) * fps - fps
  res = list.append(res, trial)
}
res = do.call(rbind,res)


### visualize some trials ###
pick = sample(1:trialNum, 9)

ggplot(res[res$trial %in% pick,]) + 
  geom_line(aes(x=time, y=feature1), colour = "red") + 
  geom_line(aes(x=time, y=feature2), colour = "blue") +
  facet_wrap(~trial)

table(res$true_class)

###--------------------------------------------------------------------------------###
# (1) dimensionality reduction using parallel factor analysis 

# (1-1) data transfomation : data.frame -> 3d array
# array should be trialFrames * numFeatures * trialNum

# apply PAFAC
arr =  array(NA, dim=c(trialFrames, numFeatures, trialNum))

for(i in 1:trialNum){
  print(i)
  temp = res[res$trial == i,]
  arr[,,i] = as.matrix(temp[,1:numFeatures])
}

# check sum trials
arr[,1,1] == res[res$trial==1,]$feature1
arr[,2,1] == res[res$trial==1,]$feature2

arr[,1,50] == res[res$trial==50,]$feature1
arr[,2,50] == res[res$trial==50,]$feature2


### fit Parafac model
pfac = parafac(arr, nfac = 2, nstart = 1)

pfac$Rsq
pfac$A %>% dim
pfac$B %>% dim
pfac$C %>% dim
components = scale(pfac$C)[,1:2]
# components = scale(pfac$C)[,1:3]

d.comp = as.data.frame(components)
colnames(d.comp) = paste0("comp", 1:numFeatures)

d.comp$true_class = 
  split(res,res$trial) %>% 
  lapply(., function(res) res$true_class[1]) %>% 
  unlist


ggplot(d.comp) + 
  geom_point(aes(x=comp1, y=comp2, colour = as.factor(true_class)), size = .8, alpha=1) +  
  xlab("Component 1") + xlab("Component 2") + TM 



###--------------------------------------------------------------------------------###
# (2) clustering Gaussian mixture model
res.gmm = Mclust(d.comp, G=5)


d.comp$class = res.gmm$classification

ggplot(d.comp) + 
  geom_point(aes(x=comp1, y=comp2, colour = as.factor(class)), size = .8, alpha=1) +  
  xlab("Component 1") + xlab("Component 2") + TM 

# perfectly classified into true classes
table(d.comp$class, d.comp$true_class)



# comaprison BIC
BICs = NULL
for(i in 1:10){
  BICs = c(BICs, Mclust(d.comp, G=i)$bic)
}

# note : Higher is better in BIC from MClust
plot(BICs, type = "b")


# alternative solution :  using Dirichlet process Gaussian mixture model
dp = DirichletProcessMvnormal(as.matrix(d.comp[,1:numFeatures]))
fit = Fit(dp, 2000, progressBar = TRUE)
d.comp$class_dpgmm = fit$clusterLabels

ggplot(d.comp) + 
  geom_point(aes(x=comp1, y=comp2, colour = as.factor(class_dpgmm)), size = .8, alpha=1) +  TM

table(d.comp$class_dpgmm, d.comp$true_class)



###--------------------------------------------------------------------------------###
# (3) Visualizing each behaviral classes

res$class = NA
res$frame = NA
for(i in 1:trialNum){

  res[res$trial == i,]$class = rep(d.comp[i,]$class, trialFrames)
  res[res$trial == i,]$frame = 1:trialFrames
  
}



# make averaged data.frame of each behaviral pattern
d.class = split(res, res$class) %>% lapply(., function(res){
  
  df = data.frame(
    feature1 = tapply(res$feature1, res$frame, mean),
    feature2 = tapply(res$feature2, res$frame, mean),
    sd1 = tapply(res$feature1, res$frame, sd),
    sd2 = tapply(res$feature2, res$frame, sd),
    frame = 1:trialFrames,
    time = 1:trialFrames * fps - fps,
    class = res$class[1]
  )
  
  return(df)
}) %>% do.call(rbind,.)

# visualization
ggplot(d.class) + 
  geom_line(aes(x=time, y=feature1), colour = "red", lwd=2) + 
  geom_line(aes(x=time, y=feature2), colour = "blue", lwd=2) + 
  ylab("features") +
  xlab("time") + 
  facet_wrap(~class) + TM + theme()



