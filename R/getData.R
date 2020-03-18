#' Parse Serendipia's page with SARS-CoV-2 data in Mexico
#'
#' Parse Serendiía's page with SARS-CoV-2 data in Mexico.
#'
#' Mexico's Ministry of Health publishes, everyday,a report containing
#'
#' @import httr
#' @import rvest
#' @export

parseSerendipia <-
  function(targetURL = "https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/",
           targetClass = "a.wp-block-file__button") {

    # First some type and value check
    if (typeof(targetURL) != "character" | length(targetURL) > 1 ) {
      stop("'targetURL' par must be a character vector of length 1!")
    }
    if (typeof(targetClass) != "character" | length(targetClass) > 1 ) {
      stop("'targetClass' par must be a character vector of length 1!")
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

    # Get all DOM elements with the target class
    buttons <- rvest::html_nodes(x  = parsedResponse, css = targetClass)

    # Get href attr from DOM elements
    hrefs <- rvest::html_attr(x = buttons, name = "href", default = NA)

    return(hrefs)
}

