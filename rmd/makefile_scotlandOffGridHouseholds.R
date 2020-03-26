# loads data for scotlandOffGridHouseholds
# Libraries ----
library(drake) # preload data
library(data.table) # dataframes on steroids
library(here) # for here

library(rmarkdown) # for knit
library(bookdown) # for fancy knit

# Project Settings ----
myParams <- list()
myParams$projLoc <- here::here()
myParams$beisPath <- "~/Data/DECC/SubnationalEnergyData/2010-2018/LSOA_DOM_ELEC_csv/"
myParams$censusPath <- "/Users/ben/Data/UK_Census/2011Data/scotland/SNS Data Zone 2011 blk/"

# functions ----

getCensusData <- function(){
  # in this case it's Scottish datazones and all we need is household spaces
  f <- "LC4403SC.csv"
  dt <- data.table::fread(paste0(myParams$censusPath, f))
  dt[, zonecode := V1] # to match to BEIS data
  # slightly weird format - sort of a cross-tab with zones plus a line for all of Scotland
  
  dt[, nHHspaces2011 := `All household spaces`] # we need this
  dt <- dt[V2 == "All household spaces" & #  this is the only row type we need
             V1 != "S92000003"] # this is the scotland total
  return(dt)
}

getBeisData <- function(){
  # elec - lsoas <-> datazones
  # hardcoded to load all the data we have so we can test each year (if the zones match)
  allDT <- data.table::data.table() # place to put data
  for(y in 2010:2018){
    message("Loading BEIS LSOA level elec: ", y)
    dt <- data.table::fread(paste0(myParams$beisPath, "LSOA_ELEC_",y,".csv"))
    dt[, zonecode := LSOACode]
    dt[, year := y]
    allDT <- rbind(allDT, dt)
    
  }
  return(allDT)
}

doReport <- function(rmd){
  rmdFile <- paste0(myParams$projLoc, "/rmd/", rmd, ".Rmd")
  rmarkdown::render(input = rmdFile,
                    params = list(title = title,
                                  subtitle = subtitle,
                                  authors = authors),
                    output_file = paste0(myParams$projLoc,"/docs/", # for easy github pages management
                                         rmd, ".html")
  )
}

# code ----
beisDT <- getBeisData()
censusDT <- getCensusData()


uniqueN(beisDT$zonecode)
beisDT[, .(nZones = .N), keyby = .(year)]

# looks like they used the same zones (LSOAs/datazones) all the way through
# but we can't be sure
# what happened in 2015?

setkey(censusDT, zonecode)
setkey(beisDT, zonecode)
scotlandDT <- beisDT[censusDT] # keeps records in the census data (Scotland)

table(scotlandDT$LAName, scotlandDT$year, useNA = "always")
# No NAs :-)

title <- "Estimating the number of off grid households"
subtitle <- "Scotland"
authors <- "Ben Anderson (b.anderson@soton.ac.uk `@dataknut`)"
rmd <- "scotlandOffGridHouseholds"

doReport(rmd)
