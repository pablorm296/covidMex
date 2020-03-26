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
#' @return A \code{tibble} with 8 columns:
#' Case Number, State, Sex, Age, Symptoms Onset Date, COVID-19 Test Result, Country Visited,
#' Date of Arrival to Mexico.
#'
#' @param targetURL Target URL of the HTTP request. \code{character} vector of length 1.
#' @param targetCSS CSS selector of the nodes containing the data files URL. \code{character} vector of length 1.
#' @param type Get confirmed (\code{confirmed}) or suspect (\code{suspects}) cases?. \code{character} vector of length 1.
#' @param date Date (version) of the report. \code{character} vector of length 1 or \code{Date} object.
#' #' If \code{character}, date must be in day/month/year format.
#' @param neat Should data be cleaned (dates, state name, column names)? \code{logical} vector of length 1.
#'
#' @importFrom tibble tibble
#' @importFrom readr read_csv
#' @importFrom dplyr rename
#' @import lubridate
#' @import stringr
#' @import httr
#' @import rvest
#' @export

GetFromSerendipia <-
  function(targetURL = "https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/",
           targetCSS = "table a, table a:link",
           type = "confirmed",
           date = "today",
           neat = TRUE) {

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
    # Header key names are enclosed in backticks since R interprets '-' as minus
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

    # Filter urls (confirmed vs suspect cases)
    # First create a regex pattern that depends on the type of cases
    # For positive (confirmed) cases
    if (type == "confirmed") {
      pattern <- "(?=positivos).*_(\\d*.\\d*.\\d*)"
    # For suspect cases
    }  else if (type == "suspects") {
      pattern <- "(?=sospechosos).*_(\\d*.\\d*.\\d*)"
    } else {
      stop("Unknown data type! Available data types: 'confirmed' or 'suspects'")
    }

    # Filter links depending on the type requested by the user
    hrefs <- hrefs[grepl(pattern = pattern, x = hrefs, perl = T)]

    # Get dates of the documents
    # The second column of the matrix is the date of the document
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
      # No rows means that there's not data for today
      if (nrow(catSubset) == 0) {
        # If more than 5 attempts, send error
        if (count > 5) {
          stop("The specified date (", parsedDatePar ,") is not available. No file matches the pattern (stopped because too many attempts)")
        }
        count <- count + 1
        warning("The specified date (", parsedDatePar ,") is not available... trying yesterday's date instead")
        parsedDatePar <- parsedDatePar - days(1)
      # If found a doc with today's date, stop while loop
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
    response <- GET(url = targetURL, write_disk(targetFile, overwrite = T),
                    add_headers(`User-Agent` = "R Package (covidMex)",
                                `X-Package-Version` = as.character(packageVersion("covidMex")),
                                `X-R-Version` = R.version.string))

    #Check response from the server
    if (status_code(response) > 399) {
      stop("The specified dataset is not available (GitHub server responded with status code ", status_code(response), ")")
    }

    # Read file. Use suppressWarnings to hide parsing failures. Use suppressMessages to hide read_csv messages
    suppressWarnings({
      if (!is.na(str_match(fileExt, "csv")[1,1])) {
        data <- suppressMessages(read_csv(targetFile))
      } else if (!is.na(str_match(fileExt, "xlsx")[1,1])) {
        data <- suppressMessages(read_excel(targetFile))
      }

    })

    # User wants a clean version of the data
    if (neat) {
      if(type == "suspects") {
        # Make a copy of the data
        cleanData <- data
        # Use a tryCath in case any unexpect table content
        tryCatch(
          #Supress any warnings
          suppressWarnings({
            cleanData <- rename(cleanData, num_caso = 1,
                                ent = 2,
                                localidad = 3,
                                sexo = 4,
                                edad = 5,
                                fecha_inicio = 6,
                                identificado = 7,
                                procedencia = 8,
                                fecha_llegada_mexico = 9)
            cleanData$ent <- str_to_title(cleanData$ent)
            cleanData$ent <- str_replace(cleanData$ent, "De", "de")
            cleanData$fecha_llegada_mexico <- as.Date(cleanData$fecha_llegada_mexico,
                                                      format = "%d/%m/%Y")
            cleanData$fecha_inicio <- as.Date(cleanData$fecha_inicio,
                                              format = "%d/%m/%Y")
            data <- cleanData
          }),
          # If error
          error = function(e) {
            warning("Cleaning data failed! Maybe a column was added/removed or changed. Please clean the returned data manually.\n", e)
          }
        )
      } else if (type == "confirmed") {
        # Make a copy of the data
        cleanData <- data
        # Use a tryCath in case any unexpect table content
        tryCatch(
          #Supress any warnings
          suppressWarnings({
            cleanData <- rename(cleanData, num_caso = 1,
                                ent = 2,
                                sexo = 3,
                                edad = 4,
                                fecha_inicio = 5,
                                identificado = 6,
                                procedencia = 7,
                                fecha_llegada_mexico = 8)
            cleanData$ent <- str_to_title(cleanData$ent)
            cleanData$ent <- str_replace(cleanData$ent, "De", "de")
            cleanData$fecha_llegada_mexico <- as.Date(cleanData$fecha_llegada_mexico,
                                                      format = "%d/%m/%Y")
            cleanData$fecha_inicio <- as.Date(cleanData$fecha_inicio,
                                              format = "%d/%m/%Y")
            data <- cleanData
          }),
          # If error
          error = function(e) {
            warning("Cleaning data failed! Maybe a column was added/removed or changed. Please clean the returned data manually.\n", e)
          }
        )
      }
    }

    return(data)
}

#' Get Covid-19 Data From Katia Guzman's GitHub repo
#'
#' Get Covid-19 Data From Katia Guzman's GitHub repo
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
#' @param targetURL Target URL of the HTTP request. \code{character} vector of length 1.
#' @param filePrefix Target file prefix in GitHub repo. \code{character} vector of length 1.
#' @param fileExt Target file extension in GitHub repo. \code{character} vector of length 1.
#' @param date Date (version) of the report. \code{character} vector of length 1 or \code{Date} object.
#' #' If \code{character}, date must be in day/month/year format.
#' @param neat Should data be cleaned (dates, state name, column names)? \code{logical} vector of length 1.
#'
#' @importFrom readxl read_excel
#' @importFrom dplyr rename
#' @import lubridate
#' @import stringr
#' @import httr
#' @import rvest
#' @export

GetFromGuzmart <-
  function (targetURL = "https://github.com/guzmart/covid19_mex/raw/master/01_datos/",
            filePrefix = "covid_mex_",
            fileExt = ".xlsx",
            date = "today",
            neat = TRUE) {

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
    if ((!is.Date(date) & !is.character(date)) | length(date) > 1) {
     stop("'date' par must be a date object or a character vector of length 1!")
    }

    # Try to parse date as date
    if (!is.Date(date)) {
      # If str = today use today's date, else use dmy
      if (date == "today") parsedDatePar <- today() else parsedDatePar <- dmy(date, quiet = T)
    } else {
      parsedDatePar <- date
    }

    # Define temp file path
    targetFile <- tempfile("covid19Mex_", fileext = fileExt)

    # Try to get data from today's date
    continue <- TRUE
    count <- 1
    while (continue) {
      # Get character representation of the date
      strDate <- format(parsedDatePar, "%Y%m%d")
      # Make request and save response file in temp directory
      full_targetURL <- paste(targetURL, filePrefix, strDate, fileExt, sep = "")
      response <- GET(url = full_targetURL, write_disk(targetFile, overwrite = T),
                      add_headers(`User-Agent` = "R Package (covidMex)",
                      `X-Package-Version` = as.character(packageVersion("covidMex")),
                      `X-R-Version` = R.version.string))
      # If server responds with an error
      if (status_code(response) > 399) {
        # If more than 5 tries, stop
        if (count > 5) {
          stop("The specified date (", parsedDatePar ,") is not available. The server responded with status code ", status_code(response),
               " (stopped because too many attempts)")
        }
        # Add one to try count
        count <- count + 1
        # Warn user that we're using yesterday's date
        warning("The specified date (", parsedDatePar ,") is not available. The server responded with status code ",
             status_code(response),
             ". Trying yesterday's date...")
        # ParsedDate minus one
        parsedDatePar <- parsedDatePar - days(1)
      # Server responded ok
      } else {
        # If found a doc with today's date, stop while loop
        continue <- FALSE
        # read_excel throws a lot of ugly warnings and there's not any warning supression par >:(
        suppressWarnings({
          data <- read_excel(targetFile)
        })
        # User wants a clean version of the data
        if (neat) {
          # Create a copy of the data
          cleanData <- data
          # Use a tryCatch in case the columns names / order changes
          tryCatch(
            #Supress any warnings
            suppressWarnings({
              cleanData$ent <- str_to_title(cleanData$ent)
              cleanData$ent <- str_replace(cleanData$ent, "De", "de")
              cleanData$fecha_corte <- as.Date(cleanData$fecha_corte)
              cleanData$fecha_llegada_mexico <- as.integer(cleanData$fecha_llegada_mexico)
              cleanData$fecha_llegada_mexico <- as.Date(cleanData$fecha_llegada_mexico,
                                                        origin = "1899-12-30")
              cleanData$fecha_inicio <- as.integer(cleanData$fecha_inicio)
              cleanData$fecha_inicio <- as.Date(cleanData$fecha_inicio,
                                                origin = "1899-12-30")
              data <- cleanData
            }),
            # If error, only warn the user
            error = function(e) {
              warning("Cleaning data failed! Maybe a column was added/removed or changed. Please clean the returned data manually.\n", e)
            }
          )
        }
      } #end if
    } #end while

    return(data)
  } #end function

#' Get Covid-19 Data From ECDC
#'
#' Get Covid-19 situation report from the European Centre for Disease Prevention and Control. This situation
#' report includes new cases and deaths in all countries in the world.
#'
#' @return A `tibble` with 9 columns:
#' Date, Day, Month, Year, New Cases, New Deaths, Country or Territory, Country ID, Country Population (World Bank 2018 Estimates).
#'
#' @param prefixURL URL prefix for the HTTP request. \code{character} vector of length 1.
#' @param date Date (version) of the report. \code{character} vector of length 1 or \code{Date} object.
#' If \code{character}, date must be in day/month/year format.
#' @param fileExt Target file extension in ECDC server \code{character} vector of length 1.
#' @param auth Authentication information generated by \code{authenticate}. \code{request} object.
#' @param neat Should data be cleaned (dates, state name, column names)? \code{logical} vector of length 1.
#'
#' @importFrom readxl read_excel
#' @import httr
#' @import lubridate
#' @export
GetFromECDC <- function(
  prefixURL = "https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-",
  date = "today",
  fileExt = ".xlsx",
  auth = authenticate(user = ":", password = ":", type = "ntlm"),
  neat = TRUE) {

  # First some type and value check
  if (!is.character(prefixURL) | length(prefixURL) > 1 ) {
    stop("'prefixURL' par must be a character vector of length 1!")
  }
  if ((!is.character(date) & !is.Date(date)) | length(date) > 1 ) {
    stop("'date' par must be a date object or a character vector of length 1!")
  }
  if (!is.character(fileExt) | length(fileExt) > 1 ) {
    stop("'fileExt' par must be a character vector of length 1!")
  }
  if (class(auth) != "request") {
    stop("'auth' par must be an instance of httr::request!")
  }

  # Try to parse date as date
  if (!is.Date(date)) {
    # If str = today use today's date, else use dmy
    if (date == "today") parsedDatePar <- today() else parsedDatePar <- dmy(date, quiet = T)
    strDate <- format(parsedDatePar, "%Y-%m-%d")
  } else {
    parsedDatePar <- date
    strDate <- format(date, "%Y-%m-%d")
  }

  # Define target URL and target temp file
  targetURL <- paste(prefixURL, strDate, fileExt, sep = "")
  targetFile <- tempfile("covid19WW_", fileext = fileExt)

  # Try to get data from today's date
  # Define a continue and a try count variable
  continue <- TRUE
  count <- 1
  while (continue) {
    # Send HTTP GET request to target URL
    targetURL <- paste(prefixURL, strDate, fileExt, sep = "")
    print(targetURL)
    response <- GET(url = targetURL, auth, write_disk(targetFile, overwrite = TRUE),
                    add_headers(`User-Agent` = "R Package (covidMex)",
                                `X-Package-Version` = as.character(packageVersion("covidMex")),
                                `X-R-Version` = R.version.string))
    # If server responds with an error
    if (status_code(response) > 399) {
      # If more than 5 tries, stop
      if (count > 5) {
        stop("The specified date (", parsedDatePar ,") is not available. The server responded with status code ", status_code(response),
             " (stopped because too many attempts)")
      }
      # Add one to try
      count <- count + 1
      # Warn user that we're trying yesterday's date
      warning("The specified date (", parsedDatePar ,") is not available. The server responded with status code ",
           status_code(response),
           ". Trying yesterday's date...")
      # ParsedDate minus one day
      parsedDatePar <- parsedDatePar - days(1)
      strDate <- format(parsedDatePar, "%Y-%m-%d")
    # Server responden with ok!
    } else {
      # If found a doc with today's date, stop while loop
      continue <- FALSE
      # read_excel throws a lot of ugly warnings and there's not any warning supression par >:(
      suppressWarnings({
        data <- read_excel(targetFile)
      })
      # User wants a clean version of the data
      if (neat) {
        # Create a copy of the data
        cleanData <- data
        # Use a tryCatch in case the columns names / order changes
        tryCatch(
          #Supress any warnings
          suppressWarnings({
            cleanData <- rename(cleanData, fecha_corte = 1,
                                dia = 2,
                                mes = 3,
                                anio = 4,
                                casos_nuevos = 5,
                                decesos = 6,
                                pais_territorio = 7,
                                geo_id = 8,
                                poblacion_2018 = 9)
            data <- cleanData
          }),
          # If error, only warn the user
          error = function(e) {
            warning("Cleaning data failed! Maybe a column was added/removed or changed. Please clean the returned data manually.\n", e)
          }
        )
      }
    } #end if
  } #end while
  return(data)
} #end function

#' Get Covid-19 Data From JHU CSSE
#'
#' Get Covid-19 situation report from the Johns Hopkins University Center for Systems Science and Engineering. This situation
#' report includes all countries in the world.
#'
#' @return A `tibble` with 12 columns:
#' FIPS code, City/County, State/Province, COuntry/Region, Date of Report, Lat, Long, Confirmed cases, Deaths,
#' Healed Cases, Active Cases, Full Geo Key.
#'
#' @param targetURL Target URL of the HTTP request. \code{character} vector of length 1.
#' @param filePrefix Target file prefix in GitHub repo. \code{character} vector of length 1.
#' @param fileExt Target file extension in GitHub repo. \code{character} vector of length 1.
#' @param date Date (version) of the report. \code{character} vector of length 1 or \code{Date} object.
#' #' If \code{character}, date must be in day/month/year format.
#' @param neat Should data be cleaned (dates, state name, column names)? \code{logical} vector of length 1.
#'
#'
#' @export
GetFromJHU <- function(targetURL = "https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_daily_reports/",
                       fileExt = ".csv",
                       date = "today",
                       neat = TRUE) {

  # First some type and value check
  if (!is.character(targetURL) | length(targetURL) > 1 ) {
    stop("'targetURL' par must be a character vector of length 1!")
  }
  if (!is.character(fileExt) | length(fileExt) > 1 ) {
    stop("'fileExt' par must be a character vector of length 1!")
  }
  if ((!is.Date(date) & !is.character(date)) | length(date) > 1) {
    stop("'date' par must be a date object or a character vector of length 1!")
  }

  # Try to parse date as date
  if (!is.Date(date)) {
    # If str = today use today's date, else use dmy
    if (date == "today") parsedDatePar <- today() else parsedDatePar <- dmy(date, quiet = T)
  } else {
    parsedDatePar <- date
  }

  # Define temp file path
  targetFile <- tempfile("covid19WW_", fileext = fileExt)

  # Try to get data from today's date
  continue <- TRUE
  count <- 1
  while (continue) {
    # Get character representation of the date
    strDate <- format(parsedDatePar, "%m-%d-%Y")
    # Make request and save response file in temp directory
    full_targetURL <- paste(targetURL, strDate, fileExt, sep = "")
    response <- GET(url = full_targetURL, write_disk(targetFile, overwrite = T),
                    add_headers(`User-Agent` = "R Package (covidMex)",
                                `X-Package-Version` = as.character(packageVersion("covidMex")),
                                `X-R-Version` = R.version.string))
    # If server responds with an error
    if (status_code(response) > 399) {
      # If more than 5 tries, stop
      if (count > 5) {
        stop("The specified date (", parsedDatePar ,") is not available. The server responded with status code ", status_code(response),
             " (stopped because too many attempts)")
      }
      # Add one to try count
      count <- count + 1
      # Warn user that we're using yesterday's date
      warning("The specified date (", parsedDatePar ,") is not available. The server responded with status code ",
              status_code(response),
              ". Trying yesterday's date...")
      # ParsedDate minus one
      parsedDatePar <- parsedDatePar - days(1)
      # Server responded ok
    } else {
      # If found a doc with today's date, stop while loop
      continue <- FALSE
      # read_excel throws a lot of ugly warnings and there's not any warning supression par >:(
      suppressWarnings({
        data <- read_csv(targetFile)
      })
      # User wants a clean version of the data
      if (neat) {
        # Create a copy of the data
        cleanData <- data
        # Use a tryCatch in case the columns names / order changes
        tryCatch(
          #Supress any warnings
          suppressWarnings({
            cleanData <- rename(cleanData, fips = 1,
                                ciudad_municipio = 2,
                                provincia_estado = 3,
                                pais_region = 4,
                                fecha_corte = 5,
                                latitud = 6,
                                longitud = 7,
                                positivos = 8,
                                decesos = 9,
                                recuperados = 10,
                                activos = 11,
                                key = 12)
            data <- cleanData
          }),
          # If error, only warn the user
          error = function(e) {
            warning("Cleaning data failed! Maybe a column was added/removed or changed. Please clean the returned data manually.\n", e)
          }
        )
      }
    } #end if
  } #end while

  return(data)
} #end function
