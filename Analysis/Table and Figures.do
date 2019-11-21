clear all
capture log close 
set more off 

ssc install est2tex, replace

cd "//Client/C$/Users/maris/Dropbox/Grad/582 - Metrics I/ECON-582---Krueger-Replication/"
set logtype text
log using "./Analysis/Log-TablesAndFigures.txt", replace 

use "./Raw Data/STAR_Students.dta"

* Rename gk variables as g0 to make loops possible later on
rename gkclasstype g0classtype
rename gkclasssize g0classsize
rename gktmathss g0tmathss
rename gkwordskillss g0wordskillss
rename gktreadss g0treadss
rename gktrace g0trace
rename gkthighdegree g0thighdegree
rename gkschid g0schid
rename gktchid g0tchid
rename gktyears g0tyears
rename gktgen g0tgen



* Create variables to tell when a student entered STAR.
gen gradeenter = 0 if flagsgk == 1
replace gradeenter = 1 if flagsgk == 0 & flagsg1 == 1
replace gradeenter = 2 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 1 
replace gradeenter = 3 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 0 & flagsg3 == 1 


* Create White/Asian indicator
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
rename gkfreelunch_2 g0freelunch_2


* Redefine gender as (0-male,1-female) instead of (1,2) 
gen girl = gender - 1


* Create variable: Attrition rate: percent that exits sample before completing third grade 
* Kindergarten:
gen g0attrition = 1 if flagsgk == 1 & flagsg1 == 0 | flagsg2 == 0 | flagsg3 == 0 
replace g0attrition = 0 if g0attrition == .
* 1st Grade:
gen g1attrition = 1 if flagsg1 == 1 & flagsg2 == 0 | flagsg3 == 0 
replace g1attrition = 0 if g1attrition == .
* 2nd Grade:
gen g2attrition = 1 if flagsg2 == 1 & flagsg3 == 0 
replace g2attrition = 0 if g2attrition == .
* 3rd Grade: Attrition not available
gen g3attrition = 0


* Create indicator for white teacher in each grade
forvalues i == 0/3 {
	gen g`i'twhite = 1 if g`i'trace == 1
	replace g`i'twhite = 0 if g`i'twhite==. & g`i'trace != .
}


* Create indicator for teacher with master's degree or higher in each grade
forvalues i == 0/3 {
	gen g`i'md = 1 if g`i'thighdegree == 3 | g`i'thighdegree == 4 | g`i'thighdegree == 5 | g`i'thighdegree == 6
	replace g`i'md = 0 if g`i'md==. & g`i'thighdegree != .
}


* Create White Teacher indicator
forvalues i == 0/3 {
	gen WhiteTeacher`i' = 1 if g`i'trace == 1
	replace WhiteTeacher`i' = 0 if WhiteTeacher`i' == . & g`i'trace != .
}


* Create Male Teacher indicator
forvalues i == 0/3 {
	gen MaleTeacher`i' = 1 if g`i'tgen == 1
	replace MaleTeacher`i' = 0 if MaleTeacher`i' == . & g`i'tgen != .
}


* Create dummy for small class, regular class, and regular+aide (need for II V and VII)
forvalues i == 0/3{
	gen g`i's = 1 if g`i'classtype==1
	replace g`i's = 0 if g`i's == . & g`i'classtype != .

	gen g`i'r = 1 if g`i'classtype==2
	replace g`i'r = 0 if g`i'r == . & g`i'classtype != .

	gen g`i'ra = 1 if g`i'classtype==3
	replace g`i'ra = 0 if g`i'ra == . & g`i'classtype !=  .
}



* Create variable: Percentile Score as SAT average for reading, math, and listening
forvalues i == 0/3 {

	foreach sub in `i'tread `i'tmath `i'wordskill {
		cumul g`sub'ss if inrange(g`i'classtype,2,3), gen(g`sub'xt)
		sort g`sub'ss
		replace g`sub'xt=g`sub'xt[_n-1] if g`sub'ss==g`sub'ss[_n-1] & g`i'classtype==1
		ipolate g`sub'xt g`sub'ss, gen(ipo)
		replace g`sub'xt=ipo if g`i'classtype==1 & mi(g`sub'xt)
		drop ipo
	}
	egen g`i'SAT = rmean(g`i'treadxt g`i'tmathxt g`i'wordskillxt)
	replace g`i'SAT=100*g`i'SAT
}






*****************************************************
* Table 1 , use column(s) option within tabstat 
* or can just use table and ,c() option (mean freelunch)
* Can combine all results into one table using a matrix, or just leave it. 

local g0list = "g0freelunch_2 WhiteAsian age g0attrition g0classsize g0SAT"
local g1list = "g1freelunch_2 WhiteAsian age g1attrition g1classsize g1SAT "
local g2list = "g2freelunch_2 WhiteAsian age g2attrition g2classsize g2SAT "
local g3list = "g3freelunch_2 WhiteAsian age g3classsize g3SAT "

foreach i in 0 1 2 3 {
   tabstat g`i'freelunch_2 WhiteAsian age g`i'attrition g`i'classsize g`i'SAT if gradeenter == `i', by(g`i'classtype) stat(mean)
     
	 foreach var of local g`i'list { 
       mvtest mean `var' if gradeenter == `i', by(g`i'classtype) 
	 }
}
 

 
 
 
 
 
******************************************************
* Table 2

forvalues i == 0/3 {
	
	foreach var of local g`i'list { 
		areg `var' g`i's g`i'ra if gradeenter==`i', absorb(g`i'schid) 
		*test g`i's=g`i'ra  
     }
}

 
 





******************************************************
* Table 3
* Distribution of children across actual class sizes by random assignment group in first grade 

