# 
# # Install packages required for the analysis.
# if (!require("pacman")) install.packages("pacman")
# pacman::p_load(data.table, rvest, dplyr, stringr)
# 
# test_link <- "https://www.willhaben.at/iad/immobilien/d/eigentumswohnung/wien/wien-1010-innere-stadt/prachtvolle-altbauwohnung-mit-blick-auf-das-naturhistorische-museum-in-1010-wien-zu-kaufen-314009082/?counterId=112"
# 
# test_result <- single_scrap(test_link)

single_scrap <- function(link){
  
  single_flat <- read_html(link)
  
  log <- data.table()
  
  # get the price
  log$price <- 
    single_flat %>%
    html_nodes("head") %>%
    html_nodes("title") %>%
    html_text() %>%
    str_extract(pattern = "(\u20AC) \\d{1,3}(\\.\\d{3})*") # find "Euro 4.995.000"
  
  # get willhaben-Code:
  log$id <- 
    single_flat %>% 
    html_nodes("span[id='advert-info-whCode']") %>%
    html_text() %>%
    unique() %>% 
    str_extract(pattern = "\\d+")
  
  # get last modified:
  log$last_modified <-
    single_flat %>% 
    html_nodes("span[id='advert-info-dateTime']") %>%
    html_text() %>%
    unique() %>% 
    str_extract(pattern = "(\\d+)\\.(\\d+)\\.(\\d+) (\\d+):(\\d+)")
  
  # get ad-title
  log$ad_title <-
    single_flat %>%
    html_nodes("head") %>%
    html_nodes("title") %>%
    html_text() %>% 
    str_extract("^(.*?),") %>% 
    str_replace(",", "")
  
  # retrieve the blue boxes from willhaben.
  # those boxes are currently:
  #  +) Objektinformation
  #  +) Ausstattung und Freifläche
  #  +) Energieausweis
  #  +) Objektbeschreibung
  #  +) Lage
  #  +) Ausstattung
  #  +) Zusatzinformationen
  #  +) Preis - Detailinformation
  all_boxes <- single_flat %>% html_nodes("[class='box-block ']") # class with exactly this name!
  
  
  # Objektinformation and Ausstattung und Freifläche are (always?!) double-columned
  # The bold text is extracted with:
  bold_text <- 
    all_boxes %>% 
    html_nodes(".col-2-desc") %>% 
    html_text() %>% 
    str_replace_all("\\r|\\n", "") %>%
    str_trim(side = "both")
  # The non-bold text is extracted with:
  simple_text <-
    all_boxes %>%
    html_nodes(".col-2-body") %>%
    html_text() %>% 
    str_replace_all("\\r|\\n", "") %>%
    str_trim(side = "both")
  
  # add the information extracted previously to the log 
  log[, (bold_text) := as.list(simple_text)]
  
  
  # save the living area as integer without dimensions
  log[, Wohnfl�che_raw := Wohnfl�che %>% str_extract("\\d+") %>% as.integer()]
  # save the price without Euro-Symbol and thousand-separators
  log[, price_raw := price %>% str_extract("\\d{1,3}(\\.\\d{3})*") %>% str_replace_all("\\.", "") %>% as.numeric()]
  # calculate the price per square meter
  log[, `price_per_square_meter`:= price_raw / Wohnfl�che_raw]
}
