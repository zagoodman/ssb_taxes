/*


Calculates Price index for Cook county and outside of cook county by month

Jacob Orchard


*/


clear
set more off

local owndir = "/data/sgps/Jake/"

global dirin = "`owndir'/HMS_data"
global dirin2 = "/data/sgps/Jake/sugar_tax"
global dirout = "/data/sgps/Jake/sugar_tax"



/*******************************************************************************
1. Prep data
********************************************************************************/

/*


use $dirin/purchases.dta, clear

merge m:1 trip_code using $dirin/trips.dta, keep(match) nogen


merge m:1 store_code_uc using $dirin2/store_location.dta, nogen


gen cook = 0
replace cook =1 if state == 17 & county == 031



gen month = mofd(purchase_date)


format month %tm

gen qtr = qofd(purchase_date)
format qtr %tq

rename total_price_paid price_orig
rename coupon_value couponv


gen double pq = price_orig - couponv



drop if pq ==0

merge  m:1 household_code panel_year using $dirin/panelists.dta, keep(match) nogen keepusing(projection_factor scantrack_market_identifier_cd  fips_county_code fips_state_code)
rename projection_factor pf
rename scantrack_market_identifier_cd scan_code

gen scan_p2016 = scan_code if panel_year < 2016

replace scan_code = 8 if scan_p2016 == 2

keep if scan_code == 8 //Keeps only Chicago Metropolitan Area

gen hh_cook = 0

replace hh_cook =1 if fips_state_code == 17 & fips_county_code == 031

*replace hh_cook = 2 if fips_state_code == 29 & (fips_county_code == 510 | fips_county_code == 189)

merge m:1 upc upc_ver_uc using $dirin/products.dta, keep(match) nogen keepusing(product_module_code multi size1_units size1_amount department_code brand_code_uc product_group_code)

* Unit size normalization (from adapted Kaplan and Menzio's code)
gen size1_units_orig = size1_units
tab size1_units
replace size1_units = "Cubic Foot" if size1_units == "CF"
replace size1_units = "Count" if size1_units == "CT"
replace size1_units = "Expired" if size1_units == "EXP"
replace size1_units = "Foot" if size1_units == "FT"
replace size1_units = "Liter" if size1_units == "LI"
replace size1_units = "Milliliter" if size1_units == "ML"
replace size1_units = "Ounce" if size1_units == "OZ"
replace size1_units = "Pound" if size1_units == "PO"
replace size1_units = "Quart" if size1_units == "QT"
replace size1_units = "Square Foot" if size1_units == "SQ FT"
replace size1_units = "Yard" if size1_units == "YD"

*collapse units
gen size1_amount_orig = size1_amount
replace size1_amount = size1_amount*16 if size1_units=="Pound"
replace size1_units = "Ounce" if size1_units=="Pound"
replace size1_amount = size1_amount*1000 if size1_units=="Liter"
replace size1_units = "Milliliter" if size1_units=="Liter"
replace size1_amount = size1_amount*3 if size1_units=="Yard"
replace size1_units = "Foot" if size1_units=="Yard"
replace size1_amount = size1_amount*946.353 if size1_units=="Quart"
replace size1_units = "Milliliter" if size1_units=="Quart"
replace size1_amount = size1_amount*957.506 if size1_units=="Cubic Foot"
replace size1_units = "Ounce" if size1_units=="Cubic Foot"
replace size1_amount = size1_amount*0.0338 if size1_units=="Milliliter"
replace size1_units = "Ounce" if size1_units=="Milliliter"

drop size1_units

rename product_module modcode
rename quantity qty
gen units=multi*size1_amount*qty

*Within Cook

save $dirout/temp/cookvoutside_sales.dta, replace

*/

use $dirout/temp/cookvoutside_sales.dta, clear

keep if hh_cook == 1



gen treattime = month < 695 & month > 690

replace pq = pq + units*.01 if cook == 1 & product_group_code == 1503 & treattime == 1

rename upc upc_org
gen upc=string(upc_org,"%17.0f") + string(upc_ver_uc)
destring upc,replace


collapse (sum) units pq  [w=pf], by(month upc modcode department_code ) fast 



