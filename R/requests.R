#' Get Covid-19 Data From Serendipia's page
#'
#' Get Covid-19 Data From Serendipia's page
#'
#' Mexico's Ministry of Health publishes a daily report containing data about
#' positive and suspected cases of Covid-19 cases in the country. However, the data is published
#' as a PDF document, difficulting further analysis. Serendipia, a data based journalism initiative,
#' publishes CSV and XLSX versions of the official reports. This function makes a request to
#' Serendipia's Covid-19 data page and downloads the specified data table.
#'
#' @return A `tibble` with 8 columns:
#' Case Number, State, Sex, Age, Symptoms Onset Date, COVID-19 Test Result, Country Visited,
#' Date of Arrival to Mexico.
#'
#' @param targetURL Target URL of the HTTP request. `character` vector of length 1.
#' @param targetCSS CSS selector of the nodes containing the data files URL. `character` vector of length 1.
#' @param type Get `confirmed` or `suspect` cases?. `character` vector of length 1.
#' @param date Date (version) of the published results. `character` vector of length 1 or `date` object.
#'
#' @importFrom tibble tibble
#' @importFrom readr read_csv
#' @import lubridate
#' @import stringr
#' @import httr
#' @import rvest
#' @export

GetFromSerendipia <-
  function(targetURL = "https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/",
           targetCSS = "a.wp-block-file__button",
           type = "confirmed",
           date = "today") {

    # First some type and value check
    if (!is.character(targetURL) | length(targetURL) > 1 ) {
      stop("'targetURL' par must be a character vector of length 1!")
    }
    if (!is.character(targetCSS) | length(targetCSS) > 1 ) {
      stop("'targetCSS' par must be a character vector of length 1!")
    }
    if (!is.character(type) | length(type) > 1 ) {
      stop("'type' par must be a character vector of length 1!")
    }
    if (!is.Date(date) & !is.character(date) | length(date) > 1) {
      stop("'date' par must be a date object or a character vector of length 1!")
    }

    # Send page request to targetURL
    # I'm nice, so I include some headers informing that the request is
    # being made from this r package
    # Header key names are enclosed in backtick since R interprets '-' as minus
    response <- GET(url = targetURL, add_headers(`User-Agent` = "R Package (covidMex)",
                                                 `X-Package-Version` = as.character(packageVersion("covidMex")),
                                                 `X-R-Version` = R.version.string))
    # Parse response
    parsedResponse <- content(x = response, as = "parsed")

    # Get all node elements with the target class
    buttons <- html_nodes(x  = parsedResponse, css = targetCSS)

    # Get href attr from node elements
    hrefs <- html_attr(x = buttons, name = "href", default = NA)

    # Try to parse date as date
    if (!is.Date(date)) {
      # If str = today use today's date, else use dmy
      if (date == "today") parsedDatePar <- today() else parsedDatePar <- dmy(date, quiet = T)
    } else {
      parsedDatePar <- date
    }

    # Filter urls (confirmed vs suspected cases)
    # First create a regex patter that depends on the type of cases
    if (type == "confirmed") {
      pattern <- "(?=positivos).*_(\\d*.\\d*.\\d*)"
    }  else if (type == "suspect") {
      pattern <- "(?=sospechosos).*_(\\d*.\\d*.\\d*)"
    } else {
      stop("Unknown data type! Available data types: 'confirmed' or 'suspect'")
    }

    # Filter
    hrefs <- hrefs[grepl(pattern = pattern, x = hrefs, perl = T)]

    # Get dates of the documents
    # The second column of the matrix corresponds to the date in the document name
    dates <- str_match(hrefs, pattern = pattern)[,2]

    # Get parsed version of the dates
    parsedDates <- parse_date_time(x = dates, orders = "%Y.%m.%d")

    # Build a tibble with the data
    cat <- tibble(hrefs, dates, parsedDates)

    # Try to get data from today's date
    continue <- TRUE
    count <- 1
    while (continue) {
      # Subset comparing parsedDatePar
      catSubset <- cat[cat$parsedDates == parsedDatePar,]
      # Count number of rows of subset result
      # No rows means that there's not yet data for today
      if (nrow(catSubset) == 0) {
        if (count > 5) {
          stop(paste("The specified date (", parsedDatePar ,") is not available (stopped because too many attempts)",
                     sep = ""))
        }
        count <- count + 1
        warning(paste("The specified date (", parsedDatePar ,") is not available... trying yesterday's date instead",
                      sep = ""))
        parsedDatePar <- parsedDatePar - days(1)
      } else {
        continue <- FALSE
      }
    }

    # Get URL from subset result
    targetURL <- catSubset$hrefs[1]

    # Define temp file name
    fileExt <- str_match(targetURL, ".*\\.(\\w+)")[,2]
    targetFile <- tempfile("covid19Mex_", fileext = fileExt)

    # Make request and save response file in temp directory
    GET(url = targetURL, write_disk(targetFile, overwrite = T),
        add_headers(`User-Agent` = "R Package (covidMex)",
                    `X-Package-Version` = as.character(packageVersion("covidMex")),
                    `X-R-Version` = R.version.string))

    # Read file
    data <- read_csv(targetFile)

    return(data)
}

