covidMex
================

Un paquete para obtener datos oficiales sobre casos de Covid-19 en
México y el mundo. Creado por [Pablo
Reyes](https://twitter.com/pablorm296). Última actualizacion:
**2020-04-26 23:09:42**.

## Instalación :package:

Para instalar el paquete, es necesario usar `install_github`, pues el
paquete no está disponible en la CRAN.

``` r
devtools::install_github("pablorm296/covidMex")
```

## Uso :wrench:

### Básico

#### Datos abiertos de la Secretaría de Salud

Para obtener el último reporte oficial sobre casos de SARS-CoV-2 en
México, usa la función `covidOfficialMx`.

``` r
library(covidMex)

# Descargar reporte oficial de la SS (datos abiertos)
datos_abiertos <- covidOfficialMx()
```

#### Casos sospechosos y confirmados en México

En las primeras versiones de este paquete, sólo era posible examinar un
reporte de casos sospechosos y casos confirmados con un número limitado
de variables. Esto se debía a que la Secretaría de Salud del Gobierno
Federal publicaba estas dos tablas en formato PDF y sólo mediante
terceros era posible conseguir versiones en formato abierto (CSV, XLSX).
Afortunadamente, desde el 14 de abril de 2020, la Secretaría de Salud
comenzó a publicar un reporte en formato abierto más completo con
información de los casos a los que se les da seguimiento (véase arriba
el uso de `covidOfficialMx`).

Decidí mantener estas dos tablas de casos sospechosos y confirmados para
garantizar una continuidad en el formato de los datos y el
funcionamiento del código escrito con el paquete; esto facilitará su
comparación y análisis.

Para obtener el reporte de **casos confirmados en México**, usa la
función `covidConfirmedMx`. Para obtener el reporte sobre los **casos
sospechosos en México**, usa la función `covidSuspectsMx`.

``` r
# Descargar reporte de casos sospechosos
sospechosos <- covidSuspectsMx()

# Descargar reporte de casos confirmados
confirmados <- covidConfirmedMx()
```

#### Situación en resto del mundo

Para obtener el reporte más reciente sobre **nuevos casos y defunciones
en el mundo**, usa la función `covidWWSituation`.

``` r
# Descargar reporte de nuevos casos y defunciones en el mundo
casosCovidMundo <- covidWWSituation()
```

### Avanzado

#### Obtener reportes específicos

`covidConfirmedMx`, `covidSuspectsMx`, `covidOfficialMx` y
`covidWWSituation` son
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
# Descargar reporte en formato abierto de la secretaría de Salud
oficial <- getData(where = "Mexico", type = "suspects", date = "today", 
                   source = "SSA", neat = TRUE)

# Descargar reporte de casos sospechosos en México
sospechosos <- getData(where = "Mexico", type = "suspects", date = "today", 
                       source = "Serendipia", neat = TRUE)

# Descargar reporte de casos confirmados en México
confirmados <- getData(where = "Mexico", type = "confirmed", date = "today",
                       source = "Serendipia", neat = TRUE)

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

1.  **Secretaría de Salud**: Reporte en formato abierto del seguimiento
    que se da a los casos positivos y sospechosos de SARS-CoV-2 en
    México.
2.  **Serendipia:**
    *[Serendipia](https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/)*,
    una iniciativa de periodismo de datos que ha publicado versiones
    .csv y .xlsx (creadas con
    [I:heart:PDF](https://www.ilovepdf.com/es)) de los reportes
    publicados por la Secretaría de Salud del Gobierno de México.
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

Los usuarios de versiones anteriores notarán que la fuente `Guzmart` ya
no está en esta lista. Aunque aún se puede usar este paquete para
acceder a los reportes publicados en el [repositorio de Katia
Guzmán](https://github.com/guzmart/covid19_mex), usando `getData` o
`GetFromGuzmart`, **esta opción ha sido deprecada, pues el repositorio
dejó de recibir actualizaciones el 6 de abril de 2020**.

``` r
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

    ## Version: 0.5.0

    ## Last Package Update: 26/04/2020

    ## Available Data Sources:

    ##     Confirmed Cases in Mexico: Serendipia, SSA

    ##     Suspect Cases in Mexico: Serendipia

    ##     WorldWide Situation Report: ECDC, JHU CSSE

El último parámetro de `getData` es `neat`. Este parámetro le indica a
la función si el usuario desea pre procesar el `tibble` obtenido de las
fuentes de datos. En el caso del reporte oficial generado por la
Secretaría de Salud, `neat` convertirá en `factor` las variable y usará
el catálogo de valores adjunto al dataset.

#### Una nota sobre los parámetros

Debido a la variedad de fuentes de datos y formatos en los que se
presentan estos, cuando usas `getData`, debes tener en cuenta que no
todas las combinaciones de parámetros son posibles. Por favor, toma en
cuenta la siguiente tabla. En ella, podras ver los parámetros válidos
dado un valor de
`where`.

| Where     | Source     | Type                | Date                                                 | Neat        |
| --------- | ---------- | ------------------- | ---------------------------------------------------- | ----------- |
| Mexico    | Serendipia | confirmed, suspects | today o cualquier fecha del 15/03/2020 en adelante   | TRUE, FALSE |
| Mexico    | SSA        | confirmed           | today                                                | TRUE, FALSE |
| Mexico    | Guzmart    | confirmed           | today o cualquier fecha del 16/03/2020 al 06/04/2020 | TRUE, FALSE |
| worldWide | ECDC       | confirmed           | today o cualquier fecha del 01/01/2020 en adelante   | TRUE, FALSE |
| worldWide | JHU        | confirmed           | today o cualquier fecha del 24/01/2020 en adelante   | TRUE, FALSE |

### Generando gráficas a partir de los datos

#### Edades de los infectados en México

``` r
# Tabla de casos confirmados
covidConfirmedMx() %>% 
  # Asignar casos a grupos de edad (10 grupos; 0-10, 11-20, 19-30... 81-90, 90+)
  mutate(GrupoEdad = cut(edad, 
                         breaks = c(seq(0, 90, by = 10), Inf),
                         include.lowest = T)) %>%
  # ggplot!
  ggplot() +
  geom_bar(aes(x = GrupoEdad, y = ..count..), colour = "#CC7390", 
           fill = "#CC7390", alpha = 0.5, na.rm = T) +
  labs(x = "Grupo de Edad", y = "Casos",
       title = "¿Qué edad tienen los infectados de SARS-CoV-2 en México?") +
  theme_light() + 
  theme(text = element_text(family = "Quicksand Medium"),
        title = element_text(family = "Keep Calm Med"))
```

![](README_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->

#### Evolución de número de casos en cinco países del mundo

``` r
# Tabla de nuevos casos y muertes
covidWWSituation() %>%
  # Seleccionar países
  filter(pais_territorio %in% c("Mexico", "Spain", 
                                "Italy", "Brazil", 
                                "United_States_of_America")) %>%
  # Covertrr fechas en Date y cambiar guiones bajos en espacios
  mutate(fecha_corte = as.Date(fecha_corte), 
         pais_territorio = gsub("_", " ", pais_territorio, fixed = T)) %>%
  # Ordenar y agrupar
  arrange(pais_territorio, fecha_corte) %>%
  group_by(pais_territorio) %>%
  # Contar casos acumulados
  mutate(casos_acumulados = cumsum(casos_nuevos)) %>%
  # Eliminar observaciones vacías hasta encontrar el primer caso
  # Mantener filas a partir de la primer fila donde casos_nuevos != 0
  filter(row_number() >= min(row_number()[casos_acumulados > 100])) %>%
  # Días desde el primer caso y suma acumulada de casos
  mutate(dias_transcurridos = fecha_corte - fecha_corte[1L]) %>%
  # ggplot!
  ggplot(aes(x = dias_transcurridos, y = casos_acumulados, colour = pais_territorio)) + 
  # Líneas
  geom_line(size = 1.2, alpha = 0.7) +
  # Escalas
  scale_y_continuous(trans = "log2") +
  # Títulos
  labs(y = "log(Casos acumulados)", x = "Días transcurridos desde el caso N° 100",
       title = "¿Qué tan rápido se contagia el SARS-CoV-2?",
       subtitle = "Casos acumulados en cinco países desde que se confirmó el caso N° 100",
       colour = "País",
       caption = "Datos del Centro Europeo para la Prevención y Control de Enfermedades") +
  # Tema <3
  theme_light() + 
  theme(text = element_text(family = "Quicksand Medium"),
        title = element_text(family = "Keep Calm Med"))
```

![](README_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

## Fuentes de datos :books:

Por favor, si usas este paquete en publicaciones, cita el paquete y las
fuentes de datos.

Los datos de casos sospechosos y confirmados en México son publicados
por la Secretaría de Salud federal del gobierno mexicano:

  - Dirección General de Epidemiología, “Coronavirus (COVID-19):
    Comunicado técnico diario”,
    <https://www.gob.mx/salud/documentos/coronavirus-covid-19-comunicado-tecnico-diario-238449>,
    consultado el 26 de abril de 2020.
  - Dirección General de Epidemiología, “Datos abiertos”,
    <https://www.gob.mx/salud/documentos/datos-abiertos-152127>,
    consultado el 26 de abril de 2020.

Las versiones *plain text* de los reportes de la Secretaría de Salud
fueron publicadas originalmente en:

  - Redacción, “Datos abiertos sobre casos de Coronavirus COVID-19 en
    México”, en *Serendipia: Periodismo de datos*,
    <https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/>,
    consultado el 18 de marzo de 2020.

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
  - Proper versioning in DESCRIPTION.

### 0.4.0 - 26/03/2020

#### Fixed

  - Documentation typos.

#### Added

  - Now users can download global situation reports. Two datasources are
    offered: the European Centre for Disease Prevention and Control, and
    John Hopkins Univeristy Coronavirus Resource Center. This feature is
    available via the wrappers `getData`, `covidWWSituation` or via
    `GetFromECDC`, `GetFromJHU`.

### 0.5.0 - 26/04/2020

#### Fixed

  - Typos in documentation.
  - Better handling of errors when downloaded data has unexpected
    format.
  - `GetFromSerendipia` broke after changes in Serendipia’s report
    naming pattern. Now, function searches for date pattern; when found,
    looks for link to relevant file in nearby html nodes by matching
    some regex.

#### Deprecated

  - `GetFromGuzmart` is now deprecated, since the GitHub repo used as
    the data source stopped daily updates. **Will remove in future
    versions.** `GetFromSerendipia` and `getFromSSA` are the suggested
    replacements. Deprecation warnings placed in documentation
    (`getData`, `GetFromGuzmart`) and main function routine
    (`GetFromGuzmart`).

#### Changed

  - `GetFromSerendipia` is the default method for `covidConfirmedMx`
    wrapper.

#### Added

  - Official Mexico’s Ministry of Health (Secretaría de Salud) open
    dataset is now available. As any other data source, user can get
    data using `getData` or `covidOfficialMx` wrapper, or directly using
    `GetFromSSA`.
  - Included package tests to better bug identification.

### Unrelelased

  - Remove `GetFromGuzmart`, and `Guzmart` (`source` parameter in
    `getData`).
  - When `neat` parameter is used in `GetFromSSA`, include state and
    municipalities names.
  - Allow user to use `date` parameter in
`GetFromSSA`.

## Licencia

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Licencia Creative Commons" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />Esta
obra está bajo una
<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Licencia
Creative Commons Atribución-NoComercial-CompartirIgual 4.0
Internacional</a>
