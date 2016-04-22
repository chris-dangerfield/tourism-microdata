library(RMySQL) # for connecting to database
library(tcltk2) # for AskCreds

message(
"Running this script will delete the 'Production' database on your
MySQL server and download all tourism data from scratch.  Are you sure 
you want to proceed? [y/n] ")
proceed <- readLines(n = 1)
if(tolower(proceed) != "y"){
    stop("Aborting database build.")
}

source("create-database/functions.R") # to define AskCreds

creds <- AskCreds("Enter credentials for a user that can create a database")

TRED <- dbConnect(RMySQL::MySQL(), username = creds$uid, password = creds$pwd)

# create a database called production if it doesn't already exist

dbSendQuery(TRED, "DROP DATABASE IF EXISTS production")
dbSendQuery(TRED, "create database production")
dbSendQuery(TRED, "use production")

base_url <- "http://www.mbie.govt.nz/info-services/sectors-industries/tourism/tourism-research-data/"
all_zip_urls <- c(
    "international-tourism-forecasts/resolveuid/3cca40265bb546bea77875e473550cae",
    "ivs/resolveuid/5e6c0e5b19bb47a68205ac1247cde8f0"
    )
all_data_sets <- c("NZTF", "IVS")

dir.create("tmp")

for(i in 1:length(all_zip_urls)){
    
    this_zip_url <- all_zip_urls[i]
    this_data <- all_data_sets[i]
    this_zip_file <- paste0("tmp/", this_data, ".zip")
    
    download.file(url      = paste0(base_url, this_zip_url), 
                  destfile = this_zip_file,
                  mode     = "wb")
    unzip(this_zip_file, exdir = "tmp")
    
    csvs <- dir(paste0("tmp/", this_data), full.names = FALSE)
    
    for(j in 1:length(csvs)){
        this_csv <- read.csv(paste0("tmp/", this_data, "/", csvs[j]), 
                             stringsAsFactors = FALSE)
        this_table <- gsub(".csv", "", csvs[j], fixed = TRUE)
    
        dbSendQuery(TRED, paste("DROP TABLE IF EXISTS", this_table))
        message(paste("Writing", this_table))
        dbWriteTable(TRED, this_table, this_csv, row.names = FALSE, overwrite = TRUE)
        
        
        # Index the database table we just made.
        # If SurveyResponseID uniquely identifies rows, make it the primary key.
        # Otherwise it should still be an index, and the table will not have a 
        # primary key (this is not good database practice, but does the job for
        # these relatively small datasets)
        if(length(unique(this_csv$SurveyResponseID)) == nrow(this_csv)){
            indexing_sql <- paste("ALTER TABLE", this_table, 
                                  "ADD PRIMARY KEY(SurveyResponseID)")
        } else {
            if("SurveyResponseID" %in% names(this_csv)){
                indexing_sql <- paste("CREATE INDEX SurveyResponseID ON", 
                                      this_table,
                                      "(SurveyResponseID)")
            } else {
                next()
            }
            
        }
        message(paste("Indexing", table_name))
        dbSendQuery(TRED, indexing_sql)
    
    }
}

    dbDisconnect(TRED)
# ------------------playing----------------

# dbListTables(TRED)
# 
# dbGetQuery(TRED, "select * from vw_nztfsurveymainheader limit 10")