bys upc month: gen Num = _N
by upc month: egen double max_exp =max(pq)
keep if pq == max_exp | Num == 1
bys upc month: gen num = _n
keep if num == 1
drop max_exp  Num num

gen unitprice = pq/units

rename pq exp 

destring upc,replace

egen tot_exp = sum(exp), by(month)
egen mod_exp = sum(exp), by( month modcode)
gen mod_share = mod_exp/tot_exp
gen upc_share = exp/mod_exp


sort upc month
gen cook = 1

save "$dirout/temp_cook.dta",replace



*Outside cook
use $dirout/temp/cookvoutside_sales.dta, clear

keep if hh_cook == 0

rename upc upc_org
gen upc=string(upc_org,"%17.0f") + string(upc_ver_uc)
destring upc,replace


collapse (sum) units pq  [w=pf], by(month upc modcode department_code ) fast 



bys upc month: gen Num = _N
by upc month: egen double max_exp =max(pq)
keep if pq == max_exp | Num == 1
bys upc month: gen num = _n
keep if num == 1
drop max_exp  Num num

gen unitprice = pq/units

rename pq exp 

destring upc,replace

egen tot_exp = sum(exp), by( month)
egen mod_exp = sum(exp), by( month modcode)
gen mod_share = mod_exp/tot_exp
gen upc_share = exp/mod_exp


sort upc month
gen cook = 0

save "$dirout/temp_outside.dta",replace



/******************************************************************************
2a. Share of soda purchases
******************************************************************************/

use $dirout/temp_cook.dta, clear
append using $dirout/temp_outside.dta
save $dirout/temp_cook_v_outside.dta, replace

*Soda Share
use "$dirout/temp_cook_v_outside.dta", clear

keep if modcode == 1484 | modcode == 1553 | modcode == 7743

collapse (mean) mod_share, by(modcode month cook)

keep if modcode == 1484
xtset cook month

label var mod_share "Soda budget share"

lab def cook 0 "Rest of Chicago Metropolitan Area" 1 "Cook County-Average"

lab val cook cook
xtline mod_share if month > ym(2016,1) , overlay graphregion(color(white)) bgcolor(white) xline(691, lcolor(red) ) xline(695,lcolor(red))


graph export $dirout/soda_budget_share.png, replace



*Diet Share
use "$dirout/temp_cook_v_outside.dta", clear

keep if modcode == 1484 | modcode == 1553 | modcode == 7743

collapse (mean) mod_share, by(modcode month cook)

keep if modcode == 1553
xtset cook month

label var mod_share "Diet-soda budget share"

lab def cook 0 "Rest of Chicago Metropolitan Area" 1 "Cook County-Average"

lab val cook cook
xtline mod_share if month > ym(2016,1) , overlay graphregion(color(white)) bgcolor(white) xline(691, lcolor(red) ) xline(695,lcolor(red))


graph export $dirout/diet_budget_share.png, replace



/******************************************************************************
2b. Soda Prices
******************************************************************************/


use "$dirout/temp_cook_v_outside.dta", clear

keep if modcode == 1484 | modcode == 1553 | modcode == 7743

collapse (mean) unitprice, by(modcode month cook)

keep if modcode == 1484
xtset cook month

label var unitprice "Soda Price"


lab def cook 0 "Rest of Chicago Metropolitan Area" 1 "Cook County-Average"


lab val cook cook
local taxbegin ym(2017,8)
local taxend ym(2017,12)
xtline unitprice if month > ym(2016,1)  , overlay graphregion(color(white)) bgcolor(white) xline(691, lcolor(red) ) xline(695,lcolor(red))




graph export $dirout/soda_price.png, replace










/******************************************************************************
3a. Laspeyres and Paasche by upc
*******************************************************************************/


*Laspeyres and Paasche for Non-cook

foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_outside.dta",clear
	
	*Keeps only common UPCS
	bys upc: gen number = _N
	keep if number == 2
	
	bys month: egen totexp = sum(exp)
	
	gen share = exp/totexp
	
	sort upc month
	by upc: gen laspeyres = share[_n-1]*(unitprice/unitprice[_n-1])
	by upc: gen paasche = share*(unitprice/unitprice[_n-1])
	drop if month ~= `x'
	collapse (sum) laspeyres paasche
	gen month = `x'
	rename laspeyres laspeyres_noncook
	rename paasche paasche_noncook
	
	save $dirout/temp/laspeyres_outside_`x'.dta, replace
	
	
	}
	
	use $dirout/temp/laspeyres_outside_540.dta, clear
	
	forval i = 541/707{
		append using $dirout/temp/laspeyres_outside_`i'.dta
	}
	
	gen llaspeyres_noncook = log(laspeyres_noncook)
	gen lpaasche_noncook = log(paasche_noncook)
	gen cum_laspeyres_noncook = exp(sum(llaspeyres_noncook))
	gen cum_paasche_noncook = exp(sum(lpaasche_noncook))
	save $dirout/temp/laspeyres_outside.dta, replace
	
*Laspeyres and Paasche for Cook

foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_cook.dta",clear
	
	
	*Keeps only common UPCS
	bys upc: gen number = _N
	keep if number == 2
	
	bys month: egen totexp = sum(exp)
	
	gen share = exp/totexp
	
	sort upc month
	by upc: gen laspeyres = share[_n-1]*(unitprice/unitprice[_n-1])
	by upc: gen paasche = share*(unitprice/unitprice[_n-1])
	drop if month ~= `x'
	collapse (sum) laspeyres paasche
	gen month = `x'
	rename laspeyres laspeyres_cook
	rename paasche paasche_cook
	save $dirout/temp/laspeyres_cook_`x'.dta, replace
	
	
	}

use $dirout/temp/laspeyres_cook_540.dta, clear
	
	forval i = 541/707{
		append using $dirout/temp/laspeyres_cook_`i'.dta
	}
	
	
	gen llaspeyres_cook = log(laspeyres_cook)
	gen lpaasche_cook = log(paasche_cook)
	gen cum_laspeyres_cook = exp(sum(llaspeyres_cook))
	gen cum_paasche_cook = exp(sum(lpaasche_cook))
	save $dirout/temp/laspeyres_cook.dta, replace



/******************************************************************************
3b. Sato-Vartia by Modcode
******************************************************************************/

*Sato-Vartia for Non-cook

foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_outside.dta",clear
	
	
	
	bys month month: egen sumexp = sum(exp)
	
	gen share = exp/sumexp
	
	sort upc month
	
	by upc: gen wtop = (share-share[_n-1])/(log(share)-log(share[_n-1]))
	egen wbottom = sum(wtop), by(modcode month)
	gen w = wtop/wbottom
	replace w = . if month ~= `x'
	
	by upc: gen sato = w*(unitprice/unitprice[_n-1])
	
	collapse (sum) sato, by(modcode)
	gen month = `x'
	
	save $dirout/temp/sato_outside_`x'.dta, replace
	
	
	}

*Sato-Vartia for Cook

foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_cook.dta",clear
	
	
	
	bys month month: egen sumexp = sum(exp)
	
	gen share = exp/sumexp
	
	sort upc month
	
	by upc: gen wtop = (share-share[_n-1])/(log(share)-log(share[_n-1]))
	egen wbottom = sum(wtop), by(modcode month)
	gen w = wtop/wbottom
	replace w = . if month ~= `x'
	
	by upc: gen sato = w*(unitprice/unitprice[_n-1])
	
	collapse (sum) sato, by(modcode)
	gen month = `x'
	
	save $dirout/temp/sato_cook_`x'.dta, replace
	
	
	}


/******************************************************************************
3c. CUPI estimation by modcode
******************************************************************************/






