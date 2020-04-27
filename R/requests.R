#' Get Covid-19 Data From Serendipia's page
#'
#' Get Covid-19 Data From Serendipia's page
#'
#' Mexico's Ministry of Health published a daily report containing data about
#' positive and suspected cases of Covid-19 cases in the country (Comunicado Técnico Diario). However, this report was published
#' as a PDF document, difficulting further analysis. Serendipia, a data based journalism initiative,
#' publishes CSV and XLSX versions of the official reports. This function makes a request to
#' Serendipia's Covid-19 data page and downloads the specified data table.
#'
#' As of 14/04/2020, Mexico's Ministry of Health started publishing an open format version of the official report on Covid-19 cases.
#' However, Serendipia continues to upload daily CSV files with the same variables as the previous PDF document. This aids in keeping
#' a consistent data logging, and facilitates intertemporal comparisons.
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
#' @importFrom lubridate is.Date today dmy days
#' @importFrom stringr str_match
#' @import httr
#' @import rvest
#' @export

GetFromSerendipia <-
  function(targetURL = "https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/",
           targetCSS = "table",
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
    if (!is.logical(neat) | is.na(neat) | length(neat) > 1) {
      stop("'neat' par must be a logical vector of length 1!")
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

    # Get all node elements with the target class (i.e. get all tables in page)
    tables <- html_nodes(x  = parsedResponse, css = targetCSS)

    # Get first table (contains covid data)
    tables <- tables[[1]]

    # Get all tr elements
    tableRows <- html_nodes(x = tables, css = "tr")

    # Get text from tablerows
    tableRowsText <- html_text(tableRows)[2:length(tableRows)]

    # Get links
    hrefs <- html_nodes(x = tableRows, css = "a")
    hrefs <- html_attr(x = hrefs, name = "href")

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
      pattern <- "positivos"
    # For suspect cases
    }  else if (type == "suspects") {
      pattern <- "sospechosos"
    } else {
      stop("Unknown data type! Available data types: 'confirmed' or 'suspects'")
    }

    # Try to get data from today's date
    continue <- TRUE
    count <- 1
    while (continue) {
      # Gen regex from date
      datePattern <- format(parsedDatePar, "(%Y.%m.%d)|(%d%m%Y)")
      # Match link list from date and type
      matchType <- grepl(pattern, tableRowsText, perl = T)
      matchDate <- grepl(datePattern, hrefs, perl =  T)
      matchFinal <- matchType & matchDate
      # Sum matchFinal
      # If result is equal to 0, then no match found
      if (sum(matchFinal) == 0) {
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
    targetURL <- hrefs[matchFinal]

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
      stop("The specified dataset is not available (Serendipia's server responded with status code ", status_code(response), ")")
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
            cleanData <- rename(cleanData, id_registro = 1,
                                ent = 2,
                                sexo = 3,
                                edad = 4,
                                fecha_inicio = 5,
                                identificado = 6)
            cleanData$ent <- str_to_title(cleanData$ent)
            cleanData$ent <- str_replace(cleanData$ent, "De", "de")
            cleanData$fecha_inicio <- as.Date(cleanData$fecha_inicio,
                                              format = "%d/%m/%Y")
            data <- cleanData
          }),
          # If error
          error = function(e) {
            warning("Cleaning data failed! Maybe a column was added/removed or changed. Please clean the returned data manually.")
          }
        )
      } else if (type == "confirmed") {
        # Make a copy of the data
        cleanData <- data
        # Use a tryCath in case any unexpect table content
        tryCatch(
          #Supress any warnings
          suppressWarnings({
            cleanData <- rename(cleanData, id_registro = 1,
                                ent = 2,
                                sexo = 3,
                                edad = 4,
                                fecha_inicio = 5,
                                identificado = 6)
            cleanData$ent <- str_to_title(cleanData$ent)
            cleanData$ent <- str_replace(cleanData$ent, "De", "de")
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
#' positive and suspected cases of Covid-19 cases in the country (Comunicado Técnico Diario). However, this report is published
#' as a PDF document, difficulting further analysis. Katia Guzman makes an open format
#' version of the report that it's also manually checked for errors and includes a column
#' with the date when the case was first registered in the official count.
#'
#' **WARNING: Data from \code{Guzmart} repository stopped daily updates on 06/04/2020. In future versions of this package, this source will be removed.**
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
#' @importFrom tibble tibble
#' @importFrom readr read_csv
#' @importFrom dplyr rename
#' @importFrom lubridate is.Date today dmy days
#' @import httr
#' @import rvest
#' @export

GetFromGuzmart <-
  function (targetURL = "https://github.com/guzmart/covid19_mex/raw/master/01_datos/",
            filePrefix = "covid_mex_",
            fileExt = ".xlsx",
            date = "today",
            neat = TRUE) {

    # First deprecation warning
    .Deprecated(
      new = "GetFromSerendipia",
      package = "covidMex",
      old = "GetFromGuzmart",
      msg = "Deprecation Warning: The repo source (guzmart/covid19_mex) stopped daily updates. In future versions, this source will be fully removed."
    )

    # Some type and value check
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
    if (!is.logical(neat) | is.na(neat) | length(neat) > 1) {
      stop("'neat' par must be a logical vector of length 1!")
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

#' Get Covid-19 Data From Mexico's Ministry of Health Open Data Node
#'
#' Get Covid-19 official report from Mexico's Ministry of Health open data node.
#'
#' Mexico's Ministry of Health released an open dataset with information about confirmed SARS-CoV-2 cases in the country.
#' This function makes a request to Mexico's Federal Government open data system to retrieve the dataset.
#' *Please keep in mind that this dataset, although official, may present some inconsistencies.*
#'
#' @return A `tibble` with 35 columns: \cr
#' 1. Report date, \cr
#' 2. Case ID,
#' 3. Type of facility where the case was registered (USMER facility / Non-USMER facility), \cr
#' 4. Institution in charge of the facility where the case was registered (Local Gov, Federal Gov, Red Cross, Army...), \cr
#' 5. State ID (where the the case was registered), \cr
#' 6. Patient's gender, \cr
#' 7. State ID (where the patient was born), \cr
#' 8. State ID (where the patient currently lives), \cr
#' 9. Municipality ID (where the patient currently lives), \cr
#' 10. Type of patient (hospitalized or home care), \cr
#' 11. Hospital admittance date (if applicable), \cr
#' 12. Symptoms onset date, \cr
#' 13. Date of death (if applicable), \cr
#' 14. The patient is/was intubated?, \cr
#' 15. The patient has/had been diagnosed with pneumonia? \cr
#' 16. Patient's age. \cr
#' 17. Is the patient Mexican or alien? \cr
#' 18. Is the patient pregnant? \cr
#' 19. Does the patiend speak an indigenous language? \cr
#' 20. The patient has/had been diagnosed with diabetes? \cr
#' 21. The patient has/had been diagnosed with COPD? \cr
#' 22. The patient has/had been diagnosed with Asthma? \cr
#' 23. The patient has/had been diagnosed with any form of immunosuppression? \cr
#' 24. The patient has/had been diagnosed with hypertension? \cr
#' 25. The patient has/had been diagnosed with any other comorbidities? \cr
#' 26. The patient has/had been diagnosed with obesity? \cr
#' 27. The patient has/had been diagnosed with any CDV? \cr
#' 28. The patient has/had been diagnosed with CKD? \cr
#' 29. The patient smokes? \cr
#' 30. The patient had contact with other SARS-CoV-2 confirmed cases? \cr
#' 31. SARS-CoV-2 test result (positive, negative, pending) \cr
#' 32. Is the patient an immigrant? \cr
#' 33. If immigrant, where did the patient came from? \cr
#' 34. Patient's nationality? \cr
#' 35. The patient is/was in ICU?
#'
#' @param targetURL Target URL of the HTTP request. \code{character} vector of length 1.
#' @param date Date (version) of the report. \code{character} vector of length 1 or \code{Date} object.
#' #' If \code{character}, date must be in day/month/year format.
#' @param neat Should data be cleaned (dates, state name, column names)? \code{logical} vector of length 1.
#'
#' @importFrom dplyr recode_factor mutate
#' @importFrom lubridate is.Date
#' @importFrom magrittr %>%
#' @import httr
#' @export
GetFromSSA <- function(targetURL = "http://187.191.75.115/gobmx/salud/datos_abiertos/datos_abiertos_covid19.zip",
                       date = "today",
                       neat = TRUE) {
  # First some type check on parameters
  if (!is.character(targetURL) | length(targetURL) > 1 ) {
    stop("'targetURL' par must be a character vector of length 1!")
  }
  if ((!is.Date(date) & !is.character(date)) | length(date) > 1) {
    stop("'date' par must be a date object or a character vector of length 1!")
  }
  if (!is.logical(neat) | is.na(neat) | length(neat) > 1) {
    stop("'neat' par must be a logical vector of length 1!")
  }

  # Throw a warning on parameter date (no version control)
  if (date != "today") {
    stop("Sorry! There's not a version control system for this report. Please use date = 'today' to download the most recent version available.")
  } else {
    warning("Please keep in mind that the official report on Covid-19 cases has not a version control system or whatsover, therefore it's still difficult to match a specific date to a version of the report. The latest version available will be downloaded (it can be from yesterday's).")
  }

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
    stop("The specified dataset is not available (Federal Government Open Data Server server responded with status code ", status_code(response), ")")
  }

  #Create a temp dir to unzip file
  targetDir <- tempdir()

  #Try to unzip the file
  tryCatch({
    suppressWarnings(
      unzip(targetFile, exdir = targetDir)
    )
  },
  # If error
  error = function(e) {
    stop("An error ocurred when unzipping the data file. Try again in a few seconds, maybe server is busy.")
  })

  # Find csv file
  dataFile <- list.files(path = targetDir, pattern = "*.csv", full.names = T)[1]

  # Read file. Use suppressWarnings to hide parsing failures. Use suppressMessages to hide read_csv messages
  suppressWarnings({
      data <- suppressMessages(read_csv(dataFile))
  })

  # User wants a clean version of the data
  if (neat) {
    tryCatch({
      suppressWarnings({
        cleanData <- data
        cleanData %>%
          mutate(ORIGEN = recode_factor(ORIGEN, `1` = "USMER", `2` = "Fuera de USMER", `99` = NA_character_),
                 SECTOR = recode_factor(SECTOR, `1` = "Cruz Roja", `2` = "DIF", `3` = "Estatal",
                                 `4` = "IMSS", `5` = "IMSS-Bienestar", `6` = "ISSSTE", `7` = "Municipal",
                                 `8` = "PEMEX", `9` = "Privada", `10` = "SEDENA", `11` = "SEMAR", `12` = "Federal",
                                 `13` = "Universitario", `99` = NA_character_),
                 SEXO = recode_factor(SEXO, `1` = "Femenino", `2` = "Masculino", `99` = NA_character_),
                 TIPO_PACIENTE = recode_factor(TIPO_PACIENTE, `1` = "Ambulatorio", `2` = "Hospitalizado", `99` = NA_character_),
                 INTUBADO = recode_factor(INTUBADO, `1` = "Sí", `2` = "No",
                                   `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 NEUMONIA = recode_factor(NEUMONIA,`1` = "Sí", `2` = "No",
                                   `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 NACIONALIDAD = recode_factor(NACIONALIDAD, `1` = "Mexicana", `2` = "Extranjero",
                                       `99` = NA_character_),
                 EMBARAZO = recode_factor(EMBARAZO, `1` = "Sí", `2` = "No",
                                   `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 HABLA_LENGUA_INDIG = recode_factor(HABLA_LENGUA_INDIG, `1` = "Sí", `2` = "No",
                                             `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 DIABETES = recode_factor(DIABETES, `1` = "Sí", `2` = "No",
                                   `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 EPOC = recode_factor(EPOC, `1` = "Sí", `2` = "No",
                               `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 ASMA = recode_factor(ASMA, `1` = "Sí", `2` = "No",
                               `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 INMUSUPR = recode_factor(INMUSUPR, `1` = "Sí", `2` = "No",
                                   `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 HIPERTENSION = recode_factor(HIPERTENSION, `1` = "Sí", `2` = "No",
                                       `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 OTRA_COM = recode_factor(OTRA_COM, `1` = "Sí", `2` = "No",
                                   `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 CARDIOVASCULAR = recode_factor(CARDIOVASCULAR, `1` = "Sí", `2` = "No",
                                         `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 OBESIDAD = recode_factor(OBESIDAD, `1` = "Sí", `2` = "No",
                                   `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 RENAL_CRONICA = recode_factor(RENAL_CRONICA, `1` = "Sí", `2` = "No",
                                        `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 TABAQUISMO = recode_factor(TABAQUISMO, `1` = "Sí", `2` = "No",
                                     `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 OTRO_CASO = recode_factor(OTRO_CASO, `1` = "Sí", `2` = "No",
                                    `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 RESULTADO = recode_factor(RESULTADO, `1` = "Positivo a SARS-CoV-2",
                                    `2` = "Negativo a SARS-CoV-2", `3` = "Pendiente"),
                 MIGRANTE = recode_factor(MIGRANTE, `1` = "Sí", `2` = "No",
                                   `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_),
                 UCI = recode_factor(UCI, `1` = "Sí", `2` = "No",
                              `97` = "No aplica", `98` = "Se ignora", `99` = NA_character_)
                 ) -> cleanData
        data <- cleanData
      })
    },
    # If error, only warn the user
    error = function(e) {
      warning("Cleaning data failed! Maybe a column was added/removed or changed. Please clean the returned data manually.\n", e)
    })
  }

  return(data)


}

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
#' @importFrom lubridate is.Date today dmy days
#' @importFrom dplyr rename
#' @import httr
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
  if (!is.logical(neat) | is.na(neat) | length(neat) > 1) {
    stop("'neat' par must be a logical vector of length 1!")
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
#' @importFrom lubridate is.Date today dmy days
#' @importFrom dplyr rename
#' @import httr
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
  if (!is.logical(neat) | is.na(neat) | length(neat) > 1) {
    stop("'neat' par must be a logical vector of length 1!")
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
