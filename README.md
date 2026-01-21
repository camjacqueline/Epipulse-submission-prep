# EpiPulse LEGIISO Submission

## Project Overview
This repository contains an R workflow for preparing and submitting **Legionella pneumophila sequence data** to the EpiPulse system. The workflow includes data cleaning, transformation, age calculation, serogroup assignment, and generating submission-ready CSV files.

---

## Dependencies

The workflow uses the following R packages:

- `dplyr` – Data manipulation  
- `readxl` – Read Excel files  
- `xlsx` – Write Excel files (optional)  
- `openxlsx` – Alternative Excel read/write  
- `lubridate` – Date handling and age calculation  
- `stringr` – String processing  

Install dependencies if not already installed.

## Input Data
Place all input files in the data/ folder:

- Fichier global.xlsx – Anonymized laboratory dataset
- Template_LEGIISO.csv – EpiPulse submission template
- October25_LEGIISO.csv – Previous month submission
- Update251016_LEGIISO.csv – Optional historical updates


## Workflow

1. Load libraries and set working directory.
2. Import input datasets (DOexport and EpiPulseimport).
3. Clean and transform DOexport:
  - Standardize sample types
  - Assign sample origin (HUMAN vs ENVIRONMENT)
  - Filter for valid Legionella pneumophila isolates
  - Filter by collection date and sequence type (optional)
4. Calculate age and assign age groups.
5. Transform serogroup variables based on isolate ID.
6. Populate the EpiPulse submission template with transformed DOexport data.
7. Merge with previous submissions (EnCours) and remove duplicates.
8. Save filtered submission as Update260108_LEGIISO.csv.
9.Optional exports for verification.

## Output Files 
Generated outputs are saved in the output/ folder:
Update260108_LEGIISO.csv – Submission-ready file excluding duplicates

## How to Run

1. Open R or RStudio.
2. Set your working directory to the scripts/ folder.
3. Run the script:
4. Check the output/ folder for generated CSV files.

## Notes
Date formats in the Excel/CSV inputs must be dd/mm/yyyy.
Adjust optional filters (e.g., ST or date filtering) as needed.
NationalRecordId is padded to 12 digits to meet submission standards, adapt as needed.
