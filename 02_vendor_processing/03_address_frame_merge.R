library(dplyr)
library(tidyr)

setwd("C:/Users/felbasa/Downloads/NCSES MSG/")

########## C. MI_PUMA_Sample.csv ### 
mi_puma_sample_sel <- mi_puma_sample %>%
  rename_with(tolower) %>%
  select(
    primaryaddress, secondaryaddress, city, state, zip, 
    zip4, housenumber, predirectional, streetname, streetsuffix,  
    msgid,
    routetype,
    deliverypointusagecode,
    dropcount,
    seasonalcode,
    vacantcode,
    pumaid,
    fips,
    tract,
    blockgroup,
    block,
    latitude,
    longitude,
    dwellingtype
  )
names(mi_puma_sample_sel) <- tolower(names(mi_puma_sample_sel))
dim(mi_puma_sample_sel)
length(unique(mi_puma_sample_sel$msgid))

names(mi_puma_sample_sel)

# Add _v1 suffix to all vendor1 columns (except msgid)
names(vendor1_demos_final_recoded)[names(vendor1_demos_final_recoded) != "msgid"] <-
  paste0(names(vendor1_demos_final_recoded)[names(vendor1_demos_final_recoded) != "msgid"], "_v1")

# Add _v2 suffix to all vendor2 columns (except msgid)
names(vendor2_demos_final_recoded)[names(vendor2_demos_final_recoded) != "msgid"] <-
  paste0(names(vendor2_demos_final_recoded)[names(vendor2_demos_final_recoded) != "msgid"], "_v2")

merged <- mi_puma_sample_sel %>%
  left_join(vendor1_demos_final_recoded, by = "msgid") %>%
  left_join(vendor2_demos_final_recoded, by = "msgid")

length(unique(merged$msgid)) 
dim(merged)
names(merged)