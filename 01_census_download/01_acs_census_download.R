library(tidycensus)
library(purrr)
census_api_key("516c7983604dc923b2ece88255e4702446147e98", install = FALSE)

######################## helper functions ########################

get_acs_bg <- function(vars, states) {
  map_dfr(states, ~
            get_acs(
              geography = "block group",
              variables = vars,
              state     = .x,
              year      = 2024,
              survey    = "acs5",
              output    = "wide"
            )
  ) %>%
    rename(fips_bg = GEOID) %>%
    select(fips_bg, NAME, ends_with("E"))
}

get_acs_tr <- function(vars, states) {
  map_dfr(states, ~
            get_acs(
              geography = "tract",
              variables = vars,
              state     = .x,
              year      = 2024,
              survey    = "acs5",
              output    = "wide"
            )
  ) %>%
    rename(fips_tract = GEOID) %>%
    select(fips_tract, NAME, ends_with("E"))
}

get_acs_county <- function(vars, states) {
  map_dfr(states, ~
            get_acs(
              geography = "county",
              variables = vars,
              state     = .x,
              year      = 2024,
              survey    = "acs5",
              output    = "wide"
            )
  ) %>%
    rename(fips_tract = GEOID) %>%
    select(fips_tract, NAME, ends_with("E"))
}


get_dec_bg <- function(vars, states, sumfile = "dhc") {
  map_dfr(states, ~
            get_decennial(
              geography = "block group",
              variables = vars,
              state     = .x,
              year      = 2020,
              sumfile   = sumfile,
              output    = "wide"
            )
  ) %>%
    rename(fips_bg = GEOID) %>%
    select(fips_bg, NAME, all_of(names(vars)))
}

get_dec_block <- function(vars, states, sumfile = "pl") {
  map_dfr(states, ~
            get_decennial(
              geography = "block",
              variables = vars,
              state     = .x,
              year      = 2020,
              sumfile   = sumfile,
              output    = "wide"
            )
  ) %>%
    rename(fips_block = GEOID) %>%
    select(fips_block, NAME, all_of(names(vars)))
}

get_dec_tr <- function(vars, states, sumfile = "dhc") {
  map_dfr(states, ~
            get_decennial(
              geography = "tract",
              variables = vars,
              state     = .x,
              year      = 2020,
              sumfile   = sumfile,
              output    = "wide"
            )
  ) %>%
    rename(fips_tract = GEOID) %>%
    select(fips_tract, NAME, all_of(names(vars)))
}

