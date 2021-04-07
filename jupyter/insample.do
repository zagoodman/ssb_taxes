/*
insample.do
By: Z. A. Goodman & J. Orchard
Updated: March 2021

This file takes the Nielsen consumer panel and returns indicators for
the SSB treated localities as well as untreated localities in the same DMA
(designated market area, like MSA) as a treated locality. Treatment is 
differentiated by counterfactual = 0 for treated and 1 for control. 

The 'using' data should have the following vars:
- panelist_zipcd
- dma_cd
- fips_state_cd
- fips_county_cd

Returns the following vars:
- dma_treated
- albany, berkeley, boulder, cook, oakland, philly, sanfran, seattle
*/


/* Identify treated DMAs, which include treated and control units
807: Bay Area
751: Boulder
504: Philly
819: Seattle
602: Cook County
*/

gen dma_treated = inlist(dma_cd, 807, 751, 504, 819, 602)


* Generate identifiers for each treated zip

gen albany = inlist(panelist_zipcd, 94706, 94707, 94710, 94804)

gen berkeley = inlist(panelist_zipcd, 94608, 94609, 94618, 94702, 94703, 94704, 94705, 94706, 94707, 94708, 94709, 94710, 94720)

gen boulder = inlist(panelist_zipcd, 80025, 80301, 80302, 80303, 80304, 80305, 80310, 80503)

gen cook = fips_state_cd == 17 & fips_county_cd == 031

gen oakland = inlist(panelist_zipcd, 94577, 94601, 94602, 94603, 94605, 94606, 94607, 94608, 94609, 94610, 94611, 94612, 94613, 94618, 94619, 94621, 94704, 94705)

gen philly = inlist(panelist_zipcd, 19102, 19103, 19104, 19106, 19107, 19109, 19111, 19112, 19114, 19115, 19116, 19118, 19119, 19120, 19121, 19122, 19123, 19124, 19125, 19126, 19127, 19128, 19129, 19130, 19131, 19132, 19133, 19134, 19135, 19136, 19137, 19138, 19139, 19140, 19141, 19142, 19143, 19144, 19145, 19146, 19147, 19148, 19149, 19150, 19151, 19152, 19153, 19154)

gen sanfran = inlist(panelist_zipcd, 94102, 94103, 94104, 94105, 94107, 94108, 94109, 94110, 94111, 94112, 94114, 94115, 94116, 94117, 94118, 94121, 94122, 94123, 94124, 94127, 94129, 94130, 94131, 94132, 94133, 94134, 94158)

gen seattle = inlist(panelist_zipcd, 98101, 98102, 98103, 98104, 98105, 98106, 98107, 98108, 98109, 98112, 98115, 98116, 98117, 98118, 98119, 98121, 98122, 98125, 98126, 98133, 98134, 98136, 98144, 98146, 98154, 98164, 98174, 98177, 98178, 98195, 98199)