tab g1classsize g1classtype







******************************************************
* Figure 1 
* Distribution of Test Percentile Scores by Class Size and Grade 

forvalues n=0/3 {
twoway kdensity g`n'SAT if (g`n'classtype==1)|| kdensity g`n'SAT if (g`n'classtype==2 | g`n'classtype==3), title("Average SAT Distributions for Grade `n'") ytitle("Density") xtitle("SAT Percentile") legend(label(1 "Small Class") label(2 "Regular Class")) lpattern("solid" "dash") scheme(s1color)
graph export "./Output/figure1_`n'.png", replace
}






******************************************************
* Table 5
* OLS and Reduced-Form (still OLS) Estimates of Effect of Class-Size Assignment on Average Percentile of SAT. 
* Four panels for when student entered TNSTAR
* All models cluster standard errors by class (gktchid is teacher ID within that grade so will indicate the class).

* OLS - Actual Class Size; Outcome is average SAT percentile; Four specifications 

	* Column 1 for each panel. Small Class, Regular/Aide class, no school FE. 
	* Not perfect, but good enough for now to move on. Within the ballpark
forvalues i == 0/3 {
	reg g`i'SAT g`i's g`i'ra, vce(cluster g`i'tchid) 
	est2vec table5a`i', replace vars(g`i'SAT g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md) e(r2`i') name(Col1`i')
} 
	* 2. Small Class, Regular/Aide class, school FE
	* Not perfect, still mostly ballpark
forvalues i == 0/3 {
    areg g`i'SAT g`i's g`i'ra, vce(cluster g`i'tchid) absorb(g`i'schid)  
	est2vec table5a`i', addto(table5a`i') name(Col2`i')
} 	
	* 3. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
	* Not perfect, still mostly ballpark but its getting larger
forvalues i == 0/3 {
	areg g`i'SAT g`i's g`i'ra  WhiteAsian girl g`i'freelunch_2, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a`i', addto(table5a`i') name(Col3`i')
} 		
	* 4. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience (gktyears), Teacher Male, Master's Degree, school FE
	* Not perfect, still mostly ballpark of the size of column 3
forvalues i == 0/3 {
	areg g`i'SAT g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a`i', addto(table5a`i') name(Col4`i')
} 	


forvalues i == 0/3 {
	est2tex table5a`i', replace preserve path() mark(stars) levels(90 95 99) flexible(2) fancy label plain() thousep
} 




/*
capture estimates drop *

forvalues i == 0/3 {
	reg g`i'SAT g`i's g`i'ra, vce(cluster g`i'tchid) 
	estimates store t51
	
	reg g`i'SAT g`i's g`i'ra, vce(cluster g`i'tchid) absorb(g`i'schid)
	estimates store t52
	
	areg g`i'SAT g`i's g`i'ra  WhiteAsian girl g`i'freelunch_2, vce(cluster g`i'tchid) absorb(g`i'schid)
	estimates store t53
	
	areg g`i'SAT g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	estimates store t54
} 
*/






***************************
* Go back change up gradeenter to make it into four separate variables. 
* Rerun Table 5a making conditional on gradeenter and check out observations. 
************************************







* Reduced Form - Initial Class Size -- Class size from first appearance in TNSTAR; Outcome is average SAT percentile;  Four specifications 

*** Create dummies indicating the students' initial assignment the first year they entered the program, rather then their actual assignment each year.
gen fyclasstype = .
forvalues i == 0/3 {

replace fyclasstype = g`i'classtype if gradeenter == `i'
}


/* Need to add in first year they entered the program!!!!!!!

forvalues i == 0/3{
	gen g`i'is = 1 if g`i'classtype==1 
	replace g`i'is = 0 if g`i'is == . & g`i'classtype != .

	gen g`i'ir = 1 if g`i'classtype==2
	replace g`i'ir = 0 if g`i'ir == . & g`i'classtype != .

	gen g`i'ira = 1 if g`i'classtype==3
	replace g`i'ira = 0 if g`i'ira == . & g`i'classtype !=  .
}
*/


	* 5. Small Class, Regular/Aide class, no school FE
forvalues i == 0/3 {
	reg g`i'SAT ib(2).fyclasstype, vce(cluster g`i'tchid) 
	est2vec table5a`i', replace vars(g`i'SAT g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md) e(r2`i') name(Col1`i')
} 

	* 6. Small Class, Regular/Aide class, school FE
	
	* 7. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
	
	* 8. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience, Master's Degree, school FE
forvalues i == 0/3 {
	areg g`i'SAT ib(2).fyclasstype WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a`i', addto(table5a`i') name(Col4`i')
} 	
	
 
 
 
 
 
******************************************************
* Table 7 
* OLS and 2SLS Estimates of Effect of Class Size on Achievement. 
* Dependent Variable: Average Percentile Score on SAT.

* Reported Coefficient is for actual number of students in each class. 
* All models control for: school fixed effects, student's race, gender, free lunch, teacher race/experience/education.
* Cluster standard errors by class

forvalues i == 0/3 {
	areg g`i'SAT g`i'classsize WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table7`i', addto(table7`i') name(Col4`i')
} 


forvalues i == 0/3 {
	ivregress 2sls g`i'SAT (g`i'classsize=i.g`i'classtype) WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md i.g`i'schid, vce(cluster g`i'tchid) 
	est2vec table7`i', addto(table7`i') name(Col4`i')
} 

*************
* Storing looped results: 
* tempname myresults 
* postfile 'myresults' x beta se using myresults.dta, replace  ( x and beta are columns)
* forvalues 2/80 {
*      reg lfkjslkdfksdf
* post `myresults`i'' (`=_b[w]') 
* another line???} 
*postclose 'myresults'

