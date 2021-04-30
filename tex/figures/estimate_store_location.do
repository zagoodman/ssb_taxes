/**************************************************************************
Sorts stores into county code if zipcodes are not included

V1 6.17.19
**************************************************************************/



local owndir = "/data/sgps/Jake/"

global dirin = "`owndir'/HMS_data"
global dirin2 = "/data/sgps/Jake/sugar_tax"
global dirout = "/data/sgps/Jake/sugar_tax"


/****************************************************************************
1. Pulls in sample from raw data
*****************************************************************************/


use "$dirin/trips.dta" , clear

gen haszip = store_zip3 !=.

merge m:1 household_code panel_year using $dirin/panelists.dta, nogen

egen county = mode(fips_county_code), by(store_code_uc)
egen state = mode(fips_state_code), by(store_code_uc)


collapse (mean) county state, by(store_code_uc)

lab dat "created by estimate_store_location v 6.17.19 "

save $dirin2/store_location.dta, replace



