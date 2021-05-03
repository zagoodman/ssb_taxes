/*
cook_zip_layers.do
By: Z. A. Goodman
Updated: April 2021

This file generates indicators for which layers the panelist_zip
is in within Cook County.

The 'using' data should have the following vars:
- panelist_zipcd
- locality

Returns the following vars:
- layer
*/


* outside cook
gen layer = 0

* inside Cook, innermost layer
replace layer = 6 if locality == "Cook"

* cross border
replace layer = 1 if inlist(panelist_zipcd, 60010, 60103, 60120, 60439, 60527, ///
    60133, 60475, 60089)

* on border, layer 1
replace layer = 2 if inlist(panelist_zipcd, 60617, 60633, 60409, 60438, 60411, /// // E
    60475, 60466, 60471, 60443, 60477, 60487, 60467, 60439, /// // S
    60480, 60558, 60154, 60162, 60163, 60164, 60131, 60666, 60018, /// // WS
    60007, 60193, 60133, 60192, 60165, /// // WN
    60074, 60004, 60090, 60062, 60022, /// // N
    60465, 60107)
    
* layer 2
replace layer = 3 if inlist(panelist_zipcd, 60649, 60619, 60628, 60827, ///
    60419, 60473, 60476, 60425, /// // E
    60430, 60422, 60461, 60478, 60452, 60462, 60464, /// // S
    60465, 60457, 60458, 60525, 60526, 60155, 60104, 60160, 60171, 60176, /// // WS
    60056, 60005, 60008, 60173, 60194, 60169, 60195, ///
           60067, 60067, 60196, /// // WN
    60026, 60025, 60093, 60070, /// // N
    60526, 60513, 60429, 60105, 60016, 60153, 60068, 60458)
    
* layer 3
replace layer = 4 if inlist(real(substr(string(panelist_zipcd),3,3)), ///
    637, 621, 620, ///
    643, 406, 469, 445, 463, 415, 428, 426, 472, 455, 501, 534, 546, ///
    141, 130, 305, 707, 634, 706, 656, 631, 714, 482, 182, 803, 453, ///
    459, 638, 402, 804, 304, 344, 302, 053, 091, 077) ///
    & real(substr(string(panelist_zipcd),1,2)) == 60

* layer 4
replace layer = 5 if inlist(real(substr(string(panelist_zipcd),3,3)), ///
    639, 630, 646, ///
    655, 456, 652, 805, 636, 629,  632, 623, 624, 644, 641, 651, 076, 712, ///
    201, 202, 203, 208, 609, 615, 653) ///
    & real(substr(string(panelist_zipcd),1,2)) == 60

label define layer 1 "Cross Border" 0 "Outside Cook" 6 "Innermost Layer" ///
    2 "Inside Cook, border" 3 "Second Layer" 4 "Third Layer" 5 "Fourth Layer"
label value layer layer
