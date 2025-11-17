# Data Source

The datasets in this application come from the CMS Provider Data Catalog, which is a repository of data from the Center of Medicare and Medicaid Services (CMS). Specifically, the data pertains to 30-day hospital mortality rates.

There are six (6) different diagnosis cohorts: AMI, CABG, COPD, HF, HIP-KNEE, PN

AMI = Acute myocardial infarction
CABG = Coronary artery bypass graft
COPD = Chronic obstructive pulmonary disease
HF = Heart failure
PN = Pneumonia
STK = Stroke

The specific datasets used are:

* [Hospital General Information](https://data.cms.gov/provider-data/dataset/xubh-q36u): Provides information on hospitals such as state, location, etc.
* [Complications and Deaths - Hospital](https://data.cms.gov/provider-data/dataset/ynj2-r877): Contains data for the hip/knee complication measure, the CMS Patient Safety Indicators, and 30-day death rates.

# Data Description For App

The dataset used in the application contains one row per hospital-diagnosis group combination, providing the program metrics for that diagnosis group for that hospital.

## Hospital information fields

These are the main fields of importance for identifying hospital-specific information in the dataset.

* A unique hospital is identified by the `FacilityID` field.
* The `FacilityName` is the hospital name
* The `Address` column provides the street address for the hospital
* The `City` column provides the city that the hospital resides
* The `County` column provides the county that the hospital resides
* The `Zip` column provides the zip code that the hospital resides

Keep in mind that a single hospital has multiple rows in the dataset (for each of the diagnosis groups they had program metrics for).

*Important Note:*: The hospital information fields are all in capital letters (all characters), so queries on this data should always capitalize all characters when searching for specific cities or counties.