*CCG for Non-Cook
set more off
foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_outside.dta",clear
	
	
	di "here"
	bys upc: gen nmonth=[_N]
	keep if nmonth==2 // balanced
	di "here"
	bys month modcode: egen sumexp=sum(exp)
	di "here"
	gen share=exp/sumexp
	
	sort upc month
	xtset upc month
	di "here"
	bys modcode: gen N = _N/2 //Total number of common goods is total obs/2 (two quarters)
	
	sort upc month

	by upc: gen share_ratio = log(share/share[_n-1])
	replace share_ratio = . if month == `x'-1
	di "here2"
	by upc: gen price_ratio = log(unitprice/unitprice[_n-1])
	replace price_ratio = . if month == `x'-1
	di "ratio complete"
	
	drop if month == `x'-1
	
	collapse (mean) N (sum) share_ratio price_ratio, by(modcode) 
	di "after collapse"
	merge m:1 modcode  using "$dirin2/sigmasRW_month.dta", nogen keep(match)
	
	
	
	gen lCCG = (1/(N))* price_ratio + (1/(sigma-1))*(1/N)*share_ratio 
	
	gen month= `x'
	save "$dirin2/temp/CCG_noncook_`x'.dta",replace
	}
	
	
	
*CCG for Cook
set more off
foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_cook.dta",clear
	
	
	
	bys upc: gen nmonth=[_N]
	keep if nmonth==2 // balanced
	
	bys month modcode: egen sumexp=sum(exp)
	gen share=exp/sumexp
	
	sort upc month
	xtset upc month
	di "here"
	bys modcode: gen N = _N/2 //Total number of common goods is total obs/2 (two quarters)
	
	sort upc month

	by upc: gen share_ratio = log(share/share[_n-1])
	replace share_ratio = . if month == `x'-1
	di "here2"
	by upc: gen price_ratio = log(unitprice/unitprice[_n-1])
	replace price_ratio = . if month == `x'-1
	di "ratio complete"
	
	drop if month == `x'-1
	
	collapse (mean) N (sum) share_ratio price_ratio, by(modcode) 
	di "after collapse"
	merge m:1 modcode  using "$dirin2/sigmasRW_month.dta", nogen keep(match)
	
	
	
	gen lCCG = (1/(N))* price_ratio + (1/(sigma-1))*(1/N)*share_ratio 
	
	gen month= `x'
	save "$dirin2/temp/CCG_cook_`x'.dta",replace
	}
	
	
	
	

*Variety Term Non-Cook
foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_outside.dta",clear
	
	
	bys upc: gen nmonth=[_N]
	
	bys modcode month: egen sumexp_common=sum(exp) if nmonth==2
	bys modcode  month: egen sumexp=sum(exp)
	gen lambda=sumexp_common/sumexp
	collapse (mean) lambda, by (modcode month )
	
	merge m:1 modcode  using "$dirin2/sigmasRW_month.dta"
	keep if _merge==3
	drop _merge
	
	egen id=group(modcode )
	sort modcode
	by modcode: gen bias=(lambda/lambda[_n-1])^(1/(sigma-1))
	by modcode: gen lvar= log(lambda/lambda[_n-1])*(1/(sigma-1))
	drop if lvar==. 
	keep modcode month  bias lvar
	distinct
	save "$dirin2/temp/bias_noncook_`x'.dta",replace
	}
	
*Variety Term Cook
foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_cook.dta",clear
	
	
	bys upc: gen nmonth=[_N]
	
	bys modcode month: egen sumexp_common=sum(exp) if nmonth==2
	bys modcode  month: egen sumexp=sum(exp)
	gen lambda=sumexp_common/sumexp
	collapse (mean) lambda, by (modcode month )
	
	merge m:1 modcode  using "$dirin2/sigmasRW_month.dta"
	keep if _merge==3
	drop _merge
	
	egen id=group(modcode )
	sort modcode
	by modcode: gen bias=(lambda/lambda[_n-1])^(1/(sigma-1))
	by modcode: gen lvar= log(lambda/lambda[_n-1])*(1/(sigma-1))
	drop if lvar==. 
	keep modcode month  bias lvar
	distinct
	save "$dirin2/temp/bias_cook_`x'.dta",replace
	}	


*Combine for Non-Cook
foreach x of numlist 540/707{

use "$dirin2/temp/CCG_noncook_`x'.dta", clear
merge 1:1 month modcode using "$dirin2/temp/bias_noncook_`x'.dta", nogen
merge 1:1 month modcode using $dirout/temp/sato_outside_`x'.dta, nogen


drop if month ~= `x'
gen lCUPI = lCCG + lvar

gen lfeenstra=ln((sato*bias))
gen feenstra = exp(lfeenstra)

gen CUPI = exp(lCUPI)

keep CUPI feenstra month modcode

save "$dirin2/temp/cupi_noncook_`x'.dta", replace
}

