# prepare PHZH ILIAS data
#
# Authors: Flavian Imlig <flavian.imlig@bi.zh.ch>
# Date: 22.04.2020
###############################################################################

library(dplyr) # Version >= 0.8.5
library(assertthat) # Version >= 0.2.1
library(jsonlite)

# get and transform data
getData <- function()
{
    # get data from xlsx files
    data_full <- loadData()
    
    # get meta and specs
    meta <- getMetadata()
    
    df_spec <- readRDS(url('https://github.com/bildungsmonitoringZH/covid19_edu_mindsteps/raw/master/df_spec.rds'))
    
    # select most current value for each date
    data_s <- data_full %>%
        rename('date' := .data$slot_begin) %>%
        filter(.data$date >= '2019-08-01') %>%
        arrange(desc(.data$report_date)) %>%
        group_by(.data$date) %>%
        summarise('value' := first(.data$active_avg),
                  'variable_short' := meta$variable_short) %>%
        ungroup() %>%
        arrange(.data$date)
    
    # generate output data
    data <- data_s %>%
        left_join(meta, by = 'variable_short') %>%
        select(df_spec$name)
    
    return(data)
}

# download and load data
loadData <- function()
{
    files <- list.files(path = 'data_ilias', pattern = '^session.+\\d{8}.xlsx$', full.names = TRUE) %>%
        sort(decreasing = TRUE)
    
    data_full <- purrr::map_dfr(files, ~loadSingleData(.x))

    return(data_full)
}

loadSingleData <- function(file)
{
    data_full <- openxlsx::read.xlsx(xlsxFile = file,
                                     colNames = FALSE)
    
    data_date <- data_full$X2[str_which(data_full$X1, '^Datum des Reports$')] %>%
        str_replace(',.+', '') %>%
        lubridate::dmy()
    
    data_idx <- str_which(data_full$X1, '^active_min$')
    data_sessions <- openxlsx::read.xlsx(xlsxFile = file,
                                         startRow = data_idx) %>%
        mutate('slot_begin' := openxlsx::convertToDateTime(.data$slot_begin),
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
    
    meta_raw <- read_json(file, simplifyVector = F)
    meta_t <- lapply(meta_raw, as.character)
    meta <- as.data.frame(meta_t, stringsAsFactors = F)
    return(meta)
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