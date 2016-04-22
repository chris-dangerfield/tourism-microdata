# This script downloads about 100MB of tourism microdata from the MBIE website,
# creates a database called 'production' on a MySQL connection and populates
# the database with the tourism microdata.  The intention is to re-create the
# MBIE environment as closely as possible.  The microdata CSVs that are 
# downloaded are dumps from the analysis-ready views in the "TRED" database
# in the MBIE environment.  
#
# The motivation is to allow SQL and R code that works in the MBIE environment 
# also to work for externals, whether because they are doing contract work for 
# MBIE or using the data for their own purposes.
#
# Needs to be run from the root directory of the repository as it includes
# reference to another script with a helper function.
#
# You need a working connection to a MySQL server that can be accessed via 
# RMySQL, and credentials that allow you to create databases and tables.
# The script could be easily adapted for other database platforms, pull requests
# will be considered.
#
# Peter Ellis, 23 April 2016


library(RMySQL) # for connecting to database
library(tcltk2) # for AskCreds

message(
"Running this script will download all New Zealand tourism data from scratch and
over-write any existing tables with comparable names in the database named 
'production' of your MySQL server.  Are you sure you want to proceed? [y/n] ")
proceed <- readLines(n = 1)
if(tolower(proceed) != "y"){
    stop("Aborting database build.")
}

source("create-database/functions.R") # to define AskCreds

# Connect to database server
creds <- AskCreds("Enter credentials for a user that can create a database")
TRED <- dbConnect(RMySQL::MySQL(), username = creds$uid, password = creds$pwd)

# create a database called production if it doesn't already exist
# dbSendQuery(TRED, "DROP DATABASE IF EXISTS production")
try(dbSendQuery(TRED, "create database production"))
dbSendQuery(TRED, "use production")

# define URLs of the source data
base_url <- "http://www.mbie.govt.nz/info-services/sectors-industries/tourism/tourism-research-data/"
all_zip_urls <- c(
    "international-tourism-forecasts/resolveuid/3cca40265bb546bea77875e473550cae",
    "ivs/resolveuid/5e6c0e5b19bb47a68205ac1247cde8f0",
    "regional-tourism-estimates/resolveuid/49a250d6850d4220b97454b79ba42baf",
    "domestic-travel-survey/resolveuid/d063c547e2044c1281bbbc4dab310659"
    )
all_data_sets <- c("NZTF", "IVS", "RTE", "DTS")

# create a temporary tmp file to hold the downloads.  Note - the script does 
# not clean up after itself, if you want to delete this tmp/ folder it is up
# to you.
dir.create("tmp")

# Main sequence of downloading files and creating database tables starts here:
for(i in 1:length(all_zip_urls)){
    
    this_zip_url <- all_zip_urls[i]
    this_data <- all_data_sets[i]
    this_zip_file <- paste0("tmp/", this_data, ".zip")
    
    download.file(url      = paste0(base_url, this_zip_url), 
                  destfile = this_zip_file,
                  mode     = "wb")
    unzip(this_zip_file, exdir = "tmp")
    message(paste("Finished unzipping", this_zip_file))
    
    csvs <- dir(paste0("tmp/", this_data), full.names = FALSE)
    
    for(j in 1:length(csvs)){
        this_csv <- read.csv(paste0("tmp/", this_data, "/", csvs[j]), 
                             stringsAsFactors = FALSE)
        this_table <- gsub(".csv", "", csvs[j], fixed = TRUE)
        
        # Some of the views in MBIE TRED have illegal names (spaces and minus
        # signs) and we replace this with underscores - so for these small 
        # number of tables the MySQL version will differ from that in MBIE.
        this_table <- gsub(" - ", "_", this_table, fixed = TRUE)
        this_table <- gsub(" ", "_", this_table, fixed = TRUE)
    
        dbSendQuery(TRED, paste("DROP TABLE IF EXISTS", this_table))
        message(paste("Writing", this_table))
        dbWriteTable(TRED, this_table, this_csv, row.names = FALSE, overwrite = TRUE)
        
        
        # Index the database table we just made.
        # If SurveyResponseID uniquely identifies rows, make it the primary key.
        # Otherwise it should still be an index, and the table will not have a 
        # primary key (this is not good database practice, but does the job for
        # these relatively small datasets)
        if(length(unique(this_csv$SurveyResponseID)) == nrow(this_csv)){
            message (paste("Using SurveyResponseID as primary key on", this_table))
            indexing_sql <- paste("ALTER TABLE", this_table, 
                                  "ADD PRIMARY KEY(SurveyResponseID)")
        } else {
            if("SurveyResponseID" %in% names(this_csv)){
                message(paste("Adding a primary key to", this_table))
                dbSendQuery(TRED, paste("ALTER TABLE", this_table, "ADD pk_column INT AUTO_INCREMENT PRIMARY KEY;"))
                
                message(paste("Adding a SurveyResponseID index to", this_table))
                indexing_sql <- paste("CREATE INDEX SurveyResponseID ON", 
                                      this_table,
                                      "(SurveyResponseID)")
            } else {
                next()
            }
            
        }
        
        dbSendQuery(TRED, indexing_sql)
    
    }
}

    dbDisconnect(TRED)
# ------------------playing----------------

# dbListTables(TRED)
# 
# dbGetQuery(TRED, "select * from vw_ivsactivities limit 10")
