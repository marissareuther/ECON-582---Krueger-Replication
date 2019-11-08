clear all
capture log close 
set more off 


cd "//Client/C$/Users/maris/Dropbox/Grad/582 - Metrics I/ECON-582---Krueger-Replication/"
set logtype text
log using "./Analysis/Figures and Tables/Log-Table1.txt", replace 

use "./Raw Data/STAR_Students.dta"


* This do file cleans the data *
*sum 

* Create variables to tell when a student entered STAR, and combine into one variable 
gen gradeenter = 0 if flagsgk == 1
replace gradeenter = 1 if flagsgk == 0 & flagsg1 == 1
replace gradeenter = 2 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 1 
replace gradeenter = 3 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 0 & flagsg3 == 1 

tab gradeenter, m


* Drop if race is missing and create White/Asian indicator
drop if race == .
gen WhiteAsian = 1 if race == 1 | race == 3
replace WhiteAsian = 0 if WhiteAsian == .


* Create variable: Age in 1985
/* need to fix? May be ok bc email said theirs was slighty off too*/
gen age = 1985 - birthyear


* Create variable: Attrition rate: percent that exits sample before completing third grade 
//Sliiiightly off... 

* Kindergarten:
gen gkleave = 1 if flagsgk == 1 & flagsg1 == 0 | flagsg2 == 0 | flagsg3 == 0 
replace gkleave = 0 if gkleave == .

* 1st Grade:
gen g1leave = 1 if flagsg1 == 1 & flagsgk == 0 & flagsg2 == 0 | flagsg3 == 0 
replace g1leave = 0 if g1leave == .

* 2nd Grade:
gen g2leave = 1 if flagsg2 == 1 & flagsg3 == 0 
replace g2leave = 0 if g2leave == .


* Create variable: Percentile Score as average of three SAT percentiles (more to it)
/* need to fix, but theirs was also slightly off.*/
egen gkpercentile=rmean(gktreadss gktmathss gktlistss)

*egen kmathpercent = _pctile gktmathss, nq(1000)
egen g1percentile=rmean(g1treadss g1tmathss g1tlistss)
egen g2percentile=rmean(g2treadss g2tmathss g2tlistss)
egen g3percentile=rmean(g3treadss g3tmathss g3tlistss)



* Table 1 

* Kindergarten:
preserve
drop if gkfreelunch == .
gen gkfrlnch = gkfreelunch == 1 

local gklist = "gkfrlnch WhiteAsian age gkleave gkclasssize gkpercentile"

foreach var of local gklist { 
   tabstat `var' if gradeenter == 0, by(gkclasstype) stat(mean, n)
   mvtest mean `var' if gradeenter == 0, by(gkclasstype)
}

restore


* 1st Grade
preserve
drop if g1freelunch == .
gen g1frlnch = g1freelunch == 1  
tab g1frlnch

local g1list = "g1frlnch WhiteAsian age g1leave g1classsize g1percentile"

foreach var of local g1list { 
   tabstat `var' if gradeenter == 1, by(g1classtype) stat(mean, n)
   mvtest mean `var' if gradeenter == 1, by(g1classtype)
}

restore


* 2nd Grade
preserve
drop if g2freelunch == .
gen g2frlnch = g2freelunch == 1  

local g2list = "g2frlnch WhiteAsian age g2leave g2classsize g2percentile"

foreach var of local g2list { 
   tabstat `var' if gradeenter == 2, by(g2classtype) stat(mean, n)
   mvtest mean `var' if gradeenter == 2, by(g2classtype)
}

restore


* 3nd Grade
preserve
drop if g3freelunch == .
gen g3frlnch = g3freelunch == 1  

local g3list = "g3frlnch WhiteAsian age g3classsize g3percentile"

foreach var of local g3list { 
   tabstat `var' if gradeenter == 3, by(g3classtype) stat(mean, n)
   mvtest mean `var' if gradeenter == 3, by(g3classtype)
}

restore
