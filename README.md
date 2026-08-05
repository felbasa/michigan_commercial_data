# michigan_commercial_data

## Michigan Commercial Data (MSG) Processing

Commercial address-file (MSG) and vendor demographic data cleaning, merging with
Census/ACS benchmarks, and frame-coverage analysis for Case Study 2, Michigan SAE
survey research (NCSES-funded project).

## Overview

This pipeline takes a purchased commercial address list (MSG) and two linked vendor
demographic files, harmonizes them into an address-level analytic dataset, appends
ACS/Decennial neighborhood context, and evaluates how well the commercial frame
covers the Census-defined housing unit universe across the 9 target Michigan PUMAs —
at the county, PUMA, and block-group level, and (at the block-group level) against
satellite-derived building counts as well. Outputs also feed PUMA-level covariate
construction for small area estimation (SAE).

The work proceeds in stages:
1. Download Census/ACS/Decennial reference variables and establish county–PUMA
   aggregation eligibility (Joy Wu's 1:1 / 1:n / n:1 / n:m classification).
2. Clean, recode, and widen the two vendor demographic files, merge onto the MSG
   address frame, and join ACS/Decennial neighborhood context by tract/block-group FIPS.
3. Compare MSG counts against ACS/Decennial benchmarks at the county and PUMA level
   (`05_coverage_analysis.Rmd`), then build the block-group-level frame coverage
   dataset and test whether MSG/satellite discrepancies vary systematically with
   block-group characteristics (`06_frame_analysis.Rmd`).
4. Build PUMA-level MSG covariates for the SAE model.

Base files: `MI_PUMA_Sample.csv` (address frame), `Vendor1_Demos.csv`,
`Vendor2_Demos.csv` — purchased from Marketing Systems Group (MSG). The MSG address
file provides MSGID as the primary housing-unit identifier throughout, along with
FIPS, tract, block group, block, and coordinates used to link to imagery data from
the companion satellite building-detection repo.

## Pipeline

| Stage | Folder | File | What it does |
|---|---|---|---|
| — | `data/` | `mi_puma_county_indicator.xlsx`, `msgforsae_summary.csv` | Reference/summary files only — the full address-level and vendor CSVs are not included in the repository for privacy reasons |
| — | `docs/` | `Vendor1_DD.xlsx`, `Vendor2_DD.xlsx` | Vendor data dictionaries |
| 0 | `00_reference/` | `00_puma_county_mapping.Rmd` | Pulls SAIPE county-level poverty and ACS 1-yr PUMS poverty benchmark; builds the county–PUMA relationship classification (1:1 / 1:n / n:1 / n:m) used to determine PUMA-aggregation eligibility everywhere downstream |
| 1 | `01_census_download/` | `01_acs_census_download.R` | Downloads ACS 5-yr (block group/tract) and Decennial 2020 DHC/PL (block/block group/tract) variables via `tidycensus` |
| 2 | `02_vendor_processing/` | `02_vendor_processing.R` | Cleans, recodes, and widens Vendor 1 (≤16 persons/household: home value, year built, lifestyle segment, Hispanic origin, surname indicators, occupation) and Vendor 2 (≤9 persons/household: adds political affiliation, veteran status, single-parent/working-woman flags, voter registration) |
| 2 | `02_vendor_processing/` | `legacy_msg_vendor1_2.R` | Earlier all-in-one draft of vendor processing + frame merge + census merge, superseded by the split scripts in this folder; kept only for the streetview-extract snippet built for Yao |
| 2 | `02_vendor_processing/` | `03_address_frame_merge.R` | Merges the recoded Vendor 1/Vendor 2 files onto the MSG address frame (`MI_PUMA_Sample.csv`) by MSGID |
| 2 | `02_vendor_processing/` | `04_census_merge.R` | Joins ACS/Decennial block-group and tract data onto the merged address frame by FIPS key, producing `msg_addresses_wide` |
| 3 | `03_coverage_analysis/` | `05_coverage_analysis.Rmd` | County- and PUMA-level coverage: compares MSG counts against ACS/Decennial benchmarks, tests whether overcoverage tracks county characteristics, and aggregates to eligible PUMAs |
| 3 | `03_coverage_analysis/` | `06_frame_analysis.Rmd` | Block-group-level coverage: compares ACS, MSG, and satellite building counts across all 1,102 block groups and regresses discrepancies on block-group characteristics |
| 4 | `04_sae_covariate_prep/` | `07_sae_covariate_prep.Rmd` | Builds PUMA-level MSG covariates for the SAE model (`msgforsae.csv`) — lifestyle segment recoding, missingness rates by PUMA, average home value/income |

## Results

### County-level: MSG vs. Census coverage
MSG overcounts occupied households in all 19 study counties relative to both ACS
and Decennial benchmarks (occupied-unit ratios 1.08–1.89), while undercounting
total housing units in 5 counties (26013, 26035, 26063, 26071, 26083). The two
largest outliers on the occupied-unit comparison are counties 26131 (1.77–1.89) and
26083 (1.59–1.82), both smaller counties.

### County-level: is overcoverage systematic?
Occupied-unit overcoverage correlates most strongly with median household income
(r = −0.58) and negatively with Hispanic share (r = −0.35) and rental rate
(r = −0.25); poverty rate shows a modest positive correlation (r = 0.29).
Total-unit undercoverage instead correlates positively with rental rate (r = 0.54)
and is not negatively associated with income (r = 0.22). ACS and Decennial
occupied-unit benchmarks are highly consistent with each other (r = 0.96).

### PUMA-level summary
Restricted to "1:1" and "n:1" counties to avoid double-counting (15 of 19 study
counties, 4 of 9 PUMAs cleanly aggregable). Within-PUMA poverty variation is
statistically significant in 3 of 4 eligible PUMAs — even cleanly aggregable
PUMAs can mask meaningful county-level poverty differences.

### Block-group level: average counts by source
Across the 1,102 block groups in the 9 PUMAs, both MSG and satellite-derived
building counts exceed ACS totals on average, with the satellite measure showing
the larger gap:

| Measure | ACS (n=1,102) | MSG (n=1,102) | Satellite (n=1,099) |
|---|---|---|---|
| Total housing units | 535.15 | 545.35 | 621.37 |
| Occupied housing units | 452.63 | 485.14 | NA |

### Block-group level: discrepancy magnitude
MSG shows smaller average discrepancies from ACS than the satellite building counts
on total housing units — MSG's relative absolute difference (0.286) is about half
that of the satellite measure (0.582). Both sources tend to overcount relative to
ACS on average (positive signed relative difference).

### Block-group level: do discrepancies vary systematically?
Regressing each relative-difference measure on quintile-coded block-group
characteristics (R² 0.15–0.40 across models, strongest for the satellite relative
difference) shows two consistent predictors: **population size** (larger block
groups show smaller relative differences — MSG and satellite data are least
accurate in small-population block groups) and **% missing income in MSG data**
(block groups in the highest missingness quintile show the largest discrepancies).
Other covariates (% minority, % renter, % married-couple, % poverty, % 65+) show
more selective, source-specific associations; % under 18 shows none.

## Data and outputs
Code lives here; the full address-level and vendor CSVs stay on the network
drive (`O:\slteam\SMART\Sampling\3_HU\2_Input\MSG\`) and are not committed to
GitHub. Only small reference and summary files live in `data/`. Satellite
building-count comparisons used in `06_frame_analysis.Rmd` are sourced from the
companion `michigan_building_detection` repository.

## Setup
R packages: `tidyverse`, `tidycensus`, `censusapi`, `janitor`, `kableExtra`,
`googledrive`. Census API key required (`CENSUS_API_KEY` env var).

## Repository structure
