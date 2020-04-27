#' covidMex package startUp message
#'
#' @export
startUpMessage <- function() {
  packageStartupMessage("covidMex Package")
  packageStartupMessage(paste("Version:", packageVersion("covidMex")))
  packageStartupMessage("Last Package Update: 26/04/2020")
  packageStartupMessage("Available Data Sources:")
  packageStartupMessage("    Confirmed Cases in Mexico: Serendipia, SSA")
  packageStartupMessage("    Suspect Cases in Mexico: Serendipia")
  packageStartupMessage("    WorldWide Situation Report: ECDC, JHU CSSE")
}
