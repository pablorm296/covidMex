#' Parse Serendipia's page with Covid-19 data in Mexico
#'
#' Parse Serendipia's page with Covid-19 data in Mexico.
#'
#' Mexico's Ministry of Health publishes a daily report containing data about
#' positive and suspected cases of Covid-19 cases in the country. However, the data is published
#' as a PDF document, difficulting further analysis. Serendipia, a data based journalism initiative,
#' publishes CSV and XLSX versions of the official reports. This function makes a request to
#' Serendipia's Covid-19 data page and parses the links that redirect to the data files.
#'
#' @return A character vector with the documents URL
#'
#' @param targetURL Target URL of the HTTP request. `character` vector of length 1.
#' @param targetCSS CSS selector of the nodes containing the data files URL. `character` vector of length 1.
#'
#' @import httr
#' @import rvest
#' @export

parseSerendipia <-
  function(targetURL = "https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/",
           targetCSS = "a.wp-block-file__button") {

    # First some type and value check
    if (is.character(targetURL) != "character" | length(targetURL) > 1 ) {
      stop("'targetURL' par must be a character vector of length 1!")
    }
    if (is.character(targetCSS) != "character" | length(targetCSS) > 1 ) {
      stop("'targetCSS' par must be a character vector of length 1!")
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

    return(hrefs)
}

