.onAttach <- function(libname, pkgname) {
  packageStartupMessage(covidMex::startUpMessage())
}