# check for missing values (indicates that need a larger geography)
acs_bg  %>%
  summarise(across(everything(), ~mean(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "pct_missing") %>%
  filter(pct_missing > 0.3) %>%
  arrange(desc(pct_missing)) %>% print(n = 50)


state_fips <- vendors1_2_addresses_merged %>%
  mutate(state_fips = str_pad(as.character(fips), 5, pad = "0") %>% substr(1, 2)) %>%
  pull(state_fips) %>%
  unique()
# state_fips <- "13"


# ── E. ACS 2020-2024 ─────────────────────────────────────────────────────────
start_time_acs <- proc.time()

# Block group level
bg_housing <- get_acs_bg(c(
  hu_total_bg        = "B25001_001",
  occ_total_bg       = "B25002_001",
  occ_occupied_bg    = "B25002_002",
  occ_vacant_bg      = "B25002_003",
  tenure_total_bg    = "B25003_001",
  tenure_owned_bg    = "B25003_002",
  tenure_rented_bg   = "B25003_003",
  bldg_total_bg      = "B25024_001",
  bldg_1det_bg       = "B25024_002",
  bldg_1att_bg       = "B25024_003",
  bldg_2_bg          = "B25024_004",
  bldg_3_4_bg        = "B25024_005",
  bldg_5_9_bg        = "B25024_006",
  bldg_10_19_bg      = "B25024_007",
  bldg_20_49_bg      = "B25024_008",
  bldg_50plus_bg     = "B25024_009",
  bldg_mobile_bg     = "B25024_010",
  bldg_boat_rv_bg    = "B25024_011",
  avg_hh_size_bg     = "B25010_001",
  avg_hh_size_own_bg = "B25010_002",
  avg_hh_size_rnt_bg = "B25010_003",
  pop_in_hh_bg       = "B25008_001",
  pop_in_hh_own_bg   = "B25008_002",
  pop_in_hh_rnt_bg   = "B25008_003"
), state_fips)

bg_population <- get_acs_bg(c(pop_total_bg = "B01003_001"), state_fips)

bg_hhtype <- get_acs_bg(c(
  hht_total_bg              = "B11001_001",
  hht_family_bg             = "B11001_002",
  hht_married_couple_bg     = "B11001_003",
  hht_other_family_bg       = "B11001_004",
  hht_male_hh_nospouse_bg   = "B11001_005",
  hht_female_hh_nospouse_bg = "B11001_006",
  hht_nonfamily_bg          = "B11001_007",
  hht_nonfam_alone_bg       = "B11001_008",
  hht_nonfam_notalone_bg    = "B11001_009"
), state_fips)

bg_age_sex <- get_acs_bg(c(
  pop_total__bg   = "B01001_001",
  male_total_bg   = "B01001_002",
  male_u5_bg      = "B01001_003",  male_5_9_bg     = "B01001_004",
  male_10_14_bg   = "B01001_005",  male_15_17_bg   = "B01001_006",
  male_18_19_bg   = "B01001_007",  male_20_bg      = "B01001_008",
  male_21_bg      = "B01001_009",  male_22_24_bg   = "B01001_010",
  male_25_29_bg   = "B01001_011",  male_30_34_bg   = "B01001_012",
  male_35_39_bg   = "B01001_013",  male_40_44_bg   = "B01001_014",
  male_45_49_bg   = "B01001_015",  male_50_54_bg   = "B01001_016",
  male_55_59_bg   = "B01001_017",  male_60_61_bg   = "B01001_018",
  male_62_64_bg   = "B01001_019",  male_65_66_bg   = "B01001_020",
  male_67_69_bg   = "B01001_021",  male_70_74_bg   = "B01001_022",
  male_75_79_bg   = "B01001_023",  male_80_84_bg   = "B01001_024",
  male_85plus_bg  = "B01001_025",
  female_total_bg = "B01001_026",
  female_u5_bg    = "B01001_027",  female_5_9_bg   = "B01001_028",
  female_10_14_bg = "B01001_029",  female_15_17_bg = "B01001_030",
  female_18_19_bg = "B01001_031",  female_20_bg    = "B01001_032",
  female_21_bg    = "B01001_033",  female_22_24_bg = "B01001_034",
  female_25_29_bg = "B01001_035",  female_30_34_bg = "B01001_036",
  female_35_39_bg = "B01001_037",  female_40_44_bg = "B01001_038",
  female_45_49_bg = "B01001_039",  female_50_54_bg = "B01001_040",
  female_55_59_bg = "B01001_041",  female_60_61_bg = "B01001_042",
  female_62_64_bg = "B01001_043",  female_65_66_bg = "B01001_044",
  female_67_69_bg = "B01001_045",  female_70_74_bg = "B01001_046",
  female_75_79_bg = "B01001_047",  female_80_84_bg = "B01001_048",
  female_85plus_bg= "B01001_049"
), state_fips)

bg_race <- get_acs_bg(c(
  race_total_bg          = "B03002_001",
  race_nh_total_bg       = "B03002_002",
  race_nh_white_bg       = "B03002_003",
  race_nh_black_bg       = "B03002_004",
  race_nh_aian_bg        = "B03002_005",
  race_nh_asian_bg       = "B03002_006",
  race_nh_nhpi_bg        = "B03002_007",
  race_nh_other_bg       = "B03002_008",
  race_nh_multiracial_bg = "B03002_009",
  race_hispanic_bg       = "B03002_012"
), state_fips)

tr_asian_subgroups <- get_acs_tr(c(
  asian_total_tr       = "B02015_001",
  asian_indian_tr     = "B02015_003",
  asian_chinese_tr     = "B02015_004",
  asian_filipino_tr    = "B02015_005",
  asian_japanese_tr    = "B02015_006",
  asian_korean_tr      = "B02015_007",
  asian_vietnamese_tr  = "B02015_008",
  asian_other_tr       = "B02015_009",
  asian_two_or_more_tr = "B02015_010"
), state_fips)

bg_income <- get_acs_bg(c(
  median_hhincome_bg = "B19013_001",
  inc_total_bg       = "B19001_001",
  inc_lt10k_bg       = "B19001_002",  inc_10_15k_bg   = "B19001_003",
  inc_15_20k_bg      = "B19001_004",  inc_20_25k_bg   = "B19001_005",
  inc_25_30k_bg      = "B19001_006",  inc_30_35k_bg   = "B19001_007",
  inc_35_40k_bg      = "B19001_008",  inc_40_45k_bg   = "B19001_009",
  inc_45_50k_bg      = "B19001_010",  inc_50_60k_bg   = "B19001_011",
  inc_60_75k_bg      = "B19001_012",  inc_75_100k_bg  = "B19001_013",
  inc_100_125k_bg    = "B19001_014",  inc_125_150k_bg = "B19001_015",
  inc_150_200k_bg    = "B19001_016",  inc_200kplus_bg = "B19001_017"
), state_fips)

bg_poverty <- get_acs_bg(c(
  pov_total_bg        = "B17021_001",
  pov_below_bg        = "B17021_002",
  pov_below_family_bg = "B17021_003",
  pov_below_nonfam_bg = "B17021_014",
  pov_above_bg        = "B17021_019",
  pov_above_family_bg = "B17021_020",
  pov_above_nonfam_bg = "B17021_031"
), state_fips)

bg_education <- get_acs_bg(c(
  educ_total_bg          = "B15002_001",
  educ_m_total_bg        = "B15002_002",
  educ_m_noschl_bg       = "B15002_003",
  educ_m_nursery_4th_bg  = "B15002_004",
  educ_m_5th_6th_bg      = "B15002_005",
  educ_m_7th_8th_bg      = "B15002_006",
  educ_m_9th_bg          = "B15002_007",
  educ_m_10th_bg         = "B15002_008",
  educ_m_11th_bg         = "B15002_009",
  educ_m_12th_nodip_bg   = "B15002_010",
  educ_m_hs_ged_bg       = "B15002_011",
  educ_m_some_col_lt1_bg = "B15002_012",
  educ_m_some_col_gt1_bg = "B15002_013",
  educ_m_assoc_bg        = "B15002_014",
  educ_m_bach_bg         = "B15002_015",
  educ_m_masters_bg      = "B15002_016",
  educ_m_prof_bg         = "B15002_017",
  educ_m_phd_bg          = "B15002_018",
  educ_f_total_bg        = "B15002_019",
  educ_f_noschl_bg       = "B15002_020",
  educ_f_nursery_4th_bg  = "B15002_021",
  educ_f_5th_6th_bg      = "B15002_022",
  educ_f_7th_8th_bg      = "B15002_023",
  educ_f_9th_bg          = "B15002_024",
  educ_f_10th_bg         = "B15002_025",
  educ_f_11th_bg         = "B15002_026",
  educ_f_12th_nodip_bg   = "B15002_027",
  educ_f_hs_ged_bg       = "B15002_028",
  educ_f_some_col_lt1_bg = "B15002_029",
  educ_f_some_col_gt1_bg = "B15002_030",
  educ_f_assoc_bg        = "B15002_031",
  educ_f_bach_bg         = "B15002_032",
  educ_f_masters_bg      = "B15002_033",
  educ_f_prof_bg         = "B15002_034",
  educ_f_phd_bg          = "B15002_035"
), state_fips)

bg_lep <- get_acs_bg(c(
  lep_total_bg             = "B16004_001",
  lep_eng_only_bg          = "B16004_003",
  lep_span_verywell_bg     = "B16004_005",  lep_span_well_bg         = "B16004_006",
  lep_span_notwell_bg      = "B16004_007",  lep_span_notatall_bg     = "B16004_008",
  lep_indoeuro_verywell_bg = "B16004_010",  lep_indoeuro_well_bg     = "B16004_011",
  lep_indoeuro_notwell_bg  = "B16004_012",  lep_indoeuro_notatall_bg = "B16004_013",
  lep_asian_verywell_bg    = "B16004_015",  lep_asian_well_bg        = "B16004_016",
  lep_asian_notwell_bg     = "B16004_017",  lep_asian_notatall_bg    = "B16004_018",
  lep_other_verywell_bg    = "B16004_020",  lep_other_well_bg        = "B16004_021",
  lep_other_notwell_bg     = "B16004_022",  lep_other_notatall_bg    = "B16004_023"
), state_fips)


bg_language <- get_acs_tr(c(
  lang_total_bg        = "B16001_001",
  lang_english_only_bg = "B16001_002",
  lang_spanish_bg      = "B16001_003",
  lang_french_bg       = "B16001_006",
  lang_haitian_bg      = "B16001_009",
  lang_italian_bg      = "B16001_012",
  lang_portuguese_bg   = "B16001_015",
  lang_german_bg       = "B16001_018",
  lang_russian_bg      = "B16001_024",
  lang_polish_bg       = "B16001_027",
  lang_chinese_bg      = "B16001_030",
  lang_tagalog_bg      = "B16001_036",
  lang_vietnamese_bg   = "B16001_042",
  lang_korean_bg       = "B16001_045",
  lang_japanese_bg     = "B16001_048",
  lang_arabic_bg       = "B16001_054",
  lang_hindi_bg        = "B16001_060",
  lang_other_bg        = "B16001_069"
), state_fips)

# Tract level — nativity, citizenship, and social programs
tr_nativity <- get_acs_tr(c(
  nativity_total_tr        = "B05012_001",
  nativity_native_tr       = "B05012_002",
  nativity_foreign_born_tr = "B05012_003"
), state_fips)

tr_citizenship <- get_acs_tr(c(
  cit_total_tr       = "B05001_001",
  cit_us_born_tr     = "B05001_002",
  cit_us_pr_born_tr  = "B05001_003",
  cit_us_abroad_tr   = "B05001_004",
  cit_naturalized_tr = "B05001_005",
  cit_noncitizen_tr  = "B05001_006"
), state_fips)

tr_social <- get_acs_tr(c(
  snap_total_tr         = "B22010_001",
  snap_received_tr      = "B22010_002",
  snap_not_received_tr  = "B22010_007",
  pubassist_total_tr    = "B19057_001",
  pubassist_received_tr = "B19057_002",
  pubassist_not_tr      = "B19057_003",
  ssi_total_tr          = "B19055_001",
  ssi_received_tr       = "B19055_002",
  ssi_not_tr            = "B19055_003"
), state_fips)

elapsed_acs <- proc.time() - start_time_acs
cat("ACS download time:", round(elapsed_acs["elapsed"] / 60, 2), "minutes\n")

# ACS block group
acs_bg <- bg_housing %>%
  left_join(bg_population,      by = c("fips_bg", "NAME")) %>%
  left_join(bg_hhtype,          by = c("fips_bg", "NAME")) %>%
  left_join(bg_age_sex,         by = c("fips_bg", "NAME")) %>%
  left_join(bg_race,            by = c("fips_bg", "NAME")) %>%
  left_join(bg_income,          by = c("fips_bg", "NAME")) %>%
  left_join(bg_poverty,         by = c("fips_bg", "NAME")) %>%
  left_join(bg_education,       by = c("fips_bg", "NAME")) %>%
  left_join(bg_lep,             by = c("fips_bg", "NAME")) %>%
  left_join(bg_language,        by = c("fips_bg", "NAME"))

# ACS tract
acs_tr <- tr_nativity %>%
  left_join(tr_citizenship, by = c("fips_tract", "NAME")) %>%
  left_join(tr_social,      by = c("fips_tract", "NAME")) %>% 
  left_join(tr_asian_subgroups, by = c("fips_bg", "NAME")) 


# ── D. Decennial Census 2020 ──────────────────────────────────────────────────
start_time_dec <- proc.time()

# Block level
dec_block_hu_pop <- get_dec_block(c(
  dec_hu_total_block  = "H1_001N",
  dec_pop_total_block = "P1_001N"
), state_fips)

dec_block_race <- get_dec_block(c(
  dec_race_total_block = "P2_001N",
  dec_hispanic_block   = "P2_002N",
  dec_nh_total_block   = "P2_003N",
  dec_nh_white_block   = "P2_004N",
  dec_nh_black_block   = "P2_005N",
  dec_nh_aian_block    = "P2_006N",
  dec_nh_asian_block   = "P2_007N",
  dec_nh_nhpi_block    = "P2_008N",
  dec_nh_other_block   = "P2_009N",
  dec_nh_multi_block   = "P2_010N"
), state_fips)

# Block group level
dec_bg_vacancy <- get_dec_bg(c(
  dec_occ_total_bg    = "H3_001N",
  dec_occ_occupied_bg = "H3_002N",
  dec_occ_vacant_bg   = "H3_003N"
), state_fips)

dec_bg_hhpop <- get_dec_bg(c(
  dec_pop_in_hh_bg = "H8_001N"
), state_fips)

dec_bg_hhsize <- get_dec_bg(c(
  dec_hh_size_total_bg = "H9_001N",
  dec_hh_size_1_bg     = "H9_002N",
  dec_hh_size_2_bg     = "H9_003N",
  dec_hh_size_3_bg     = "H9_004N",
  dec_hh_size_4_bg     = "H9_005N",
  dec_hh_size_5_bg     = "H9_006N",
  dec_hh_size_6_bg     = "H9_007N",
  dec_hh_size_7plus_bg = "H9_008N"
), state_fips)

dec_bg_tenure <- get_dec_bg(c(
  dec_tenure_total_bg  = "H10_001N",
  dec_tenure_owned_bg  = "H10_002N",
  dec_tenure_rented_bg = "H10_003N"
), state_fips)

dec_bg_hhtype <- get_dec_bg(c(
  dec_hht_total_bg             = "P16_001N",
  dec_hht_family_bg            = "P16_002N",
  dec_hht_married_couple_bg    = "P16_003N",
  dec_hht_married_no_kids_bg   = "P16_004N",
  dec_hht_married_with_kids_bg = "P16_005N",
  dec_hht_other_family_bg      = "P16_006N",
  dec_hht_nonfamily_bg         = "P16_007N",
  dec_hht_nonfam_alone_bg      = "P16_008N",
  dec_hht_nonfam_notalone_bg   = "P16_009N"
), state_fips)

dec_bg_sex <- get_dec_bg(c(
  dec_pop_total_bg    = "P3_001N",
  dec_male_total_bg   = "P3_002N",
  dec_female_total_bg = "P3_003N"
), state_fips)

dec_bg_race <- get_dec_bg(c(
  dec_race_total_dhc_bg = "P5_001N",
  dec_hispanic_dhc_bg   = "P5_002N",
  dec_nh_total_dhc_bg   = "P5_003N",
  dec_nh_white_dhc_bg   = "P5_004N",
  dec_nh_black_dhc_bg   = "P5_005N",
  dec_nh_aian_dhc_bg    = "P5_006N",
  dec_nh_asian_dhc_bg   = "P5_007N",
  dec_nh_nhpi_dhc_bg    = "P5_008N",
  dec_nh_other_dhc_bg   = "P5_009N",
  dec_nh_multi_dhc_bg   = "P5_010N"
), state_fips)

# Tract level — age by sex only available at tract in DHC
dec_tr_age <- get_dec_tr(c(
  dec_age_total_tr = "PCT12_001N",
  dec_m_total_tr   = "PCT12_002N",
  dec_m_u5_tr      = "PCT12_003N",
  dec_m_5_9_tr     = "PCT12_008N",
  dec_m_10_14_tr   = "PCT12_013N",
  dec_m_15_17_tr   = "PCT12_018N",
  dec_m_18_19_tr   = "PCT12_021N",
  dec_m_20_24_tr   = "PCT12_023N",
  dec_m_25_29_tr   = "PCT12_028N",
  dec_m_30_34_tr   = "PCT12_033N",
  dec_m_35_39_tr   = "PCT12_038N",
  dec_m_40_44_tr   = "PCT12_043N",
  dec_m_45_49_tr   = "PCT12_048N",
  dec_m_50_54_tr   = "PCT12_053N",
  dec_m_55_59_tr   = "PCT12_058N",
  dec_m_60_64_tr   = "PCT12_063N",
  dec_m_65_69_tr   = "PCT12_068N",
  dec_m_70_74_tr   = "PCT12_073N",
  dec_m_75_79_tr   = "PCT12_078N",
  dec_m_80_84_tr   = "PCT12_083N",
  dec_m_85plus_tr  = "PCT12_088N",
  dec_f_total_tr   = "PCT12_106N",
  dec_f_u5_tr      = "PCT12_107N",
  dec_f_5_9_tr     = "PCT12_112N",
  dec_f_10_14_tr   = "PCT12_117N",
  dec_f_15_17_tr   = "PCT12_122N",
  dec_f_18_19_tr   = "PCT12_125N",
  dec_f_20_24_tr   = "PCT12_127N",
  dec_f_25_29_tr   = "PCT12_132N",
  dec_f_30_34_tr   = "PCT12_137N",
  dec_f_35_39_tr   = "PCT12_142N",
  dec_f_40_44_tr   = "PCT12_147N",
  dec_f_45_49_tr   = "PCT12_152N",
  dec_f_50_54_tr   = "PCT12_157N",
  dec_f_55_59_tr   = "PCT12_162N",
  dec_f_60_64_tr   = "PCT12_167N",
  dec_f_65_69_tr   = "PCT12_172N",
  dec_f_70_74_tr   = "PCT12_177N",
  dec_f_75_79_tr   = "PCT12_182N",
  dec_f_80_84_tr   = "PCT12_187N",
  dec_f_85plus_tr  = "PCT12_192N"
), state_fips)

elapsed_dec <- proc.time() - start_time_dec
cat("Decennial download time:", round(elapsed_dec["elapsed"] / 60, 2), "minutes\n")

# Join decennial tables
dec_bg <- dec_bg_vacancy %>%
  left_join(dec_bg_hhpop,     by = c("fips_bg", "NAME")) %>%
  left_join(dec_bg_hhsize,    by = c("fips_bg", "NAME")) %>%
  left_join(dec_bg_tenure,    by = c("fips_bg", "NAME")) %>%
  left_join(dec_bg_hhtype,    by = c("fips_bg", "NAME")) %>%
  left_join(dec_bg_sex,       by = c("fips_bg", "NAME")) %>%
  left_join(dec_bg_race,  by = c("fips_bg", "NAME"))

dec_block <- dec_block_hu_pop %>%
  left_join(dec_block_race, by = c("fips_block", "NAME"))

dec_tr <- dec_tr_age

########## save all dataframes as csvs Change to new download location
# write.csv(acs_bg,    "O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/acs_bg.csv",    row.names = FALSE)
# write.csv(acs_tr,    "O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/acs_tr.csv",    row.names = FALSE)
# write.csv(dec_bg,    "O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/dec_bg.csv",    row.names = FALSE)
# write.csv(dec_block, "O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/dec_block.csv", row.names = FALSE)
# write.csv(dec_tr,    "O:/slteam/SMART/Sampling/3_HU/2_Input/MSG/2026 March/Data_Processing/dec_tr.csv",    row.names = FALSE)