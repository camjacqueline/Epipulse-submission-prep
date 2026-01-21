# Clear the R environment
rm(list=ls())

# Load required libraries
library(dplyr)       # For data manipulation
library(readxl)      # To read Excel files
library(xlsx)        # To write Excel files (not used in this script but loaded)
library(lubridate)   # For date manipulation
require(openxlsx)    # Alternative library to read/write Excel files
library(stringr)     # For string manipulation

### Setting working directory
setwd("yourdirectory")

### Upload datasets
# DOexport: anonymized laboratory dataset
DOexport <- read_xlsx("yourfile", sheet = "Anonymisé")

# EpiPulseimport: template CSV for submission to EpiPulse
EpiPulseimport <- read.csv("Template_LEGIISO.csv", sep=",")

## Ensure EpiPulse template has enough rows to accommodate DOexport
EpiPulseimport <- EpiPulseimport %>% slice(nrow(DOexport))

#### Standardize sample type and determine sample origin
DOexport <- DOexport %>%
  mutate(
    `Type de prélèvement` = case_when(
      str_detect(`Type de prélèvement`, "Divers \\(voir ci-dessous\\)|divers \\(voir ci-dessous\\)") ~ "DIVERS",
      TRUE ~ `Type de prélèvement`
    ), 
    SampleOrigin = case_when(
      str_detect(`Type de prélèvement`, "crachats|Crachats|LBA|Abcès cervical|Souche clinique|souche clinique|Aspiration bronchique|aspiration bronchique|Aspiration trachéo_bronchique|aspiration trachéo_bronchique|DIVERS|Liquide pleural") ~ "HUMAN", 
      TRUE ~ "ENVIRONMENT"
    )
  )

##### Filter dataset for Legionella pneumophila isolates and valid ST results
DOexport <- DOexport %>%
  filter(str_detect(identification, "^LEGPNE\\d+/\\d+$|^LEGPNE\\d+$")) %>%
  filter(!is.na(as.numeric(ST)))

###### Optional: filter by date and/or sequence type (ST)
DOexport <- DOexport %>%
  filter(as.Date(`Date de prélèvement`, format = "%d/%m/%Y") > as.Date("2025-04-30"))

### Function to calculate age
calculate_age <- function(dob, sampling_date) {
  dob <- dmy(dob)  # Convert date of birth to Date
  sampling_date <- dmy(sampling_date)  # Convert sampling date to Date
  age <- as.integer(interval(dob, sampling_date) / years(1))  # Compute age in years
  return(age)
}

#### Update dataset with age and age groups, convert dates
DOexport <- DOexport %>%
  mutate(
    Age = calculate_age(DDN, `Date de prélèvement`),
    Agegroup = cut(
      Age, 
      breaks = c(-Inf, 9, 19, 29, 39, 49, 59, 69, 79, Inf),
      labels = c("Age00_09", "Age10_19", "Age20_29", "Age30_39","Age40_49","Age50_59","Age60_69","Age70_79","Age80+"),
      right = TRUE,
      ordered_result = TRUE
    ),
    `Date de prélèvement` = dmy(`Date de prélèvement`)  # Convert to Date format
  )

### Transform the serogroup variable based on identification
DOexport <- DOexport %>%
  mutate(
    serogroup = case_when(
      str_detect(identification, "^LEGPNE\\d+/\\d+$|^LEGPNE \\d+/\\d+$") ~ "LPNE_SGMIX", 
      TRUE ~ str_replace(identification, "^LEGPNE", "LPNE_SG")
    )
  )

# Populate the EpiPulse template with DOexport values
for (i in 1:nrow(DOexport)) {
  EpiPulseimport[i, 1]  = "LEGI"                        # Source
  EpiPulseimport[i, 2]  = "ISO"                         # Isolate type
  EpiPulseimport[i, 3]  = "FR"                          # Country
  EpiPulseimport[i, 5]  = "LEGIISO"                     # Lab name/code
  EpiPulseimport[i, 6]  = as.character(DOexport$`N° GLIMS CNR`[i])  # Lab ID
  EpiPulseimport[i, 7]  = "FR-LEGIISO"                  # Lab country/code
  EpiPulseimport[i, 8]  = as.character(DOexport$`Date de prélèvement`[i]) # Sample date
  EpiPulseimport[i, 10] = as.character(DOexport$Agegroup[i])            # Age group
  EpiPulseimport[i, 11] = as.character(DOexport$Sexe[i])                 # Sex
  EpiPulseimport[i, 18] = as.character(DOexport$SampleOrigin[i])         # Sample origin
  EpiPulseimport[i, 27] = as.character(DOexport$serogroup[i])            # Serogroup
  EpiPulseimport[i, 29] = "Illumina"                                      # Sequencing platform
  EpiPulseimport[i, 34] = as.character(DOexport$ST[i])                    # Sequence type
}

#### Update with previous month submissions
EnCours <- read.csv("October25_LEGIISO.csv", sep=";") %>%
  mutate(DateUsedForStatistics = as.Date(DateUsedForStatistics, format = "%d/%m/%Y"))

### Optional: filter on previously uploaded records
LastUpdate <- read.csv("Update251016_LEGIISO.csv", sep=";")  # Change filename as needed

EnCours <- EnCours %>%
  rbind(LastUpdate)

### Save updated file
write.table(EnCours, file = "December25_LEGIISO.csv", sep = ";", row.names = FALSE, quote= FALSE, col.names = TRUE, na = "")

# Ensure NationalRecordId is character and pad missing zeros
EnCours$NationalRecordId <- as.character(EnCours$NationalRecordId)
EnCours <- EnCours %>%
  mutate(NationalRecordId = str_pad(NationalRecordId, width = 12, pad = "0", side = "left"))

# Remove records already in EnCours from the new submission
EpiPulseimport_filtered <- EpiPulseimport %>%
  anti_join(EnCours, by = "NationalRecordId")

### Save the filtered submission
write.table(EpiPulseimport_filtered, file = "Update260108_LEGIISO.csv", sep = ";", row.names = FALSE, quote= FALSE, col.names = TRUE, na = "")
