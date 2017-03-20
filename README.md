# This repository contains code which creates a database of MBIE's tourism microdata
This repository contains [R](https://www.rstudio.com/) code for creating a [MySQL](https://www.mysql.com/) database and populating this with tourism microdata. 

## A working MySQL database and RMySQL connection is needed
In order to use this database you will need a working connection to a [MySQL](https://www.mysql.com/) server that can be accessed via [RMySQL](https://cran.r-project.org/web/packages/RMySQL/index.html), and credentials that allow you to create databases and tables. The script could be easily adapted for other database platforms, pull requests will be considered.

## The main file is /create-database/create_database_mysql.R
The main file in the repository is an R script under the create-database folder. This script downloads about 100MB of tourism microdata from the MBIE website, creates a database called 'production' on a [MySQL](https://www.mysql.com/) connection and populates the database with the tourism microdata.  The intention is to re-create the MBIE environment as closely as possible.  The microdata CSVs that are downloaded are dumps from the analysis-ready views in the "TRED" database in the MBIE environment.

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.