#' Get Covid-19 Data From Katia Guzman's GitHub page
#'
#' Get Covid-19 Data From Katia Guzman's GitHub page
#'
#' Mexico's Ministry of Health publishes a daily report containing data about
#' positive and suspected cases of Covid-19 cases in the country. However, the data is published
#' as a PDF document, difficulting further analysis. Katia Guzman makes an open format
#' version of the report that it's also manually checked for errors and includes a column
#' with the date when the case was first registered in the official count.
#'
#' @return A `tibble` with 9 columns:
#' Case Number, State, Sex, Age, Symptoms Onset Date, COVID-19 Test Result, Country Visited,
#' Date of Arrival to Mexico, and Date when case officialy registered.
#'
#' @param targetURL Target URL of the HTTP request. `character` vector of length 1.
#' @param filePrefix Target file prefix in GitHub repo. `character` vector of length 1.
#' @param fileExt Target file extension in GitHub repo. `character` vector of length 1.
#' @param date Date (version) of the published results. `character` vector of length 1 or `date` object.
#'
#' @importFrom readxl read_excel
#' @import lubridate
#' @import stringr
#' @import httr
#' @import rvest
#' @export

GetFromGuzmart <-
  function (targetURL = "https://github.com/guzmart/covid19_mex/raw/master/01_datos/",
            filePrefix = "covid_mex_",
            fileExt = ".xlsx",
            date = "today") {

    # First some type and value check
    if (!is.character(targetURL) | length(targetURL) > 1 ) {
     stop("'targetURL' par must be a character vector of length 1!")
    }
    if (!is.character(filePrefix) | length(filePrefix) > 1 ) {
     stop("'filePrefix' par must be a character vector of length 1!")
    }
    if (!is.character(fileExt) | length(fileExt) > 1 ) {
     stop("'fileExt' par must be a character vector of length 1!")
    }
    if (!is.Date(date) & !is.character(date) | length(date) > 1) {
     stop("'date' par must be a date object or a character vector of length 1!")
    }

    # Try to parse date as date
    if (!is.Date(date)) {
      # If str = today use today's date, else use dmy
      if (date == "today") parsedDatePar <- today() else parsedDatePar <- dmy(date, quiet = T)
    } else {
      parsedDatePar <- date
    }

    # Try to get data from today's date
    continue <- TRUE
    count <- 1
    while (continue) {
      # Get character prepresentation of the date
      strDate <- format(parsedDatePar, "%Y%m%d")
      # Make request and save response file in temp directory
      full_targetURL <- paste(targetURL, filePrefix, strDate, fileExt, sep = "")
      targetFile <- tempfile("covid19Mex_", fileext = fileExt)
      response <- GET(url = full_targetURL, write_disk(targetFile, overwrite = T),
                      add_headers(`User-Agent` = "R Package (covidMex)",
                      `X-Package-Version` = as.character(packageVersion("covidMex")),
                      `X-R-Version` = R.version.string))
      # If file does not exists
      if (status_code(response) > 300) {
        if (count > 5) {
          stop(paste("The specified date (", parsedDatePar ,") is not available (stopped because too many attempts)",
                     sep = ""))
        }
        count <- count + 1
        warning(paste("The specified date (", parsedDatePar ,") is not available... trying yesterday's date instead",
                      sep = ""))
        parsedDatePar <- parsedDatePar - days(1)
      } else {
        continue <- FALSE
        suppressWarnings({
          data <- read_excel(targetFile)
          data$fecha_llegada_mexico <- as.integer(data$fecha_llegada_mexico)
          data$fecha_llegada_mexico <- as.Date(data$fecha_llegada_mexico, origin = "1899-12-30")
        })
      }
    }

    return(data)
}
