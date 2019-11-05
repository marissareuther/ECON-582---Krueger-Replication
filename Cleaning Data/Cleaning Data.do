clear all
capture log close 
set more off 

cd "//Client/C$/Users/maris/Dropbox/Grad/582 - Metrics I/ECON-582---Krueger-Replication/"
set logtype text
log using "./Cleaning Data/Log-CleaningData.txt", replace 

use "./Raw Data/STAR_Students.dta"

* This do file cleans the data *
*sum 

* Create variables to tell when a student entered STAR, and combine into one variable 
gen gradeenter = 0 if flagsgk == 1
replace gradeenter = 1 if flagsgk == 0 & flagsg1 == 1
replace gradeenter = 2 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 1 
replace gradeenter = 3 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 0 & flagsg3 == 1 

tab gradeenter



* Table 1 

* Having issues with entering other grades besides k. 
* Try to make one variable based on class size.... 


* Kindergarten:
* Free lunch is coded as 1 (free lunch) and 2 (non-free lunch), need to make 0 and 1 instead. 
tab gkfreelunch, m
preserve
drop if gkfreelunch == .
gen gkfrlnch=gkfreelunch==1  /* need to make sure missing values are dropped otherwise get absorbed into the '0' */
tab gkfrlnch, m

bysort  gkclasstype : egen mgkfreelunch = mean(gkfrlnch)  /* don't need the bysory classtype???
tab mgkfreelunch, m 
restore



* 1st Grade
* Free lunch is coded as 1 (free lunch) and 2 (non-free lunch), need to make 0 and 1 instead. 
tab g1freelunch, m
preserve
drop if g1freelunch == .
gen g1frlnch=g1freelunch==1  /* need to make sure missing values are dropped otherwise get absorbed into the '0' */
tab g1frlnch, m

bysort g1classtype : egen mg1freelunch = mean(g1frlnch)
tab g1classtype, m
tab mg1freelunch, m 
restore



* 2nd Grade
tab g2freelunch, m
preserve
drop if g2freelunch == .
gen g2frlnch=g2freelunch==1  /* need to make sure missing values are dropped otherwise get absorbed into the '0' */
tab g2frlnch, m

bysort gradeenter g2classtype : egen mg2freelunch = mean(g2frlnch)
tab g2classtype, m
tab mg2freelunch, m 
restore



bysort  gradeenter gkclasstype : egen mgkfreelunch = mean(gkfrlnch)
tab mgkfreelunch, m 


bysort  gradeenter g1classtype : egen mgkfreelunch = mean(g1frlnch)
tab mgkfreelunch, m 

bysort  gradeenter g2classtype : egen mgkfreelunch = mean(gkfrlnch)
tab mgkfreelunch, m 

bysort  gradeenter g3classtype : egen mgkfreelunch = mean(gkfrlnch)
tab mgkfreelunch, m 