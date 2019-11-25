clear all
capture log close 
set more off 

cd "//Client/C$/Users/maris/Dropbox/Grad/582 - Metrics I/ECON-582---Krueger-Replication/"
set logtype text
log using "./Analysis/Clean_Data.txt", replace 

use "./Raw Data/STAR_Students.dta"


********************************************************************************
* I. Create / Reformat Variables
********************************************************************************

* Rename gk variables as g0 to make loops possible later on
local k = "freelunch classtype classsize tmathss wordskillss treadss trace thighdegree schid tchid tyears tgen"

foreach var of local k{
   rename gk`var' g0`var'
}


* Create gradeenter as when a student entered TNSTAR
qui gen gradeenter = 0 if flagsgk == 1
 qui replace gradeenter = 1 if flagsgk == 0 & flagsg1 == 1
 qui replace gradeenter = 2 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 1 
 qui replace gradeenter = 3 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 0 & flagsg3 == 1 


* Create White/Asian indicator
qui gen WhiteAsian = 1 if race == 1 | race == 3
 qui replace WhiteAsian = 0 if WhiteAsian == . & race != .


* Create Age as of September 1st, 1985 (start of 1985 school year)
qui gen bday = mdy(birthmonth, birthday, birthyear)
qui gen startschool = mdy(9,1,1985)
qui gen age = (startschool - bday)/365
 qui replace age = 1985 - birthyear if age == .


* Redefine free lunch as (0 1) instead of (1 2)
local freelunch = "g0freelunch g1freelunch g2freelunch g3freelunch"

foreach var of local freelunch {
 qui gen `var'_2 = .  if `var'== .  
  qui replace `var'_2 = 0 if `var' == 2
  qui replace `var'_2 = 1 if `var' == 1
}


* Redefine gender as (0-male,1-female) instead of (1,2) 
qui gen girl = gender - 1


* Create Attrition rate: percent that exits sample before completing third grade. 
* K:
qui gen g0attrition = 1 if flagsgk == 1 & flagsg1 == 0 | flagsg2 == 0 | flagsg3 == 0 
 qui replace g0attrition = 0 if g0attrition == .
* 1:
qui gen g1attrition = 1 if flagsg1 == 1 & flagsg2 == 0 | flagsg3 == 0 
 qui replace g1attrition = 0 if g1attrition == .
* 2:
qui gen g2attrition = 1 if flagsg2 == 1 & flagsg3 == 0 
 qui replace g2attrition = 0 if g2attrition == .
* 3:
qui gen g3attrition = 0


* Create variable: Percentile Score as SAT average for reading, math, and listening
forvalues i == 0/3 {

	foreach sub in `i'tread `i'tmath `i'wordskill {
		cumul g`sub'ss if inrange(g`i'classtype,2,3), gen(g`sub'xt)
		sort g`sub'ss
		qui replace g`sub'xt=g`sub'xt[_n-1] if g`sub'ss==g`sub'ss[_n-1] & g`i'classtype==1
		qui ipolate g`sub'xt g`sub'ss, gen(ipo)
		qui replace g`sub'xt=ipo if g`i'classtype==1 & mi(g`sub'xt)
		drop ipo
	}
	qui egen g`i'SAT = rmean(g`i'treadxt g`i'tmathxt g`i'wordskillxt)
	 qui replace g`i'SAT=100*g`i'SAT
}


* Create indicator for white teacher 
forvalues i == 0/3 {
	qui gen g`i'twhite = 1 if g`i'trace == 1
	 qui replace g`i'twhite = 0 if g`i'twhite==. & g`i'trace != .
}


* Create indicator for teacher with master's degree or higher
forvalues i == 0/3 {
	qui gen g`i'md = 1 if g`i'thighdegree == 3 | g`i'thighdegree == 4 | g`i'thighdegree == 5 | g`i'thighdegree == 6
	 qui replace g`i'md = 0 if g`i'md==. & g`i'thighdegree != .
}


* Create White Teacher indicator
forvalues i == 0/3 {
	qui gen WhiteTeacher`i' = 1 if g`i'trace == 1
	 qui replace WhiteTeacher`i' = 0 if WhiteTeacher`i' == . & g`i'trace != .
}


* Create Male Teacher indicator
forvalues i == 0/3 {
	qui gen MaleTeacher`i' = 1 if g`i'tgen == 1
	 qui replace MaleTeacher`i' = 0 if MaleTeacher`i' == . & g`i'tgen != .
}


* Create Indicator for small class, regular class, and regular+aide (needed for II, V, and VII)
forvalues i == 0/3{
	qui gen g`i's = 1 if g`i'classtype==1
	 qui replace g`i's = 0 if g`i's == . & g`i'classtype != .

	qui gen g`i'r = 1 if g`i'classtype==2
	 qui replace g`i'r = 0 if g`i'r == . & g`i'classtype != .

	qui gen g`i'ra = 1 if g`i'classtype==3
	 qui replace g`i'ra = 0 if g`i'ra == . & g`i'classtype !=  .
}


* Create Indicator for students' initial assignment the first year they entered the program (needed for Reduced Form in V)
qui gen fyclasstype = .

forvalues i == 0/3 {
	qui replace fyclasstype = g`i'classtype if gradeenter == `i'
}

qui gen initials = 1 if fyclasstype==1
 qui replace initials = 0 if initials == . & fyclasstype != .

qui gen initialr = 1 if fyclasstype==2
 qui replace initialr = 0 if initialr == . & fyclasstype != .

qui gen initialra = 1 if fyclasstype==3
 qui replace initialra = 0 if initialra == . & fyclasstype !=  .

 
save "./Output/Data/CleanData.dta", replace