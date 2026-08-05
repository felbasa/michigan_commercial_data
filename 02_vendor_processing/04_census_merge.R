##### D. ACS and DHC Merge
library(dplyr)
library(janitor)
library(tidyr)
library(tidyverse)
library(stringr)

Address_Frame_Wide <- merged

dim(Address_Frame_Wide)
glimpse(Address_Frame_Wide)

acs_bg <-  read.csv("O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/acs_bg.csv")
acs_tr <- read.csv("O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/acs_tr.csv")
dec_bg <- read.csv("O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/dec_bg.csv" )
dec_block <- read.csv("O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/dec_block.csv")
dec_tr  <- read.csv("O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/dec_tr.csv")

address_frame_clean <- Address_Frame_Wide %>%
  mutate(
    fips_str = str_pad(as.character(fips), 5, pad = "0"),
    tract_str = str_pad(as.character(tract), 6, pad = "0"),
    fips_tract = paste0(fips_str, tract_str),
    fips_bg = paste0(fips_tract, str_pad(as.character(block), 1, pad = "0")),
    fips_block_group_digit = str_pad(as.character(block), 1, pad = "0")
  )


prepare_census <- function(df, level) {
  key_col <- case_when(
    level == "tract" ~ "fips_tract",
    level == "bg"    ~ "fips_bg",
    level == "block" ~ "fips_block"
  )
  
  df %>%
    mutate(!!key_col := str_pad(as.character(get(key_col)), 
                                width = if_else(level == "tract", 11, 
                                                if_else(level == "bg", 12, 15)), 
                                pad = "0")) %>%
    select(-any_of("NAME"))
}

acs_bg_proc    <- prepare_census(acs_bg, "bg")
acs_tr_proc    <- prepare_census(acs_tr, "tract")
dec_bg_proc    <- prepare_census(dec_bg, "bg")
dec_tr_proc    <- prepare_census(dec_tr, "tract")
dec_block_proc <- prepare_census(dec_block, "block")


merged_ABS_census_frame_wide <- address_frame_clean %>%
  
  # Join Block Group data (12-digit)
  left_join(acs_bg_proc, by = "fips_bg") %>%
  left_join(dec_bg_proc, by = "fips_bg") %>%
  
  # Join Tract data (11-digit)
  left_join(acs_tr_proc, by = "fips_tract") %>%
  left_join(dec_tr_proc, by = "fips_tract")


merged_ABS_census_frame_wide %>%
  select(fips, tract, block, fips_bg, everything()) %>%
  head()

head(merged_ABS_census_frame_wide)


names(merged_ABS_census_frame_wide)
# merged_ABS_census_frame_wide <- merged_ABS_census_frame_wide %>%
#   select(!c(
#     # X,
#     X.x,
#     X.y,
#     tract_str,
#     fips_str,
#     fips_tract,
#     fips_bg,
#     fips_block_group_digit
#   ))
dim(merged_ABS_census_frame_wide)


merged_ABS_census_frame_wide <- merged_ABS_census_frame_wide %>%
  mutate(
    Vendor1_in_HH = ifelse(!is.na(numadults_rec_v1), 1, NA),
    Vendor2_in_HH = ifelse(!is.na(numadults_rec_v2), 1, NA)
  )
sum(merged_ABS_census_frame_wide$Vendor1_in_HH == 1, na.rm = TRUE)# (Matches vendor 1 size)
#[1] 447990
sum(merged_ABS_census_frame_wide$Vendor2_in_HH == 1, na.rm = TRUE)# (Matches vendor 2 size)
# [1] 444104

max_p_values <- merged_ABS_census_frame_wide %>%
  select(msgid, matches("_\\d+(_rec)?_v[12]$")) %>%
  pivot_longer(
    cols = matches("_\\d+(_rec)?_v[12]$"),
    names_to = "var_name",
    values_to = "val",
    values_transform = list(val = as.character)
  ) %>%
  filter(!is.na(val)) %>%
  mutate(
    p_idx  = as.numeric(str_extract(var_name, "(?<=_)\\d+(?=(_rec)?_v[12]$)")),
    vendor = str_extract(var_name, "v[12]$")
  ) %>%
  group_by(msgid, vendor) %>%
  summarize(max_p = max(p_idx, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(
    names_from  = vendor,
    values_from = max_p,
    names_prefix = "Max_P_"
  )

msg_addresses_wide <- merged_ABS_census_frame_wide %>%
  left_join(max_p_values, by = "msgid") %>%
  mutate(
    Max_P_v1 = replace_na(Max_P_v1, 0),
    Max_P_v2 = replace_na(Max_P_v2, 0)
  )


write.csv(msg_addresses_wide, "C:/Users/felbasa/Downloads/NCSES MSG/msg_addresses_wide.csv")
msg_addresses_wide = read.csv("C:/Users/felbasa/Downloads/NCSES MSG/msg_addresses_wide.csv")