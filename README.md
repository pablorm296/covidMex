covidMex
================

Un paquete para obtener datos oficiales sobre casos de Covid-19 en
México. Creado por [Pablo Reyes](https://twitter.com/pablorm296).
Última actualizacion: **Mon Mar 23 01:26:39 2020**

## Instalación :package:

Para instalar el paquete, es necesario usar `install_github`, pues el
paquete no está disponible en la CRAN.

``` r
devtools::install_github("pablorm296/covidMex")
```

## Uso :question:

### Básicos

Para obtener el reporte oficial más reciente sobre los **casos
confirmados** en México, usa la función `covidConfirmedMx`. Para obtener
el reporte oficial más reciente sobre los **casos sospechosos** en
México, usa la función `covidSuspectsMx`.

``` r
library(covidMex)

# Descargar reporte de casos sospechosos
sospechosos <- covidSuspectsMx()

# Descargar reporte de casos confirmados
confirmados <- covidConfirmedMx()
```

### Avanzado

Tanto `covidConfirmedMx` como `covidSuspectsMx` son
[*wrappers*](https://stat.ethz.ch/pipermail/r-help/2008-March/158393.html)
de `getData`. La función `getData` te permite descargar el reporte
oficial con unas cuantas opciones extras. Con el parámetro `type` puedes
especificar el tipo de reporte a cargar (casos confirmados o casos
sospechosos) y con el parámetro `date` especificas la versión del
reporte (fecha en que fue publicado). Por default, `getData` descargará
el reporte del día de casos confirmados (`type = "suspect", date =
"today"`). Si todavía no se publica el reporte diario, `getData`
descargará el reporte del día anterior y notificará al usuario por medio
de una `warning`.

``` r
library(covidMex)

# Descargar reporte de casos sospechosos
sospechosos <- getData(type = "suspect", source = "Serendipia")

# Descargar reporte de casos confirmados
confirmados <- getData(type = "confirmed")

# Descarga una versión anterior del reporte
sospechosos_old <- getData(type = "confirmed", date = "16/03/2020")
```

Por el momento, `getData` descarga los datos de dos fuentes:

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
    Por esta razón, esta fuente es la principal al momento de descargar
    la tabla de casos confirmados. **Esta fuente de datos sólo tiene
    tabla de casos confirmados**.

El usuario siempre puede especificar la fuente datos que desea usar con
el parámetro `source`, aunque por deafult, para casos confirmados se usa
el repositorio de Katia Guzmán y, para casos sospechosos, la página de
Serendipia

``` r
# Descargar reporte de casos confirmados 
# (Por defaul lo hará del repositorio de Katia)
confirmados <- getData(type = "confirmed")

# Descargar reporte de casos confirmados 
# (Podemos especificar que queremos el de Serendipia)
confirmados <- getData(type = "confirmed", source = "Serendipia")
```

Adicionalmente, cada vez que el usuario cargue el paquete, un mensaje le
notificará las fuentes de datos disponibles

``` r
library(covidMex)
```

    covidMex Package
    Versión: 0.2.0
    Last Update: 19/03/2020
    Available Data Sources:
        Confirmed Cases Table: Serendipia, Guzmart
        Suspect Cases Table: Serendipia

En próximas actualizaciones programaré un script que creará,
automaticamente, versiones .csv del reporte de SALUD y que serán
accesibles a partir de una API y de este paquete.

También debes tomar en cuenta que los datos devueltos por `getData`
**son pre procesados** de manera que las fechas son tratadas como
objetos `Date`, los nombres de las entidades federativas se ponen en
mayúscula y los nombres de las columnas son transformados al estandar
que maneja [el repositorio de Katia
Guzmán](https://github.com/guzmart/covid19_mex). Puedes usar el
parámetro `neat = FALSE` para obtener una versión *as is* del reporte.

### Generando gráficas a partir de los datos

``` r
covidConfirmedMx() %>%
  mutate(GrupoEdad = cut(edad, breaks = c(seq(0, 80, by = 10), Inf))) %>%
  ggplot() +
  geom_bar(aes(x = GrupoEdad, y = ..count..), colour = "#CC7390", 
           fill = "#CC7390", alpha = 0.5, na.rm = T) +
  labs(x = "Grupo de Edad", y = "Casos",
       title = "¿Qué edad tienen los infectados de SARS-CoV-2 en México?") +
  theme_light() + 
  theme(text = element_text(family = "Quicksand Medium"),
        title = element_text(family = "Keep Calm Med"))
```

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

## Fuentes

Las versiones *plain text* de los reportes de la Secretaría de Salud que
se usan en este paquete fueron publicadas originalmente en:

  - Redacción, “Datos abiertos sobre casos de Coronavirus COVID-19 en
    México”, en *Serendipia: Periodismo de datos*,
    <https://serendipia.digital/2020/03/datos-abiertos-sobre-casos-de-coronavirus-covid-19-en-mexico/>,
    consultado el 18 de marzo de 2020.

  - Katia Guzmán Martínez, “covid19\_mex: Publicación de datos oficiales
    (Secretaría de Salud) en formato amigable”, en *GitHub*, 16 de marzo
    de 2020, <https://github.com/guzmart/covid19_mex>, consultado el 18
    de marzo de 2020.

## Build & Test Info :construction\_worker:

**Probado
en:**

| platform             | arch    | os        | system             | status | major | minor | year | month | day | svn.rev | language | version.string               | nickname             |
| :------------------- | :------ | :-------- | :----------------- | :----- | :---- | :---- | :--- | :---- | :-- | :------ | :------- | :--------------------------- | :------------------- |
| x86\_64-pc-linux-gnu | x86\_64 | linux-gnu | x86\_64, linux-gnu |        | 3     | 6.3   | 2020 | 02    | 29  | 77875   | R        | R version 3.6.3 (2020-02-29) | Holding the Windsock |

## Changelog

### 0.1.0 - 18/03/2020

#### Added

  - `getData` and `ParseSerendipia` functions.

### 0.2.0 - 19/03/2020

#### Fixed

  - Error when using `date` type object in `getData` (as `date`
    parameter).
  - DESCRIPTION and NAMESPACE file now has propper package dependencies
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
    `GetFromSerendipia` and `GetFromGuzmart`. Specially, propper date
    parsing and state name capitalizing.

#### Fixed

  - Typos in README and functions
comments.

## Licencia

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Licencia Creative Commons" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />Esta
obra está bajo una
<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Licencia
Creative Commons Atribución-NoComercial-CompartirIgual 4.0
Internacional</a>
