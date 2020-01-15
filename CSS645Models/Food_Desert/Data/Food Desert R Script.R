###Food Desert ABM Experiments
###Harold Walbert
###hwalbert@gmu.edu


###Need to install the required package and then load and attach the package 
#install.packages("RNetLogo")
library('RNetLogo')
library('dplyr')


###
setwd('C:/Program Files (x86)/NetLogo 5.2.1')

#setwd('C:/Users/Harold/Documents/CSS/CSS600')
###This code starts the NetLogo GUI
nl.path <- getwd()
NLStart(nl.path)

###This loads a specific model saved on your computer
NLLoadModel('C:/Users/Harold/Documents/CSS/CSS Spatial ABM/Food Desert ABM/Food Desert ABM v11.nlogo')

ResetDefaultValues <- function(){
  NLCommand("set radius-size 6")
  NLCommand("set d* 1.1")
  NLCommand("set populationDenominator 300")
  NLCommand("set education-factor 0.5")
  NLCommand("set Calculate-Accessibility-Using-Socioeconomic-Data? TRUE")
}
NumberOfRepetitions <- 100

#Reset default values and set d* to Low value
ResetDefaultValues()
NLCommand("set d* 0.3")

LowdResultsEstimate <- data.frame()
LowdResultsStErr <- data.frame()
LowdPValue <- data.frame()
LowdRSqr <- data.frame()
LowdSumAcc <- data.frame()
LowdMeanAcc <- data.frame()
LowdAccIndex <- data.frame()
LowdPerSupermarket <- data.frame()
LowdPernotSupermarket <- data.frame()
LowdRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)

  LowdResultsEstimate <- as.data.frame(append(LowdResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  LowdResultsStErr <- as.data.frame(append(LowdResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  LowdPValue <-as.data.frame(append(LowdPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  LowdRSqr <- as.data.frame(append(LowdRSqr, summary(reg)$adj.r.squared))
  LowdSumAcc <- as.data.frame(append(LowdSumAcc, NLReport("sum ([accessibility] of people)")))
  LowdMeanAcc <- as.data.frame(append(LowdMeanAcc, NLReport("mean [accessibility] of people")))
  LowdAccIndex <- as.data.frame(append(LowdAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  LowdPerSupermarket <- as.data.frame(append(LowdPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  LowdPernotSupermarket <- as.data.frame(append(LowdPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  LowdRatio <- as.data.frame(append(LowdRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
LowdResultsEstimate <- t(LowdResultsEstimate)
LowdResultsStErr <- t(LowdResultsStErr)
LowdPValue <- t(LowdPValue)
LowdRSqr <- t(LowdRSqr)
LowdSumAcc <- t(LowdSumAcc)
LowdMeanAcc <- t(LowdMeanAcc)
LowdAccIndex <- t(LowdAccIndex)
LowdPerSupermarket <- t(LowdPerSupermarket)
LowdPernotSupermarket <- t(LowdPernotSupermarket)
LowdRatio <- t(LowdRatio)

LowdCombined <- data.frame(LowdResultsEstimate, LowdResultsStErr, LowdPValue, LowdRSqr, LowdSumAcc, LowdMeanAcc, LowdAccIndex, LowdPerSupermarket, LowdPernotSupermarket, LowdRatio)

#######################
#Reset default values and set d* to Medium value
ResetDefaultValues()
NLCommand("set d* 1.1")

MediumdResultsEstimate <- data.frame()
MediumdResultsStErr <- data.frame()
MediumdPValue <- data.frame()
MediumdRSqr <- data.frame()
MediumdSumAcc <- data.frame()
MediumdMeanAcc <- data.frame()
MediumdAccIndex <- data.frame()
MediumdPerSupermarket <- data.frame()
MediumdPernotSupermarket <- data.frame()
MediumdRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)
  
  MediumdResultsEstimate <- as.data.frame(append(MediumdResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  MediumdResultsStErr <- as.data.frame(append(MediumdResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  MediumdPValue <-as.data.frame(append(MediumdPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  MediumdRSqr <- as.data.frame(append(MediumdRSqr, summary(reg)$adj.r.squared))
  MediumdSumAcc <- as.data.frame(append(MediumdSumAcc, NLReport("sum ([accessibility] of people)")))
  MediumdMeanAcc <- as.data.frame(append(MediumdMeanAcc, NLReport("mean [accessibility] of people")))
  MediumdAccIndex <- as.data.frame(append(MediumdAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  MediumdPerSupermarket <- as.data.frame(append(MediumdPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  MediumdPernotSupermarket <- as.data.frame(append(MediumdPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  MediumdRatio <- as.data.frame(append(MediumdRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
MediumdResultsEstimate <- t(MediumdResultsEstimate)
MediumdResultsStErr <- t(MediumdResultsStErr)
MediumdPValue <- t(MediumdPValue)
MediumdRSqr <- t(MediumdRSqr)
MediumdSumAcc <- t(MediumdSumAcc)
MediumdMeanAcc <- t(MediumdMeanAcc)
MediumdAccIndex <- t(MediumdAccIndex)
MediumdPerSupermarket <- t(MediumdPerSupermarket)
MediumdPernotSupermarket <- t(MediumdPernotSupermarket)
MediumdRatio <- t(MediumdRatio)

MediumdCombined <- data.frame(MediumdResultsEstimate, MediumdResultsStErr, MediumdPValue, MediumdRSqr, MediumdSumAcc, MediumdMeanAcc, MediumdAccIndex, MediumdPerSupermarket, MediumdPernotSupermarket, MediumdRatio)

#############################
#Reset default values and set d* to High value
ResetDefaultValues()
NLCommand("set d* 2.0")

HighdResultsEstimate <- data.frame()
HighdResultsStErr <- data.frame()
HighdPValue <- data.frame()
HighdRSqr <- data.frame()
HighdSumAcc <- data.frame()
HighdMeanAcc <- data.frame()
HighdAccIndex <- data.frame()
HighdPerSupermarket <- data.frame()
HighdPernotSupermarket <- data.frame()
HighdRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)
  
  HighdResultsEstimate <- as.data.frame(append(HighdResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  HighdResultsStErr <- as.data.frame(append(HighdResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  HighdPValue <-as.data.frame(append(HighdPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  HighdRSqr <- as.data.frame(append(HighdRSqr, summary(reg)$adj.r.squared))
  HighdSumAcc <- as.data.frame(append(HighdSumAcc, NLReport("sum ([accessibility] of people)")))
  HighdMeanAcc <- as.data.frame(append(HighdMeanAcc, NLReport("mean [accessibility] of people")))
  HighdAccIndex <- as.data.frame(append(HighdAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  HighdPerSupermarket <- as.data.frame(append(HighdPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  HighdPernotSupermarket <- as.data.frame(append(HighdPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  HighdRatio <- as.data.frame(append(HighdRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
HighdResultsEstimate <- t(HighdResultsEstimate)
HighdResultsStErr <- t(HighdResultsStErr)
HighdPValue <- t(HighdPValue)
HighdRSqr <- t(HighdRSqr)
HighdSumAcc <- t(HighdSumAcc)
HighdMeanAcc <- t(HighdMeanAcc)
HighdAccIndex <- t(HighdAccIndex)
HighdPerSupermarket <- t(HighdPerSupermarket)
HighdPernotSupermarket <- t(HighdPernotSupermarket)
HighdRatio <- t(HighdRatio)

HighdCombined <- data.frame(HighdResultsEstimate, HighdResultsStErr, HighdPValue, HighdRSqr, HighdSumAcc, HighdMeanAcc, HighdAccIndex, HighdPerSupermarket, HighdPernotSupermarket, HighdRatio)


###This is good for saving each regression that is run and numbering them
#assign(paste("acc_reg", i, sep = ""), lm(peopleProperties$health ~ peopleProperties$accessibility))

################
#Now do same experiments without using socioeconomic data
################
#Reset default values and set d* to Low value
ResetDefaultValues()
NLCommand("set d* 0.3")
NLCommand("set Calculate-Accessibility-Using-Socioeconomic-Data? FALSE") 

Lowd_FResultsEstimate <- data.frame()
Lowd_FResultsStErr <- data.frame()
Lowd_FPValue <- data.frame()
Lowd_FRSqr <- data.frame()
Lowd_FSumAcc <- data.frame()
Lowd_FMeanAcc <- data.frame()
Lowd_FAccIndex <- data.frame()
Lowd_FPerSupermarket <- data.frame()
Lowd_FPernotSupermarket <- data.frame()
Lowd_FRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)
  
  Lowd_FResultsEstimate <- as.data.frame(append(Lowd_FResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  Lowd_FResultsStErr <- as.data.frame(append(Lowd_FResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  Lowd_FPValue <-as.data.frame(append(Lowd_FPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  Lowd_FRSqr <- as.data.frame(append(Lowd_FRSqr, summary(reg)$adj.r.squared))
  Lowd_FSumAcc <- as.data.frame(append(Lowd_FSumAcc, NLReport("sum ([accessibility] of people)")))
  Lowd_FMeanAcc <- as.data.frame(append(Lowd_FMeanAcc, NLReport("mean [accessibility] of people")))
  Lowd_FAccIndex <- as.data.frame(append(Lowd_FAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  Lowd_FPerSupermarket <- as.data.frame(append(Lowd_FPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  Lowd_FPernotSupermarket <- as.data.frame(append(Lowd_FPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  Lowd_FRatio <- as.data.frame(append(Lowd_FRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
Lowd_FResultsEstimate <- t(Lowd_FResultsEstimate)
Lowd_FResultsStErr <- t(Lowd_FResultsStErr)
Lowd_FPValue <- t(Lowd_FPValue)
Lowd_FRSqr <- t(Lowd_FRSqr)
Lowd_FSumAcc <- t(Lowd_FSumAcc)
Lowd_FMeanAcc <- t(Lowd_FMeanAcc)
Lowd_FAccIndex <- t(Lowd_FAccIndex)
Lowd_FPerSupermarket <- t(Lowd_FPerSupermarket)
Lowd_FPernotSupermarket <- t(Lowd_FPernotSupermarket)
Lowd_FRatio <- t(Lowd_FRatio)

Lowd_FCombined <- data.frame(Lowd_FResultsEstimate, Lowd_FResultsStErr, Lowd_FPValue, Lowd_FRSqr, Lowd_FSumAcc, Lowd_FMeanAcc, Lowd_FAccIndex, Lowd_FPerSupermarket, Lowd_FPernotSupermarket, Lowd_FRatio)

#######################
#Reset default values and set d* to Medium value
ResetDefaultValues()
NLCommand("set d* 1.1")
NLCommand("set Calculate-Accessibility-Using-Socioeconomic-Data? FALSE") 

Mediumd_FResultsEstimate <- data.frame()
Mediumd_FResultsStErr <- data.frame()
Mediumd_FPValue <- data.frame()
Mediumd_FRSqr <- data.frame()
Mediumd_FSumAcc <- data.frame()
Mediumd_FMeanAcc <- data.frame()
Mediumd_FAccIndex <- data.frame()
Mediumd_FPerSupermarket <- data.frame()
Mediumd_FPernotSupermarket <- data.frame()
Mediumd_FRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)
  
  Mediumd_FResultsEstimate <- as.data.frame(append(Mediumd_FResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  Mediumd_FResultsStErr <- as.data.frame(append(Mediumd_FResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  Mediumd_FPValue <-as.data.frame(append(Mediumd_FPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  Mediumd_FRSqr <- as.data.frame(append(Mediumd_FRSqr, summary(reg)$adj.r.squared))
  Mediumd_FSumAcc <- as.data.frame(append(Mediumd_FSumAcc, NLReport("sum ([accessibility] of people)")))
  Mediumd_FMeanAcc <- as.data.frame(append(Mediumd_FMeanAcc, NLReport("mean [accessibility] of people")))
  Mediumd_FAccIndex <- as.data.frame(append(Mediumd_FAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  Mediumd_FPerSupermarket <- as.data.frame(append(Mediumd_FPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  Mediumd_FPernotSupermarket <- as.data.frame(append(Mediumd_FPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  Mediumd_FRatio <- as.data.frame(append(Mediumd_FRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
Mediumd_FResultsEstimate <- t(Mediumd_FResultsEstimate)
Mediumd_FResultsStErr <- t(Mediumd_FResultsStErr)
Mediumd_FPValue <- t(Mediumd_FPValue)
Mediumd_FRSqr <- t(Mediumd_FRSqr)
Mediumd_FSumAcc <- t(Mediumd_FSumAcc)
Mediumd_FMeanAcc <- t(Mediumd_FMeanAcc)
Mediumd_FAccIndex <- t(Mediumd_FAccIndex)
Mediumd_FPerSupermarket <- t(Mediumd_FPerSupermarket)
Mediumd_FPernotSupermarket <- t(Mediumd_FPernotSupermarket)
Mediumd_FRatio <- t(Mediumd_FRatio)

Mediumd_FCombined <- data.frame(Mediumd_FResultsEstimate, Mediumd_FResultsStErr, Mediumd_FPValue, Mediumd_FRSqr, Mediumd_FSumAcc, Mediumd_FMeanAcc, Mediumd_FAccIndex, Mediumd_FPerSupermarket, Mediumd_FPernotSupermarket, Mediumd_FRatio)

#############################
#Reset default values and set d* to High value
ResetDefaultValues()
NLCommand("set d* 2.0")
NLCommand("set Calculate-Accessibility-Using-Socioeconomic-Data? FALSE") 

Highd_FResultsEstimate <- data.frame()
Highd_FResultsStErr <- data.frame()
Highd_FPValue <- data.frame()
Highd_FRSqr <- data.frame()
Highd_FSumAcc <- data.frame()
Highd_FMeanAcc <- data.frame()
Highd_FAccIndex <- data.frame()
Highd_FPerSupermarket <- data.frame()
Highd_FPernotSupermarket <- data.frame()
Highd_FRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)
  
  Highd_FResultsEstimate <- as.data.frame(append(Highd_FResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  Highd_FResultsStErr <- as.data.frame(append(Highd_FResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  Highd_FPValue <-as.data.frame(append(Highd_FPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  Highd_FRSqr <- as.data.frame(append(Highd_FRSqr, summary(reg)$adj.r.squared))
  Highd_FSumAcc <- as.data.frame(append(Highd_FSumAcc, NLReport("sum ([accessibility] of people)")))
  Highd_FMeanAcc <- as.data.frame(append(Highd_FMeanAcc, NLReport("mean [accessibility] of people")))
  Highd_FAccIndex <- as.data.frame(append(Highd_FAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  Highd_FPerSupermarket <- as.data.frame(append(Highd_FPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  Highd_FPernotSupermarket <- as.data.frame(append(Highd_FPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  Highd_FRatio <- as.data.frame(append(Highd_FRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
Highd_FResultsEstimate <- t(Highd_FResultsEstimate)
Highd_FResultsStErr <- t(Highd_FResultsStErr)
Highd_FPValue <- t(Highd_FPValue)
Highd_FRSqr <- t(Highd_FRSqr)
Highd_FSumAcc <- t(Highd_FSumAcc)
Highd_FMeanAcc <- t(Highd_FMeanAcc)
Highd_FAccIndex <- t(Highd_FAccIndex)
Highd_FPerSupermarket <- t(Highd_FPerSupermarket)
Highd_FPernotSupermarket <- t(Highd_FPernotSupermarket)
Highd_FRatio <- t(Highd_FRatio)

Highd_FCombined <- data.frame(Highd_FResultsEstimate, Highd_FResultsStErr, Highd_FPValue, Highd_FRSqr, Highd_FSumAcc, Highd_FMeanAcc, Highd_FAccIndex, Highd_FPerSupermarket, Highd_FPernotSupermarket, Highd_FRatio)

#######################
#Now run sweep of the education factor
#######################

#Reset default values and set education-factor to Low value
ResetDefaultValues()
NLCommand("set education-factor 0.1")

LowEduResultsEstimate <- data.frame()
LowEduResultsStErr <- data.frame()
LowEduPValue <- data.frame()
LowEduRSqr <- data.frame()
LowEduSumAcc <- data.frame()
LowEduMeanAcc <- data.frame()
LowEduAccIndex <- data.frame()
LowEduPerSupermarket <- data.frame()
LowEduPernotSupermarket <- data.frame()
LowEduRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)
  
  LowEduResultsEstimate <- as.data.frame(append(LowEduResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  LowEduResultsStErr <- as.data.frame(append(LowEduResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  LowEduPValue <-as.data.frame(append(LowEduPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  LowEduRSqr <- as.data.frame(append(LowEduRSqr, summary(reg)$adj.r.squared))
  LowEduSumAcc <- as.data.frame(append(LowEduSumAcc, NLReport("sum ([accessibility] of people)")))
  LowEduMeanAcc <- as.data.frame(append(LowEduMeanAcc, NLReport("mean [accessibility] of people")))
  LowEduAccIndex <- as.data.frame(append(LowEduAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  LowEduPerSupermarket <- as.data.frame(append(LowEduPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  LowEduPernotSupermarket <- as.data.frame(append(LowEduPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  LowEduRatio <- as.data.frame(append(LowEduRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
LowEduResultsEstimate <- t(LowEduResultsEstimate)
LowEduResultsStErr <- t(LowEduResultsStErr)
LowEduPValue <- t(LowEduPValue)
LowEduRSqr <- t(LowEduRSqr)
LowEduSumAcc <- t(LowEduSumAcc)
LowEduMeanAcc <- t(LowEduMeanAcc)
LowEduAccIndex <- t(LowEduAccIndex)
LowEduPerSupermarket <- t(LowEduPerSupermarket)
LowEduPernotSupermarket <- t(LowEduPernotSupermarket)
LowEduRatio <- t(LowEduRatio)

LowEduCombined <- data.frame(LowEduResultsEstimate, LowEduResultsStErr, LowEduPValue, LowEduRSqr, LowEduSumAcc, LowEduMeanAcc, LowEduAccIndex, LowEduPerSupermarket, LowEduPernotSupermarket, LowEduRatio)

#Reset default values and set education-factor to Medium value
ResetDefaultValues()
NLCommand("set education-factor 0.5")

MediumEduResultsEstimate <- data.frame()
MediumEduResultsStErr <- data.frame()
MediumEduPValue <- data.frame()
MediumEduRSqr <- data.frame()
MediumEduSumAcc <- data.frame()
MediumEduMeanAcc <- data.frame()
MediumEduAccIndex <- data.frame()
MediumEduPerSupermarket <- data.frame()
MediumEduPernotSupermarket <- data.frame()
MediumEduRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)
  
  MediumEduResultsEstimate <- as.data.frame(append(MediumEduResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  MediumEduResultsStErr <- as.data.frame(append(MediumEduResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  MediumEduPValue <-as.data.frame(append(MediumEduPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  MediumEduRSqr <- as.data.frame(append(MediumEduRSqr, summary(reg)$adj.r.squared))
  MediumEduSumAcc <- as.data.frame(append(MediumEduSumAcc, NLReport("sum ([accessibility] of people)")))
  MediumEduMeanAcc <- as.data.frame(append(MediumEduMeanAcc, NLReport("mean [accessibility] of people")))
  MediumEduAccIndex <- as.data.frame(append(MediumEduAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  MediumEduPerSupermarket <- as.data.frame(append(MediumEduPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  MediumEduPernotSupermarket <- as.data.frame(append(MediumEduPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  MediumEduRatio <- as.data.frame(append(MediumEduRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
MediumEduResultsEstimate <- t(MediumEduResultsEstimate)
MediumEduResultsStErr <- t(MediumEduResultsStErr)
MediumEduPValue <- t(MediumEduPValue)
MediumEduRSqr <- t(MediumEduRSqr)
MediumEduSumAcc <- t(MediumEduSumAcc)
MediumEduMeanAcc <- t(MediumEduMeanAcc)
MediumEduAccIndex <- t(MediumEduAccIndex)
MediumEduPerSupermarket <- t(MediumEduPerSupermarket)
MediumEduPernotSupermarket <- t(MediumEduPernotSupermarket)
MediumEduRatio <- t(MediumEduRatio)

MediumEduCombined <- data.frame(MediumEduResultsEstimate, MediumEduResultsStErr, MediumEduPValue, MediumEduRSqr, MediumEduSumAcc, MediumEduMeanAcc, MediumEduAccIndex, MediumEduPerSupermarket, MediumEduPernotSupermarket, MediumEduRatio)

#Reset default values and set education-factor to High value
ResetDefaultValues()
NLCommand("set education-factor 1.0")

HighEduResultsEstimate <- data.frame()
HighEduResultsStErr <- data.frame()
HighEduPValue <- data.frame()
HighEduRSqr <- data.frame()
HighEduSumAcc <- data.frame()
HighEduMeanAcc <- data.frame()
HighEduAccIndex <- data.frame()
HighEduPerSupermarket <- data.frame()
HighEduPernotSupermarket <- data.frame()
HighEduRatio <- data.frame()
for (i in 1:NumberOfRepetitions)
{
  NLCommand("setup")
  NLCommand("draw")
  NLCommand("make-pop")
  NLDoCommand(7, "go")
  peopleProperties <- NLGetAgentSet(c("accessibility","health","heart","overweight","edu","pov","fs"), "people", as.data.frame=TRUE)
  reg <- lm(peopleProperties$health ~ peopleProperties$accessibility)
  
  HighEduResultsEstimate <- as.data.frame(append(HighEduResultsEstimate, coef(summary(reg))["peopleProperties$accessibility","Estimate"]))
  HighEduResultsStErr <- as.data.frame(append(HighEduResultsStErr, coef(summary(reg))["peopleProperties$accessibility","Std. Error"]))
  HighEduPValue <-as.data.frame(append(HighEduPValue, coef(summary(reg))["peopleProperties$accessibility", "Pr(>|t|)"]))
  HighEduRSqr <- as.data.frame(append(HighEduRSqr, summary(reg)$adj.r.squared))
  HighEduSumAcc <- as.data.frame(append(HighEduSumAcc, NLReport("sum ([accessibility] of people)")))
  HighEduMeanAcc <- as.data.frame(append(HighEduMeanAcc, NLReport("mean [accessibility] of people")))
  HighEduAccIndex <- as.data.frame(append(HighEduAccIndex, NLReport("(accessibility-index-reserve / (count people)) / 0.5")))
  HighEduPerSupermarket <- as.data.frame(append(HighEduPerSupermarket, NLReport("100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)")))
  HighEduPernotSupermarket <- as.data.frame(append(HighEduPernotSupermarket, NLReport("100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)")))
  HighEduRatio <- as.data.frame(append(HighEduRatio, NLReport("(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))")))
} 
HighEduResultsEstimate <- t(HighEduResultsEstimate)
HighEduResultsStErr <- t(HighEduResultsStErr)
HighEduPValue <- t(HighEduPValue)
HighEduRSqr <- t(HighEduRSqr)
HighEduSumAcc <- t(HighEduSumAcc)
HighEduMeanAcc <- t(HighEduMeanAcc)
HighEduAccIndex <- t(HighEduAccIndex)
HighEduPerSupermarket <- t(HighEduPerSupermarket)
HighEduPernotSupermarket <- t(HighEduPernotSupermarket)
HighEduRatio <- t(HighEduRatio)

HighEduCombined <- data.frame(HighEduResultsEstimate, HighEduResultsStErr, HighEduPValue, HighEduRSqr, HighEduSumAcc, HighEduMeanAcc, HighEduAccIndex, HighEduPerSupermarket, HighEduPernotSupermarket, HighEduRatio)
