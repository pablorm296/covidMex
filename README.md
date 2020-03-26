covidMex
================

Un paquete para obtener datos oficiales sobre casos de Covid-19 en
México y el mundo. Creado por [Pablo
Reyes](https://twitter.com/pablorm296). Última actualizacion:
**2020-03-25 23:22:16**.

## Instalación :package:

Para instalar el paquete, es necesario usar `install_github`, pues el
paquete no está disponible en la CRAN.

``` r
devtools::install_github("pablorm296/covidMex")
```

## Uso :wrench:

### Básico

#### Casos sospechosos y confirmados en México

Para obtener el reporte oficial más reciente sobre los **casos
confirmados en México**, usa la función `covidConfirmedMx`. Para obtener
el reporte oficial más reciente sobre los **casos sospechosos en
México**, usa la función `covidSuspectsMx`.

``` r
library(covidMex)

# Descargar reporte de casos sospechosos
sospechosos <- covidSuspectsMx()

# Descargar reporte de casos confirmados
confirmados <- covidConfirmedMx()
```

#### Situación en resto del mundo

Para obtener el reporte más reciente sobre **casos y defunciones en el
mundo**, usa la función `covidWWSituation`.

``` r
# Descargar reporte de casos y defunciones en el mundo
casosCovidMundo <- covidWWSituation()
```

### Avanzado

#### Obtener reportes específicos

`covidConfirmedMx`, `covidSuspectsMx` y `covidWWSituation` son
[*wrappers*](https://stat.ethz.ch/pipermail/r-help/2008-March/158393.html)
de `getData`.

La función `getData` te permite descargar un reporte oficial específico.
Con el parámetro `where` especificas el ámbito del reporte (México o el
resto del mundo). Con el parámetro `type` puedes especificar el tipo de
reporte a cargar (casos confirmados o casos sospechosos). Con el
parámetro `date` especificas la versión del reporte (fecha en que fue
publicado). Si no se encuentra la fecha especificada, `getData`
intentará descargar el reporte del día anterior y notificará al usuario
por medio de una `warning`.

``` r
# Descargar reporte de casos sospechosos en México
sospechosos <- getData(where = "Mexico", type = "suspects", date = "today", 
                       source = "Serendipia", neat = TRUE)

# Descargar reporte de casos confirmados en México
confirmados <- getData(where = "Mexico", type = "confirmed", date = "today",
                       source = "Guzmart", neat = TRUE)

# Descarga una versión anterior del reporte
sospechosos_old <- getData(where = "Mexico", type = "confirmed", date = "16/03/2020", 
                           source = "Serendipia", neat = TRUE)

# Descarga reporte de situación en resto del mundo
casosCovidMundo <- getData(where = "worldWide", type = "confirmed", date = "today", 
                           source = "ECDC", neat = TRUE)
```

Seguro notaste que `getData` también acepta un parámetro `source`; éste
sirve para especificar la fuente de datos a cargar. Por el momento,
`getData` usa cuatro fuentes de datos:

1.  **Serendipia:**
    *[Serendipia](https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/)*,
    una iniciativa de periodismo de datos que ha publicado versiones
    .csv y .xlsx (creadas con
    [I:heart:PDF](https://www.ilovepdf.com/es)) de los reportes
    publicados por la Secretaría de Salud del Gobierno de México.
2.  **covid19\_mex:** Un [repositorio en
    GitHub](https://github.com/guzmart/covid19_mex) creado por [Katia
    Guzmán Martínez](https://twitter.com/guzmart_). Katia, además de
    convertirlo en formarto abierto, hace una revisión manual del
    reporte publicado por la Secretaría de Salud del Gobierno de México.
    Por esta razón, **esta fuente es la predeterminada al momento de
    descargar la tabla de casos confirmados para México.** Esta fuente
    de datos sólo tiene tabla de casos confirmados.
3.  **European Centre for Disease Prevention and Control**: La agencia
    de la Unión Europea encargada de la seguridad sanitaria. Además de
    publicar un reporte diario sobre casos de Covid-19 y defunciones en
    países europeos, el ECDC también empezó a publicar reportes de casos
    en todos los países del mundo independientes a los publicados por la
    Organización Mundial de la Salud. **Esta fuente es la predeterminada
    al momento de descargar la tabla de casos confirmados para el resto
    de países en el mundo.**
4.  **Johns Hopkins University Dashboard**: [Repositorio en
    GitHub](https://github.com/CSSEGISandData/COVID-19) con los datos
    mostrados en el [mapa
    interactivo](https://www.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6)
    del Johns Hopkins University Center for Systems Science and
    Engineering con datos de casos de Covid-19 en el mundo. La principal
    fuente de información de este repositorio son los datos publicados
    por la Organización Mundial de la Salud (OMS). Se incluyó esta
    fuente de datos porque es, sin duda alguna, uno de los repositorios
    más populares hasta el momento con datos de la pandemia. Sin
    embargo, los datos tienen múltiples problemas (registros incorrectos
    o desactualizados). Además, la OMS cambió su hora de corte el 15 de
    marzo de 2020, yuxtaponiendo casos correspondientes al día anterior.
    Esto comprometió las comparaciones entre datos antes y después de
    esa fecha. Por estas razones, el ECDC es la fuente predeterminada
    cuando se trata de datos para países del resto del mundo.

<!-- end list -->

``` r
# Descargar reporte de casos confirmados en México
# Usamos el repositorio de Katia
confirmados <- getData(where = "Mexico", type = "confirmed", date = "today",
                       source = "Guzmart", neat = TRUE)

# Descargar reporte de casos confirmados en México
# Esta vez, especificando que queremos usar el sitio de Serendipia
confirmados <- getData(where = "Mexico", type = "confirmed", date = "today",
                       source = "Serendipia", neat = TRUE)

# Descarga reporte de casos en el resto del mundo
# Especificamos que lo queremos desde el repositorio de la Johns Hopkins University
casosCovidMundo <- getData(where = "worldWide", type = "confirmed", date = "today", 
                           source = "JHU", neat = TRUE)
```

Adicionalmente, cada vez que el usuario cargue el paquete, un mensaje le
notificará las fuentes de datos disponibles:

``` r
library(covidMex)
```

    ## covidMex Package

    ## Version: 0.4.0

    ## Last Package Update: 19/03/2020

    ## Available Data Sources:

    ##     Confirmed Cases in Mexico: Serendipia, Guzmart

    ##     Suspect Cases in Mexico: Serendipia

    ##     WorldWide Situation Report: ECDC, JHU CSSE

El último parámetro de `getData` es `neat`. Este parámetro le informa a
la función si el usuario desea pre procesar el `tibble` obtenido de las
fuentes de datos, de manera que las fechas son tratadas como objetos
`Date`, los nombres de las entidades federativas se ponen en mayúscula y
los nombres de las columnas son transformados al estandar que maneja [el
repositorio de Katia Guzmán](https://github.com/guzmart/covid19_mex).
Puedes usar el parámetro `neat = FALSE` para obtener una versión *as is*
del reporte.

#### Una nota sobre los parámetros

Debido a la variedad de fuentes de datos y formatos en los que se
presentan estos, cuando usas `getData`, debes tener en cuenta que no
todas las combinaciones de parámetros son posibles. Por favor, toma en
cuenta la siguiente tabla. En ella, podras ver los parámetros válidos
dado un valor de
`where`.

| Where     | Source     | Type                | Date                                               | Neat        |
| --------- | ---------- | ------------------- | -------------------------------------------------- | ----------- |
| Mexico    | Serendipia | confirmed, suspects | today o cualquier fecha del 15/03/2020 en adelante | TRUE, FALSE |
| Mexico    | Guzmart    | confirmed           | today o cualquier fecha del 16/03/2020 en adelante | TRUE, FALSE |
| worldWide | ECDC       | confirmed           | today o cualquier fecha del 01/01/2020 en adelante | TRUE, FALSE |
| worldWide | JHU        | confirmed           | today o cualquier fecha del 24/01/2020 en adelante | TRUE, FALSE |

### Generando gráficas a partir de los datos

#### Edades de los infectados en México

``` r
covidConfirmedMx() %>%
  mutate(GrupoEdad = cut(edad, 
                         breaks = c(seq(0, 80, by = 10), Inf),
                         include.lowest = T)) %>%
  ggplot() +
  geom_bar(aes(x = GrupoEdad, y = ..count..), colour = "#CC7390", 
           fill = "#CC7390", alpha = 0.5, na.rm = T) +
  labs(x = "Grupo de Edad", y = "Casos",
       title = "¿Qué edad tienen los infectados de SARS-CoV-2 en México?") +
  theme_light() + 
  theme(text = element_text(family = "Quicksand Medium"),
        title = element_text(family = "Keep Calm Med"))
```

![](README_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

#### Evolución de número de casos en cinco países del mundo

## Fuentes de datos :books:

Por favor, si usas este paquete en publicaciones, cita el paquete y las
fuentes de datos.

Los datos de casos sospechosos y confirmados en México son publicados
por la Secretaría de Salud federal del gobierno mexicano:

  - Dirección General de Epidemiología, “Coronavirus (COVID-19):
    Comunicado técnico diario”,
    <https://www.gob.mx/salud/documentos/coronavirus-covid-19-comunicado-tecnico-diario-238449>,
    consultado el 25 de marzo de 2020.

Las versiones *plain text* de los reportes de la Secretaría de Salud
fueron publicadas originalmente en:

  - Redacción, “Datos abiertos sobre casos de Coronavirus COVID-19 en
    México”, en *Serendipia: Periodismo de datos*,
    <https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/>,
    consultado el 18 de marzo de 2020.

  - Katia Guzmán Martínez, “covid19\_mex: Publicación de datos oficiales
    (Secretaría de Salud) en formato amigable”, repositorio en *GitHub*,
    <https://github.com/guzmart/covid19_mex>, consultado el 18 de marzo
    de 2020.

Los datos del reporte situacional en el resto del mundo son publicados
por dos fuentes: el Centro Europeo para la Prevención y Control de
Enfermedades (ECDC) y el Johns Hopkins University Center for Systems
Science and Engineering.

  - European Centre for Disease Prevention and Control, “Download
    today’s data on the geographic distribution of COVID-19 cases
    worldwide”,
    <https://www.ecdc.europa.eu/en/publications-data/download-todays-data-geographic-distribution-covid-19-cases-worldwide>,
    consultado el 25 de marzo de 2020.

  - Johns Hopkins University Center for Systems Science and Engineering,
    “COVID-19: Novel Coronavirus (COVID-19) Cases”, repositorio en
    *GitHub*, <https://github.com/CSSEGISandData/COVID-19>, consultado
    el 25 de marzo de 2020.

## Build & Test Info :construction\_worker:

**Probado
en:**

| platform             | arch    | os        | system             | status | major | minor | year | month | day | svn.rev | language | version.string               | nickname             |
| :------------------- | :------ | :-------- | :----------------- | :----- | :---- | :---- | :--- | :---- | :-- | :------ | :------- | :--------------------------- | :------------------- |
| x86\_64-pc-linux-gnu | x86\_64 | linux-gnu | x86\_64, linux-gnu |        | 3     | 6.3   | 2020 | 02    | 29  | 77875   | R        | R version 3.6.3 (2020-02-29) | Holding the Windsock |

## Changelog :clipboard:

### 0.1.0 - 18/03/2020

#### Added

  - `getData` and `ParseSerendipia` functions.

### 0.2.0 - 19/03/2020

#### Fixed

  - Error when using `date` type object in `getData` (as `date`
    parameter).
  - DESCRIPTION and NAMESPACE file now has proper package dependencies
    (under CRAN rules).
  - DESCRIPTION file now has better package information (under CRAN
    rules). ALthough, some warnings and notes generated by `R CMD Check`
    remain unattended.
  - Typos in documentation.

#### Changed

  - README file. Better package description and functionality.
  - `ParseSerendipia` function renamed to `GetFromSerendipia`.
  - `getData`

#### Added

  - LICENSE file.
  - `GetFromGuzmart` function. This functions downloads data from Katia
    Guzman’s GitHub repo.
  - `"guzmart"` is now a valid `source` parameter value in `getData`
    function. Downloads data from Katia Guzman’s GitHub repo.

### 0.2.1 - 19/03/2020

#### Fixed

  - Fixed some minor typos in DESCRIPTION.
  - Changelog now included in README. TODO section moved to UNRELEASED
    in Changelog.
  - `onAttach` message fixed. It was not clear if the ‘last update’ info
    was about package or data.
  - Fixed out of date documentation of `getData` function.
  - Fixed some typos in function comments.

### 0.3.0 - 23/03/2020

#### Added

  - `covidSuspectsMx` and `covidConfirmedMx` functions. These are “super
    easy/fast to use” wrappers of `getData`.
  - Parameter `neat` in `getData`, `GetFromSerendipia`, and
    `GetFromGuzmart` functions. This parameter allows user to decide if
    some data cleaning is performed on the returned `tibbles` by
    `GetFromSerendipia` and `GetFromGuzmart`. Specially, proper date
    parsing and state name capitalizing.

#### Fixed

  - Typos in README and functions comments.

### 0.3.1 - 24/03/2020

#### Fixed

  - Serendipia updated data page, this broke scrapping routine. Changed
    CSS targets in `getFromSerendipia`.
  - In `getData`, `GetFromSerendipia`, and `GetFromGuzmart` `neat`
    parameter is now set to `FALSE` as default. This prevents errors
    when unexpected column names mess with clean routine.
  - Proper versioning in
DESCRIPTION.

## Licencia

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Licencia Creative Commons" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />Esta
obra está bajo una
<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Licencia
Creative Commons Atribución-NoComercial-CompartirIgual 4.0
Internacional</a>
