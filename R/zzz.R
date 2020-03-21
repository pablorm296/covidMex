.onAttach <- function(libname, pkgname) {
  packageStartupMessage("covidMex Package")
  packageStartupMessage("Version: 0.2.0")
  packageStartupMessage("Last Package Update: 19/03/2020")
  packageStartupMessage("Available Data Sources:")
  packageStartupMessage("    Confirmed Cases Table: Serendipia, Guzmart")
  packageStartupMessage("    Suspect Cases Table: Serendipia")
}
