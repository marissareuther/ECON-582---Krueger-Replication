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
drop if race == .
gen WhiteAsian = 1 if race == 1 | race == 3
replace WhiteAsian = 0 if WhiteAsian == . & race != .


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


* Redefine gender as (0 -male,1 -female) instead of (1,2) 
gen girl = gender - 1


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


* Create indicator for white teacher in each grade
rename gktrace g0trace

forvalues i == 0/3 {
	gen g`i'twhite = 1 if g`i'trace == 1
	replace g`i'twhite = 0 if g`i'twhite==. & g`i'trace != .
}

* Create indicator for teacher with master's degree or higher in each grade
rename gkthighdegree g0thighdegree

forvalues i == 0/3 {
	gen g`i'md = 1 if g`i'thighdegree == 3 | g`i'thighdegree == 4 | g`i'thighdegree == 5 | g`i'thighdegree == 6
	replace g`i'md = 0 if g`i'md==. & g`i'thighdegree != .
}


* Create dummy for just small class (need for V and VII)
rename gkclasstype g0classtype

forvalues i == 0/3 {
	gen g`i'small = 1 if g`i'classtype == 1
	replace g`i'small = 0 if g`i'small == . & g`i'classtype != .
}


* Create dummy for just regular + aide class (need for V and VII)
forvalues i == 0/3 {
	gen g`i'reg_a = 1 if g`i'classtype == 3
	replace g`i'reg_a = 0 if g`i'reg_a == . & g`i'classtype != .
}


* Create variable: Percentile Score as average of three SAT percentiles 
************* Need to fix this!!!!! All other variables are good. 
** Pool together grades for regular and regular + aid. Make those percentiles for the two groups first. 
rename gktmathss g0tmathss
rename gktlistss g0tlistss
rename gktreadss g0treadss

local g0score = "g0tmathss g0tlistss g0treadss"
local g1score = "g1tmathss g1tlistss g1treadss"
local g2score = "g2tmathss g2tlistss g2treadss"
local g3score = "g3tmathss g3tlistss g3treadss"

/*
forvalues i == 0/3 { 

   foreach var of local g`i'score {
     xtile p`var'2 = `var' if g`i'classtype == 2 | g`i'classtype == 3 , nq(100) 
	 	 }
	g g`i'score2 = (pg`i'tmathss2 + pg`i'tlistss2 + pg`i'treadss2)/3
} */
* determine where the small class size students fall using the regular size distribution
*sort g0tmathss 

forvalues i == 0/3 { 

   foreach var of local g`i'score {
     xtile p`var' = `var' , nq(100) 
	 	 }
	g g`i'score = (pg`i'tmathss + pg`i'tlistss + pg`i'treadss)/3
} 






*****************************************************
* Table 1 , use column(s) option within tabstat 
* or can just use table and ,c() option (mean freelunch)

rename gkfreelunch_2 g0freelunch_2
rename gkclasssize g0classsize

local g0list = "g0freelunch_2 WhiteAsian age g0attrition g0classsize g0score "
local g1list = "g1freelunch_2 WhiteAsian age g1attrition g1classsize g1score "
local g2list = "g2freelunch_2 WhiteAsian age g2attrition g2classsize g2score "
local g3list = "g3freelunch_2 WhiteAsian age g3classsize g3score "

foreach i in 0 1 2 3 {
   tabstat g`i'freelunch_2 WhiteAsian age g`i'attrition g`i'classsize g`i'score if gradeenter == `i', by(g`i'classtype) stat(mean)
     
	 foreach var of local g`i'list { 
       mvtest mean `var' if gradeenter == `i', by(g`i'classtype) 
	  * mvtest mean `var' if gradeenter == `i', by(g`i'classtype) het
     }
}
 
 
******************************************************
* Table 2

* check out  areg and/or reghdfe 
*school id variables --> gkschid, 
* Is this what it means by school controls?

gen g0=gradeenter==0
gen g1=gradeenter==1
gen g2=gradeenter==2
gen g3=gradeenter==3

xtset gkschid
xtreg g0score g0freelunch_2 if gradeenter==0, fe



******************************************************
* Table 3
* Distribution of children across actual class sizes by random assignment group in first grade 

tab g1classsize g1classtype




******************************************************
* Figure 1 
* Distribution of Test Percentile Scores by Class Size and Grade 

forvalues n=0/3 {
twoway kdensity g`n'score if (g`n'classtype==1) || kdensity g`n'score if (g`n'classtype==2 | g`n'classtype==3), title("Average SAT Distributions for Grade `n'") ytitle("Density") xtitle("SAT Percentile") legend(label(1 "Small Class") label(2 "Regular Class")) lpattern("solid" "dash")
graph export "./Output/figure1_`n'.png", replace
}

******************************************************
* Table 5
* OLS and Reduced-Form (still OLS) Estimates of Effect of Class-Size Assignment on Average Percentile of SAT. 
* Four panels for when student entered TNSTAR
* All models cluster standard errors by class (gktchid is teacher ID within that grade so will indicate the class).

* OLS - Actual Class Size; Outcome is average SAT percentile; Four specifications 

	* 1. Small Class, Regular/Aide class, no school FE
	
	* 2. Small Class, Regular/Aide class, school FE
	
	* 3. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
	
	* 4. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience (gktyears), Master's Degree, school FE
	

* Reduced Form - Initial Class Size; Outcome is average SAT percentile;  Four specifications 
	* 5. Small Class, Regular/Aide class, no school FE
	
	* 6. Small Class, Regular/Aide class, school FE
	
	* 7. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
	
	* 8. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience, Master's Degree, school FE
	
 
 
******************************************************
* Table 7 
* OLS and 2SLS Estimates of Effect of Class Size on Achievement. 
* Dependent Variable: Average Percentile Score on SAT.

* Reported Coefficient is for actual number of students in each class. 
* All models control for: school fixed effects, student's race, gender, free lunch, teacher race/experience/education.
* Cluster standard errors by class


