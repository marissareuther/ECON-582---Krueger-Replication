clear all
capture log close 
set more off 


cd "//Client/C$/Users/maris/Dropbox/Grad/582 - Metrics I/ECON-582---Krueger-Replication/"
set logtype text
log using "./Analysis/Log-TablesAndFigures.txt", replace 

use "./Raw Data/STAR_Students.dta"


* Create variables to tell when a student entered STAR.
gen gradeenter = 0 if flagsgk == 1
replace gradeenter = 1 if flagsgk == 0 & flagsg1 == 1
replace gradeenter = 2 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 1 
replace gradeenter = 3 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 0 & flagsg3 == 1 

* Drop if race is missing and create White/Asian indicator
*drop if race == .
gen WhiteAsian = 1 if race == 1 | race == 3
replace WhiteAsian = 0 if WhiteAsian == .

* Create variable: Age as of September 1st, 1985 (start of 1985 school year)
gen bday = mdy(birthmonth, birthday, birthyear)
gen startschool = mdy(9,1,1985)
gen age = (startschool - bday)/365

* Redefine free lunch as (0 1) instead of (1 2)
local freelunch = "gkfreelunch g1freelunch g2freelunch g3freelunch"

foreach var of local freelunch {
 gen `var'_2 = .  if `var'== .  
 replace `var'_2 = 0 if `var' == 2
 replace `var'_2 = 1 if `var' == 1
}

* Create variable: Attrition rate: percent that exits sample before completing third grade 
* Kindergarten:
gen g0attrition = 1 if flagsgk == 1 & flagsg1 == 0 | flagsg2 == 0 | flagsg3 == 0 
replace g0attrition = 0 if g0attrition == .

* 1st Grade:
gen g1attrition = 1 if flagsg1 == 1 & flagsgk == 0 & flagsg2 == 0 | flagsg3 == 0 
replace g1attrition = 0 if g1attrition == .

* 2nd Grade:
gen g2attrition = 1 if flagsg2 == 1 & flagsg3 == 0 
replace g2attrition = 0 if g2attrition == .

* 3rd Grade: Attrition not available
gen g3attrition = 0


* Create variable: Percentile Score as average of three SAT percentiles 
************* Need to fix this!!!!! All other variables are pretty good. 
local g0score = "gktmathss gktlistss gkwordskillss"
local g1score = "g1tmathss g1tlistss g1wordskillss"
local g2score = "g2tmathss g2tlistss g2wordskillss"
local g3score = "g3tmathss g3tlistss g3wordskillss"

foreach var of local g0score { 
     egen n_`var' = count(`var')
     sort `var'
     egen i_`var' = rank(`var')
     gen p_`var' = ((i_`var' - 0.5) / n_`var')*100 
} 
gen g0pscore = (p_gktmathss + p_gktlistss + p_gkwordskillss)/3

foreach var of local g1score { 
  egen n_`var' = count(`var')
  sort `var'
  egen i_`var' = rank(`var')
  gen p_`var' = ((i_`var' - 0.5) / n_`var')*100 
 }
gen g1pscore = (p_g1tmathss + p_g1tlistss + p_g1wordskillss)/3

foreach var of local g2score { 
  egen n_`var' = count(`var')
  sort `var'
  egen i_`var' = rank(`var')
  gen p_`var' = ((i_`var' - 0.5) / n_`var')*100 
 }
gen g2pscore = (p_g2tmathss + p_g2tlistss + p_g2wordskillss)/3

foreach var of local g3score { 
  egen n_`var' = count(`var')
  sort `var'
  egen i_`var' = rank(`var')
  gen p_`var' = ((i_`var' - 0.5) / n_`var')*100 
 }
gen g3pscore = (p_g3tmathss + p_g3tlistss + p_g3wordskillss)/3



******************************************************
* Table 1 , use column(s) option within tabstat
* or can just use table and ,c() option (mean freelunch)

rename gkclasstype g0classtype
rename gkfreelunch_2 g0freelunch_2
rename gkclasssize g0classsize

local g0list = "g0freelunch_2 WhiteAsian age g0attrition g0classsize g0pscore"
local g1list = "g1freelunch_2 WhiteAsian age g1attrition g1classsize g1pscore"
local g2list = "g2freelunch_2 WhiteAsian age g2attrition g2classsize g2pscore"
local g3list = "g3freelunch_2 WhiteAsian age g3classsize g3pscore"

foreach i in 0 1 2 3 {
   tabstat g`i'freelunch_2 WhiteAsian age g`i'attrition g`i'classsize g`i'pscore if gradeenter == `i', by(g`i'classtype) stat(mean)
     
	 foreach var of local g`i'list { 
       mvtest mean `var' if gradeenter == `i', by(g`i'classtype) 
	   mvtest mean `var' if gradeenter == `i', by(g`i'classtype) het
     }
}

/* different format. (Not as nice) 
foreach i in 0 1 2 3 {
  foreach var of local g`i'list { 
     tabstat `var' if gradeenter == `i', by(g`i'classtype) stat(mean, n)
     mvtest mean `var' if gradeenter == `i', by(g`i'classtype) het
   }
}
*/




******************************************************
* Table 2

* check out  areg and/or reghdfe 
*school id variables --> gkschid, 
* Is this what it means by school controls?




******************************************************
* Table 3
* Distribution of children across actual class sizes by random assignment group in first grade 

tab g1classsize g1classtype




******************************************************
* Figure 1 
* Distribution of Test Percentile Scores by Class Size and Grade 

forvalues n=0(1)3 {
twoway kdensity g`n'pscore if (g`n'classtype==1) || kdensity g`n'pscore if (g`n'classtype==2 | g`n'classtype==3)
graph export "./Output/figure1_`n'.png", replace
}

 
