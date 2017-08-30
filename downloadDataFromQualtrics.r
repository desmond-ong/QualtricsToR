
downloadDataFromQualtrics <- function(apiTokenFile) {
  # requires curl and jsonlite
  library(curl)
  library(jsonlite)
  
  apiTokenInformation <- fromJSON(paste(readLines(apiTokenFile), collapse=""))
  # reading in the authentication tokens and survey IDs:
  myAPIToken = apiTokenInformation$apiToken
  mySurveyID = apiTokenInformation$surveyID
  
  # constructing and sending off the "export csv" request
  myHandle <- new_handle()
  handle_setopt(myHandle, copypostfields = paste('{ \n    \"surveyId\": \"', mySurveyID, '\", \n    \"format\": \"csv\" \n  }', sep=""));
  handle_setheaders(myHandle, "X-API-TOKEN" = myAPIToken, "Content-Type" = "application/json")

  raw_response <- curl_fetch_memory("https://yourdatacenterid.qualtrics.com/API/v3/responseexports", handle = myHandle)
  #print(raw_response$status_code)
  if(raw_response$status_code!=200) {
    stop(paste("There was an error issuing the export request. The request came back with status code:", raw_response$status_code, "\n"))
  } else {
    cat("Successfully issued a request to Qualtrics to export data in a csv format.\n")
    resultID = fromJSON(rawToChar(raw_response$content))$result$id
  }
  
  cat("Will wait 3 seconds for Qualtrics to export data...\n")
  Sys.sleep(3)
  
  # Checking to see if the exporting is done.
  myHandle <- new_handle()
  handle_setheaders(myHandle, "X-API-TOKEN" = myAPIToken, "Content-Type" = "application/json")
  data_url = paste('https://yourdatacenterid.qualtrics.com/API/v3/responseexports/', resultID, sep="")
  response_export_progress <- curl_fetch_memory(data_url, handle = myHandle)
  progress = fromJSON(rawToChar(response_export_progress$content))$result$percentComplete
  while(progress < 100) {
    cat(paste("Qualtrics has not finished exporting yet (at ", progress,"%). Will wait 3 seconds to try again...\n", sep=""))
    Sys.sleep(3)
    response_export_progress <- curl_fetch_memory(data_url, handle = myHandle)
    progress = fromJSON(rawToChar(response_export_progress$content))$result$percentComplete
  }

  # Downloading and unzipping
  curl_download(paste(data_url, '/file', sep=""), 'results_file.zip', handle=myHandle)
  cat(paste("Downloaded results file to ", getwd(), "/results_file.zip\n", sep=""))
  unzip("results_file.zip")
  outputFilename = unzip("results_file.zip", list=T)[1]
  cat(paste("Done unzipping the data to ", getwd(), "/", outputFilename, "\n", sep=""))
  
  # Reading in the survey file into dSurvey and returning it
  dSurvey = read.csv(paste(getwd(), "/", outputFilename, sep=""), header=FALSE, skip=2) 
  variableNames = read.csv(paste(getwd(), "/", outputFilename, sep=""), header=TRUE, nrows=1) 
  colnames(dSurvey) = colnames(variableNames) 
  
  return(dSurvey)
}

