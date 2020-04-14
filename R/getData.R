#' Get official data about Covid-19 cases in Mexico and the World
#'
#' Get official data about Covid-19 cases. User defines the report scope (Mexico or worldwide),
#' the type of report (confirmed or suspected cases), the version of the report (i.e. the date of publication),
#' and the data source. Please see details.
#'
#' Main data sources are Mexico's Federal Government Ministry of Health (Secretaría de Salud),
#' the European Centre for Disease Prevention and Control, and Johns Hopkins University Center for Systems Science and
#' Engineering. In the case of Mexico, although the main data source is the Federal Government Ministry of Health, there
#' are third parties that generate their own data by auditing and cleaning the official report.
#' Due to the wide variety of data sources and formats, not all parameter combinations are possible.
#' Please consider the following table. Each column is a valid parameter value given the data scope.
#'
#' \tabular{lcccc}{
#' Where (scope) \tab Source \tab Type \tab Date \tab Neat \cr
#' \code{Mexico} \tab \code{SSA} \tab \code{confirmed} \tab \code{today} \tab \code{TRUE}, \code{FALSE} \cr
#' \code{Mexico} \tab \code{Serendipia} \tab \code{confirmed}, \code{suspects} \tab \code{today} or any date from 15/03/2020 onwards. \tab \code{TRUE}, \code{FALSE} \cr
#' \code{Mexico} \tab \code{Guzmart} \tab \code{confirmed} \tab \code{today} or any date from 16/03/2020 to 06/04/2020 \tab \code{TRUE}, \code{FALSE} \cr
#' \code{worldWide} \tab \code{ECDC} \tab \code{confirmed} \tab \code{today} or any date from 01/01/2020 onwards. \tab \code{TRUE}, \code{FALSE} \cr
#' \code{worldWide} \tab \code{JHU} \tab \code{confirmed} \tab \code{today} or any date from 24/01/2020 onwards.\tab \code{TRUE}, \code{FALSE}
#' }
#'
#' For example, when requesting data for Mexico, you can either use \code{Serendipia}, \code{Guzmart} or \code{Mexico}
#' as \code{source} parameters. If you choose \code{Serendipia},
#' you can only use \code{type="confirmed"} and any date from from 16/03/2020 onwards.
#'
#' **WARNING: Data from \code{Guzmart} repository stopped daily updates on 06/04/2020. In future versions of this package, this source will be removed.**
#'
#' This functions is a wrapper for \code{\link{GetFromSerendipia}},
#' \code{\link{GetFromGuzmart}}, \code{\link{GetFromJHU}}, and \code{\link{GetFromECDC}}.
#'
#' @return A \code{tibble} with the requested data.
#'
#' @param where Scope of the report (Mexico or worldWide). \code{character} vector of length 1.
#' @param type Get confirmed (\code{confirmed}) or suspect (\code{suspects}) cases?. \code{character} vector of length 1.
#' @param date Date (version) of the published results. \code{character} vector of length 1 or \code{Date} object.
#' @param source Data source. \code{character} vector of length 1. Possible data sources are:
#' \code{Serendipia} (Mexico: confirmed, suspects), \code{Guzmart} (Mexico: confirmed), \code{JHU} (World Wide: confirmed),
#' and \code{ECDC} (World Wide: confirmed).
#' @param neat Should data be cleaned (dates, state name, column names)? \code{logical} vector of length 1.
#'
#' @import lubridate
#' @export

getData <- function(where, type, date, source, neat) {
  # First some type and value check
  if (!is.character(where) | length(where) > 1 ) {
    stop("'where' par must be a character vector of length 1!")
  }
  if (!is.character(type) | length(type) > 1 ) {
    stop("'type' par must be a character vector of length 1!")
  }
  if (!is.character(source) | length(source) > 1 ) {
    stop("'source' par must be a character vector of length 1!")
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

  # Define some functions. This makes code easier to read!
  # User wants data from mexico
  getMexicoData <- function() {
    # User can choose between data sources
    # Serendipia and Guzmart are available
    # User asked for Serendipia as data source
    if (tolower(source) == "serendipia") {
      data <- covidMex::GetFromSerendipia(type = type, date = parsedDatePar, neat = neat)
      # User asked for Guzmart GitHub page as data source
    } else if (tolower(source) == "guzmart") {
      # Guzmart has no suspect cases data :(
      if (type == "suspects") {
        stop("Sorry! The suspects cases table is only available in Serendipia's data page. Please use source='Serendipia'")
      }
      data <- covidMex::GetFromGuzmart(date = parsedDatePar, neat = neat)
    } else {
      stop("Unknown data source! Available data sources for Mexico's official report: 'Serendipia', 'Guzmart'")
    }
    return(data)
  }
  # User wants data from other parts of the world
  getWorldWideData <- function() {
    # User can choose between data sources
    # JHU and ECDC are available
    # User asked for JHU as data source
    if (tolower(source) == "jhu") {
      if (type == "suspects") {
        stop("Sorry! The suspects cases table is not available for the world wide report'")
      }
      data <- covidMex::GetFromJHU(date = parsedDatePar, neat = neat)
      # User asked for Guzmart GitHub page as data source
    } else if (tolower(source) == "ecdc") {
      # Guzmart has no suspect cases data :(
      if (type == "suspects") {
        stop("Sorry! The suspects cases table is not available for the world wide report'")
      }
      data <- covidMex::GetFromECDC(date = parsedDatePar, neat = neat)
    } else {
      stop("Unknown data source! Available data sources for world wide situation report: 'JHU', 'ECDC'")
    }
    return(data)
  }

  #First, check if user wants Mexico or worldwide
  if (where == "Mexico") {
    data <- getMexicoData()
  } else if (where == "worldWide") {
    data <- getWorldWideData()
  }

  return(data)
}

#' Get official record of confirmed Covid-19 cases in Mexico
#'
#' Get official record of confirmed Covid-19 cases in Mexico. This is a wrapper for \code{\link{getData}} that downloads the most recent
#' official report (Mexico's Ministry of Health) of Covid-19 cases in the country.
#'
#' @return A \code{tibble} with 9 columns:
#' Case Number, State, Sex, Age, Symptoms Onset Date, COVID-19 Test Result, Country Visited,
#' Date of Arrival to Mexico, and Date when the case officialy registered.
#'
#' @export
covidConfirmedMx <- function() {
  data <- getData(where = "Mexico", type = "confirmed", date = "today", source = "SSA", neat = TRUE)
  return(data)
}

#' Get official record of suspected Covid-19 cases in Mexico
#'
#' Get official record of suspected Covid-19 cases in Mexico. This is a wrapper for \code{\link{getData}} that downloads the most recent
#' official report (Mexico's Ministry of Health) of suspected Covid-19 cases in the country.
#'
#' @return A \code{tibble} with 9 columns:
#' Case Number, State, County/Region, Sex, Age, Symptoms Onset Date, COVID-19 Test Result, Country Visited, and
#' Date of Arrival to Mexico.
#'
#' @export
covidSuspectsMx <- function() {
  data <- getData(where = "Mexico", type = "suspects", date = "today", source = "Serendipia", neat = TRUE)
  return(data)
}

#' Get last worldwide Covid-19 situation report
#'
#' Get last Covid-19 world wide situation report. This is a wrapper for \code{\link{getData}} that downloads the most recent
#' situation report generated by the European Centre for Disease Prevention and Control.
#'
#' @export
covidWWSituation <- function() {
  data <- getData(where = "worldWide", type = "confirmed", date = "today", source = "ECDC", neat = TRUE)
  return(data)
}
