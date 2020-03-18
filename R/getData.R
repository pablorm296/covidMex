#' Get official data about Covid-19 cases in Mexico
#'
#' @import lubridate
#' @export

getData <- function(type = "confirmed", date = "today", source = "Serendipia") {
  # First some type and value check
  if (is.character(type) != "character" | length(type) > 1 ) {
    stop("'type' par must be a character vector of length 1!")
  }
  if (is.character(source) != "character" | length(source) > 1 ) {
    stop("'source' par must be a character vector of length 1!")
  }
  if (!is.Date(date) & !is.character(date) | length(date) > 1) {
    stop("'date' par must be a date object or a character vector of length 1!")
  }

  # Try to parse date as date
  if (!is.Date(date)) {
    # If str = today use today's date, else use dmy
    if (date = "today") parsedDate <- today() else parsedDate <- dmy(date, quiet = T)
  }

  # User can choose between data sources
  # As of v. 0.1.0, only Serendipia is available
  if (tolower(source) == "serendipia") {
    hrefs <- covidMex::parseSerendipia()
  } else {
    stop("Unknown data source! Available data sources: 'Serendipia'")
  }

}
