# QualtricsToR
Helper functions that reads survey data directly from Qualtrics into R (via the Qualtrics API). Comments, bugs, feedback should be sent to me at desmond (dot) ong (at) stanford (dot) edu.


When using Qualtrics, here's the basic workflow to get your data, usually done using the Qualtrics website. (Qualtrics users should be familiar with this.)

- Request a data export (into .csv, or Excel, or SPSS, etc).
- When Qualtrics is finished exporting your data, you get a link to download the data onto your computer
- You'll need to do some minor cleaning before you can read it into R

The `downloadDataFromQualtrics()` function does this for you, via the Qualtrics API.

# Setup:

1. Install cURL. This should be standard on Mac and Unix platforms; Windows users might have to install it.
2. Requires access to Qualtrics API 
  * At least for my institution, I had to contact the IT Service Desk to request access to the API.
3. Obtain your **API Token**, store it in a safe place. (Importantly, as with all security tokens, NEVER upload this to Github or any other public repository). Refer to <a href="https://api.qualtrics.com/docs/authentication">this page</a> for details on how to obtain your API Token
4. While you're on the Qualtrics ID page, store the **Survey ID** of the particular survey you want to download.


# Using the R function

prerequisites: `curl` and `jsonlite`

1) Because of security issues, I don't want users to hardcode their API Tokens and Survey IDs into the function. Instead, edit the `sample_apiTokenFile` with your API Token and Survey ID. Rename it "apiTokenFile" (or whatever you wish, I'm assuming it's "apiTokenFile"), and make sure that this file is never committed to a public repo.

2) In your R script, import the helper function. It takes in one argument, the "apiTokenFile". After you call the function, it should do everything for you (request an export, check that the export is ready for download, download the zip file, unzip the zip file, read the csv into R after removing the 2nd and 3rd row):
```r
source("downloadDataFromQualtrics.r")
dSurvey = downloadDataFromQualtrics("apiTokenFile")
```

- If you don't want to keep downloading data from Qualtrics and you want to use the file that you just downloaded, you can get that from the last line that the function prints to the console.
```r
Done unzipping the data to filename.csv
```
It should be the name of the survey in Qualtrics. Scroll to the bottom for sample code on reading this csv into R (i.e., removing the pesky 2nd and 3rd row).


# Using plain old curl

If you're comfortable using the command line (Terminal) directly, then you can use cURL to download the data. These examples are taken more or less directly from the Qualtrics API documentation, and the downloadDataFromQualtrics.R code is basically the below steps, wrapped in nice R code.

1) Open Terminal. use cURL to send a "csv export" request to Qualtrics (<a href="https://api.qualtrics.com/docs/csv">details</a>): 
```
  curl -X POST -H 'X-API-TOKEN: ***API_TOKEN***' -H 'Content-Type: application/json' -d '{ 
    "surveyId": "***SURVEY_ID***", 
    "format": "csv" 
  }' 'https://yourdatacenterid.qualtrics.com/API/v3/responseexports' 
```

2) You should receive a 200 response with a Result ID. 
```
   {"result":{"id":"***RESULT_ID***"},"meta":{"httpStatus":"200 - OK"}} 
```

Use cURL again with this Result ID to download the file into a .zip file. (<a href="https://api.qualtrics.com/docs/get-response-export">details</a>) You may have to wait a little while for Qualtrics to export the data.
```
  curl -X GET -H "Content-Type: application/json" -H "X-API-TOKEN: ***API_TOKEN***" 
  "https://yourdatacenterid.qualtrics.com/API/v3/responseexports/***RESULT_ID***/file" -o response.zip 
```

3) Unzip the file (response.zip)

4) After that, read the .csv into R! 
```r
  csvFilename = "survey_name.csv" 
  dSurvey = read.csv(csvFilename, header=FALSE, skip=3) 
  variableNames = read.csv(csvFilename, header=TRUE, nrows=1) 
  colnames(dSurvey) = colnames(variableNames) 
  rm(variableNames)
```
