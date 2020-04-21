# explore xlsx data source on PHZH ILIAS data
#
# Authors: Flavian Imlig <flavian.imlig@bi.zh.ch>
# Date: 21.04.2020
###############################################################################

data_full <- openxlsx::read.xlsx(xlsxFile = file.path('data_ilias', 'session_statistics_20190422-20200421.xlsx'),
                                colNames = FALSE)

data_date <- data_full$X2[str_which(data_full$X1, '^Datum des Reports$')] %>%
    str_replace(',.+', '') %>%
    lubridate::dmy()

data_idx <- str_which(data_full$X1, '^active_min$')
data_sessions <- openxlsx::read.xlsx(xlsxFile = file.path('data_ilias', 'session_statistics_20190422-20200421.xlsx'),
                                startRow = data_idx) %>%
    mutate_at('slot_begin', ~openxlsx::convertToDateTime(.x)) %>%
    filter(.data$slot_begin < data_date)

range(data_sessions$slot_begin)

lm <- lm(active_max ~ active_avg, data = data_sessions)
summary(lm)

ggplot(data_sessions, aes(x = active_avg, y = active_max)) +
    geom_point() +
    stat_smooth(method = 'lm', colour = biplaR::getColorZH(2)[2]) +
    geom_abline(slope = lm$coefficients[2], intercept = lm$coefficients[1], colour = biplaR::getColorZH(1))

ggplot(data_sessions, aes(x = slot_begin)) +
    geom_line(aes(y = active_avg), colour = biplaR::getColourZH(1)) +
    geom_line(aes(y = active_max), colour = biplaR::getColourZH(2)[2])