use "$dirin2/temp/cupi_noncook_540.dta",clear
foreach x of numlist 541/707{
	append using "$dirin2/temp/cupi_noncook_`x'.dta", nolabel
	}
save $dirin2/temp/cupi_noncook.dta, replace

*Combine for Cook
foreach x of numlist 540/707{

use "$dirin2/temp/CCG_cook_`x'.dta", clear
merge 1:1 month modcode using "$dirin2/temp/bias_cook_`x'.dta", nogen
merge 1:1 month modcode using $dirout/temp/sato_outside_`x'.dta, nogen


drop if month ~= `x'
gen lCUPI = lCCG + lvar

gen lfeenstra=ln((sato*bias))
gen feenstra = exp(lfeenstra)

gen CUPI = exp(lCUPI)

keep CUPI feenstra month modcode



save "$dirin2/temp/cupi_cook_`x'.dta", replace
}

use "$dirin2/temp/cupi_cook_540.dta",clear
foreach x of numlist 541/707{
	append using "$dirin2/temp/cupi_cook_`x'.dta", nolabel
	}
save $dirin2/temp/cupi_cook.dta, replace






/****************************************************************************
3. CCG and Sato-Vartia Estimation Across Modcodes
****************************************************************************/

*Non-Cook



set more off
foreach x of numlist 540/707{

	use if month == `x' | month == `x'-1 using $dirout/temp_outside.dta, clear


	collapse (sum) exp, by( modcode month)
	bys modcode: gen number = _N
	keep if number == 2
	bys month: egen sumexp = sum(exp)
	gen mod_share = exp/sumexp


	merge 1:1 modcode month  using $dirin2/temp/cupi_noncook.dta, nogen keep(match)
	
	
	
	rename mod_share share
	rename CUPI unitprice
	rename feenstra unitprice2
	
	sort modcode month
	bys modcode: gen pastshare = share[_n-1]
	xtset modcode month
	
	gen N = _N/2 //Total number of common goods is total obs/2 (two quarters)
	
	sort modcode month

	by modcode: gen share_ratio = log(share/share[_n-1])
	replace share_ratio = . if month == `x'-1
	
	by modcode: gen price_ratio = log(unitprice)
	replace price_ratio = . if month == `x' - 1
	
	
	
	by modcode: gen wtop = (share-share[_n-1])/(log(share)-log(share[_n-1]))
	egen wbottom = sum(wtop), by(month)
	gen w = wtop/wbottom
	replace w = . if month ~= `x'
	
	by modcode: gen sato = w*(unitprice2)
	
	
	
	drop if month == `x'-1
	
	gen cupi2_noncook = pastshare*unitprice
	gen feenstra2_noncook = pastshare*unitprice2
	
	collapse (mean) N (sum) share_ratio price_ratio sato cupi2 feenstra2
	di "after collapse"
	merge 1:1 _n  using "$dirin2/sigmasRW_month_acrossmodule.dta", nogen keep(match)
	
	
	
	gen lCCG = (1/(N))* price_ratio + (1/(sigma-1))*(1/N)*share_ratio 
	
	gen month= `x'
	save "$dirin2/temp/across_CCG_noncook_`x'.dta",replace
	}

use "$dirin2/temp/across_CCG_noncook_540.dta",clear
foreach x of numlist 541/707{
	append using "$dirin2/temp/across_CCG_noncook_`x'.dta", nolabel
	}
	gen CCG_noncook = exp(sum(lCCG))
	gen feenstra_noncook = sato
	
	merge 1:1 month using $dirout/temp/laspeyres_outside.dta, nogen
*gen cum_CCG_noncook=exp(sum(ln(CCG)))*100
	
save $dirin2/temp/across_CCG_noncook.dta, replace


*Cook



