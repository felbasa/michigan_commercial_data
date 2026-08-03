# michigan_commercial_data

 Michigan Commercial Data (MSG) Processing

Commercial address-file (MSG) and vendor demographic data cleaning, merging with
Census/ACS benchmarks, and frame-coverage analysis for Case Study 2, Michigan SAE
survey research (NCSES-funded project).

## Overview
This pipeline takes a purchased commercial address list (MSG) and two linked vendor
demographic files, harmonizes them into an address-level analytic dataset, appends
ACS/Decennial neighborhood context, and evaluates how well the commercial frame
covers the Census-defined housing unit universe across the 9 target Michigan PUMAs.

The work proceeds in stages:
1. Download Census/ACS/Decennial reference variables and establish county–PUMA
   aggregation eligibility (Joy Wu's 1:1 / 1:n / n:1 / n:m classification).
2. Clean, recode, and widen the two vendor demographic files.
3. Merge vendor data onto the MSG address frame.
4. Join ACS/Decennial neighborhood context by tract/block-group FIPS.
5. Build block-group- and PUMA-level frame coverage DVs/IVs.
6. Compare MSG counts against ACS/Decennial benchmarks and test coverage
   systematicity against county characteristics.

Base files: `MI_PUMA_Sample.csv` (address frame), `Vendor1_Demos.csv`,
`Vendor2_Demos.csv` — purchased from Marketing Systems Group (MSG).

## Pipeline

| Stage | Folder | What it does |
|---|---|---|
| 0 | `data/` | Contains references to the datasets used in this analysis. They will not be included in the repository for privacy reasons |
| 0 | `00_reference/` | Codebooks, SAIPE/PUMS poverty benchmark; county–PUMA relationship classification |
| 1 | `01_data_preparation/` | ACS 5-yr + Decennial 2020 variable download (BG/tract/block) |
| 2 | `02_vendor_processing/` | Clean, recode, widen Vendor 1 (≤16 persons) & Vendor 2 (≤9 persons) |
| 3 | `03_address_frame_merge/` | Merge vendor data onto MSG address frame by MSGID |
| 4 | `04_census_merge/` | Join ACS/Decennial data by tract/block-group FIPS → `msg_addresses_wide` |
| 5 | `05_frame_coverage_dataset/` | Build BG- and PUMA-level frame coverage DVs/IVs |
| 6 | `06_coverage_analysis/` | MSG vs. Census benchmarking, PUMA aggregation, correlation analysis |


