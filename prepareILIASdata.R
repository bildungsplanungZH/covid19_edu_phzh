# prepare PHZH ILIAS data
#
# Authors: Flavian Imlig <flavian.imlig@bi.zh.ch>
# Date: 4.04.2022
###############################################################################

library(dplyr) # Version >= 0.8.5
library(stringr)
library(assertthat) # Version >= 0.2.1
# library(jsonlite)

# get and transform data
getData <- function()
{
    # get data from xlsx files
    data_full <- loadData()
    
    # get meta, specs and exclusion data
    meta <- getMetadata()
    
    df_spec <- readRDS(url('https://github.com/bildungsmonitoringZH/covid19_edu_mindsteps/raw/master/df_spec.rds'))
    
    excl <- getExclData()
    
    # select most current value for each date
    data_s <- data_full %>%
        rename('date' := .data$slot_begin) %>%
        filter(.data$date >= '2019-08-01') %>%
        arrange(desc(.data$report_date)) %>%
        group_by(.data$date) %>%
        summarize('value' := dplyr::first(.data$active_avg),
                  'variable_short' := meta$variable_short) %>%
        ungroup() %>%
        arrange(.data$date)
    
    # combine with metadata
    data <- data_s %>%
        left_join(meta, by = 'variable_short') %>%
        select(df_spec$name)
    
    # eliminate values to exclude
    data$value[which(data$date %in% excl$date)] <- NA_integer_
    
    return(data)
}

# download and load data
loadData <- function()
{
    files <- list.files(path = 'data_ilias', pattern = '^session.+\\d{8}.(csv)$', full.names = TRUE) %>%
        sort(decreasing = TRUE)
    
    data_full <- purrr::map_dfr(files, ~loadSingleData(.x))

    return(data_full)
}

loadSingleData <- function(file)
{
    type <- str_extract(file, '\\w+$')
    assert_that(is.string(type))
    assert_that(noNA(type))
    
    data_full <- switch(type,
           'xlsx' = openxlsx::read.xlsx(xlsxFile = file, colNames = FALSE),
           'csv' = read.csv2(file, header = FALSE, encoding = 'UTF-8')) %>%
        rename_all(~str_replace(.x, '[a-zA-Z]+', 'X'))
    
    data_date <- data_full$X2[str_which(data_full$X1, '^Datum des Reports$')] %>%
        str_replace(',.+', '') %>%
        lubridate::dmy()
    
    data_idx <- str_which(data_full$X1, '^active_min')
    assert_that(is.number(data_idx))
    
    data_sessions <- switch(type,
                            'xlsx' = openxlsx::read.xlsx(xlsxFile = file,
                                         startRow = data_idx),
                            'csv' = read.csv2(file, skip = data_idx-1, stringsAsFactors = FALSE)) %>%
        mutate('slot_begin' := switch(type, 
                                      'xlsx' = lubridate::as_date(openxlsx::convertToDateTime(.data$slot_begin)),
                                      'csv' = lubridate::dmy_hm(.data$slot_begin)),
               'report_date' := data_date) %>%
        filter(.data$slot_begin < data_date)
    
    return(data_sessions)
}

# load metadata function
getMetadata <- function(file)
{
    if( missing(file) ) file <- 'data_ilias/ilias_meta.json'
    assert_that(is.string(file))
    assert_that(file.exists(file))
    
    meta_raw <- jsonlite::read_json(file, simplifyVector = F)
    meta_t <- lapply(meta_raw, as.character)
    meta <- as.data.frame(meta_t, stringsAsFactors = F)
    return(meta)
}

# load exclusion data function
getExclData <- function(file)
{
    if( missing(file) ) file <- file.path('data_ilias', 'ilias_exclusions.rds')
    assert_that(is.string(file))
    assert_that(file.exists(file))
    assert_that(str_detect(file, '\\.rds$'))
    
    excl_raw <- readRDS(file)
    excl <- excl_raw %>% tidyr::drop_na() %>% unique()
    
    assert_that(has_name(excl, 'date'))
    assert_that(lubridate::is.POSIXct(excl$date))
    
    return(excl)
    
    data_prep %>% filter(is.na(.data$value) | .data$value %in% 600L) %>%
        select(.data$date) %>%
        saveRDS(file)
}

# test result function
testTable <- function(df)
{
    df_spec <- readRDS(url('https://github.com/bildungsmonitoringZH/covid19_edu_mindsteps/raw/master/df_spec.rds'))
    
    assert_that(is(df, 'data.frame'))
    assert_that(identical(names(df), df_spec$name))
    
    purrr::pwalk(as.list(df_spec), ~assert_that(is(get(.x, df), .y)))
    
    return(invisible(NULL))
}

# main
data_prep <- getData()
# plot <- ggplot(data_prep, aes(x = date, y = value)) + geom_line()
test <- testTable(data_prep)
write.table(data_prep, "./Bildung_IliasNutzung.csv", sep=",", fileEncoding="UTF-8", row.names = F)
