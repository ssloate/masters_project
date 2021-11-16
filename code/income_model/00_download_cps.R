setwd('/Users/samsloate/Desktop/807 MP/masters_project/data/cps') 
if (!require("ipumsr")) stop("Reading IPUMS data into R requires the ipumsr package. It can be installed using the following command: install.packages('ipumsr')") 
ddi <- read_ipums_ddi("cps_00008.xml") 
data <- read_ipums_micro(ddi) 
write.csv(data, "raw_cps_microdata.csv") 