set more off
foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_cook.dta",clear
	



	collapse (sum) exp, by( modcode month)
	bys modcode: gen number = _N
	keep if number == 2
	bys month: egen sumexp = sum(exp)
	gen mod_share = exp/sumexp


	merge 1:1 modcode month  using $dirin2/temp/cupi_cook.dta, nogen keep(match)
	
	
	
	rename mod_share share
	rename CUPI unitprice
	rename feenstra unitprice2
	
	sort modcode month
	bys modcode: gen pastshare = share[_n-1]
	
	xtset modcode month
	
	gen N = _N/2 //Total number of common goods is total obs/2 (two quarters)
	
	sort modcode month

	by modcode: gen share_ratio = log(share/share[_n-1])
	replace share_ratio = . if month == `x'-1
	di "here2"
	by modcode: gen price_ratio = log(unitprice)
	replace price_ratio = . if month == `x' - 1
	
	
	by modcode: gen wtop = (share-share[_n-1])/(log(share)-log(share[_n-1]))
	egen wbottom = sum(wtop), by(month)
	gen w = wtop/wbottom
	replace w = . if month ~= `x'
	
	by modcode: gen sato = w*(unitprice2)
	
	drop if month == `x'-1
	
	gen cupi2_cook = pastshare*unitprice
	gen feenstra2_cook = pastshare*unitprice2
	
	collapse (mean) N (sum) share_ratio price_ratio sato cupi2 feenstra2
	di "after collapse"
	merge 1:1 _n  using "$dirin2/sigmasRW_month_acrossmodule.dta", nogen keep(match)
	
	
	
	gen lCCG = (1/(N))* price_ratio + (1/(sigma-1))*(1/N)*share_ratio 
	
	gen month= `x'
	save "$dirin2/temp/across_CCG_cook_`x'.dta",replace
	}

use "$dirin2/temp/across_CCG_cook_540.dta",clear

foreach x of numlist 541/707{
	append using "$dirin2/temp/across_CCG_cook_`x'.dta", nolabel
	
	}
	gen CCG_cook = exp(sum(lCCG))
	gen feenstra_cook = sato
	
	
	merge 1:1 month using $dirout/temp/laspeyres_cook.dta, nogen
	*gen cum_CCG_cook=exp(sum(ln(CCG)))*100
	
sort month 

save $dirin2/temp/across_CCG_cook.dta, replace



/****************************************************************************
4. Combine and Graph
****************************************************************************/



use $dirin2/temp/across_CCG_noncook.dta, replace

merge 1:1 month using $dirin2/temp/across_CCG_cook.dta, nogen

sort month
tsset month
format month %tm

*Normalize to 100 in August, 2017

global price_list "cum_laspeyres_cook cum_laspeyres_noncook cum_paasche_cook cum_paasche_noncook  CCG_cook CCG_noncook"


foreach var of global price_list{

gen _base_`var' = `var' if month == ym(2017,7)
egen base_`var' = max(_base_`var')
gen norm_`var' = 100*`var'/base_`var'
}

lab var norm_cum_laspeyres_cook "Laspeyres Cook"
lab var norm_cum_laspeyres_noncook "Laspeyres Rest of Chicago"
lab var norm_cum_paasche_cook "Paasche Cook"
lab var norm_cum_paasche_noncook "Paasche Rest of Chicago"
lab var norm_CCG_cook "CCG Cook"
lab var norm_CCG_noncook "CCG Rest of Chicago"



tsline  norm_cum_laspeyres_cook norm_cum_laspeyres_noncook   if month > ym(2016,7) & month < ym(2018,7),  xline(691, lcolor(red) ) xline(695,lcolor(red))
graph export $dirout/laspeyres_cook_v_noncook.png, replace

tsline norm_CCG_cook norm_CCG_noncook if month > ym(2016,7) & month < ym(2018,7),  xline(691, lcolor(red) ) xline(695,lcolor(red))
graph export $dirout/laspeyres_cook_v_noncook.png, replace







/******************************************************************************
5. Price Index for Soft Drinks only
******************************************************************************/



*Laspeyres and Paasche

*Laspeyres and Paasche for Non-cook only modcode 1484

foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_outside.dta",clear
	keep if modcode == 1484
	
	*Keeps only common UPCS
	bys upc: gen number = _N
	keep if number == 2
	
	bys month: egen totexp = sum(exp)
	
	gen share = exp/totexp
	
	sort upc month
	by upc: gen laspeyres = share[_n-1]*(unitprice/unitprice[_n-1])
	by upc: gen paasche = share*(unitprice/unitprice[_n-1])
	drop if month ~= `x'
	collapse (sum) laspeyres paasche
	gen month = `x'
	rename laspeyres laspeyres_noncook
	rename paasche paasche_noncook
	
	save $dirout/temp/laspeyres_outside1484_`x'.dta, replace
	
	
	}
	
	use $dirout/temp/laspeyres_outside1484_540.dta, clear
	
	forval i = 541/707{
		append using $dirout/temp/laspeyres_outside1484_`i'.dta
	}
	
	save $dirout/temp/laspeyres_outside1484.dta, replace
	
*Laspeyres and Paasche for Cook

foreach x of numlist 540/707{

	use if month==`x'|month==`x'-1 using "$dirout/temp_cook.dta",clear
	keep if modcode == 1484
	
	*Keeps only common UPCS
	bys upc: gen number = _N
	keep if number == 2
	
	bys month: egen totexp = sum(exp)
	
	gen share = exp/totexp
	
	sort upc month
	by upc: gen laspeyres = share[_n-1]*(unitprice/unitprice[_n-1])
	by upc: gen paasche = share*(unitprice/unitprice[_n-1])
	drop if month ~= `x'
	collapse (sum) laspeyres paasche
	gen month = `x'
	rename laspeyres laspeyres_cook
	rename paasche paasche_cook
	save $dirout/temp/laspeyres_cook1484_`x'.dta, replace
	
	
	}

use $dirout/temp/laspeyres_cook1484_540.dta, clear
	
	forval i = 541/707{
		append using $dirout/temp/laspeyres_cook1484_`i'.dta
	}
	
	save $dirout/temp/laspeyres_cook1484.dta, replace


*CUPI and Feenstra

use "$dirin2/temp/cupi_cook.dta", clear
rename CUPI cupi_cook
rename feenstra feenstra_cook



merge 1:1 modcode month using "$dirin2/temp/cupi_noncook.dta", nogen
rename CUPI cupi_noncook
rename feenstra feenstra_noncook

keep if modcode == 1484
drop modcode
merge 1:1 month using $dirout/temp/laspeyres_cook1484.dta, nogen
merge 1:1 month using $dirout/temp/laspeyres_outside1484.dta, nogen

*Graph

sort month
tsset month
format month %tm

lab var laspeyres_cook "Laspeyres Cook"
lab var laspeyres_noncook "Laspeyres Non-cook"

foreach var of varlist  cupi_cook feenstra_cook laspeyres_cook paasche_cook cupi_noncook feenstra_noncook laspeyres_noncook paasche_noncook {

gen cum_`var' = exp(sum(log(`var')))
gen _base_`var' = cum_`var' if month == ym(2017,7)
egen base_`var' = max(_base_`var')
gen norm_cum_`var' =  100*cum_`var'/base_`var'
}

lab var norm_cum_cupi_cook "CUPI Price Index Cook"
lab var norm_cum_cupi_noncook "CUPI Price Index Rest of Chicago"
lab var norm_cum_laspeyres_cook "Laspeyres Cook"
lab var norm_cum_laspeyres_noncook "Laspeyres Rest of Chicago"
lab var norm_cum_paasche_cook "Paasche Cook"
lab var norm_cum_paasche_noncook "Paasche Rest of Chicago"
lab var norm_cum_feenstra_cook "Feenstra Cook"
lab var norm_cum_feenstra_noncook "Feenstra Rest of Chicago"

tsline norm_cum_cupi* if month > ym(2016,1), xline(691, lcolor(red) ) xline(695,lcolor(red))

graph export $dirout/cupi_cook_v_noncook_soda.png, replace

tsline norm* if month > ym(2016,1),xline(691, lcolor(red) ) xline(695,lcolor(red))

graph export $dirout/price_cook_v_noncook_soda.png, replace



